#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
target=${AMETHYST_TELEGRAM_TARGET:-vista}
case "$target" in
    xp)
        windows_version=0x0501
        ntddi_version=0x05010300
        subsystem_major=5
        subsystem_minor=1
        winpthread=${AMETHYST_WINPTHREAD_STATIC:-/usr/i686-w64-mingw32/lib/libwinpthread.a}
        if [[ ! -f "$winpthread" ]]; then
            echo "Set AMETHYST_WINPTHREAD_STATIC to the MinGW static winpthread archive." >&2
            exit 2
        fi
        winpthread_link="-Wl,--whole-archive,$winpthread,--no-whole-archive"
        ;;
    vista)
        windows_version=0x0600
        ntddi_version=0x06000000
        subsystem_major=6
        subsystem_minor=0
        winpthread_link=
        ;;
    *) echo "AMETHYST_TELEGRAM_TARGET must be 'xp' or 'vista'" >&2; exit 2 ;;
esac
required=(AMETHYST_MINGW_CXX AMETHYST_TDLIB_DIR AMETHYST_TDLIB_SOURCE AMETHYST_TDLIB_BUILD
          AMETHYST_OPENSSL_PREFIX AMETHYST_FMT_PREFIX AMETHYST_ZLIB_PREFIX
          AMETHYST_GTK_SDK AMETHYST_GLIB_SDK AMETHYST_TELEGRAM_BUILD_DIR AMETHYST_TELEGRAM_OUTPUT_DIR)
for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
        echo "Set $name; see docs/TELEGRAM-WINDOWS.md." >&2
        exit 2
    fi
done

cmake -S "$root/third_party/tdlib-purple" -B "$AMETHYST_TELEGRAM_BUILD_DIR" \
    -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=i686 \
    -DCMAKE_CXX_COMPILER="$AMETHYST_MINGW_CXX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-D_WIN32_WINNT=$windows_version -DWINVER=$windows_version -DNTDDI_VERSION=$ntddi_version -DG_SOURCE_REMOVE=FALSE -DG_SOURCE_CONTINUE=TRUE -I$AMETHYST_OPENSSL_PREFIX/include -I$AMETHYST_TDLIB_SOURCE/tdutils -I$AMETHYST_TDLIB_BUILD/tdutils" \
    -DCMAKE_SHARED_LINKER_FLAGS="-static-libgcc -static-libstdc++ $winpthread_link -Wl,--subsystem,windows,--major-subsystem-version,$subsystem_major,--minor-subsystem-version,$subsystem_minor" \
    -DTd_DIR="$AMETHYST_TDLIB_DIR" \
    -DNoPkgConfig=True -DNoPidgin=False -DNoVoip=True -DNoLottie=True -DNoTranslations=True \
    -Dfmt_INCLUDE_DIRS="$AMETHYST_FMT_PREFIX/include" \
    -DPidgin_INCLUDE_DIRS="$root/pidgin;$root/pidgin/win32;$AMETHYST_GTK_SDK/include/gtk-2.0;$AMETHYST_GTK_SDK/include/atk-1.0;$AMETHYST_GTK_SDK/include/cairo;$AMETHYST_GTK_SDK/include/pango-1.0;$AMETHYST_GTK_SDK/lib/gtk-2.0/include" \
    -Dfmt_LIBRARIES="$AMETHYST_FMT_PREFIX/lib/libfmt.a" \
    -DPurple_INCLUDE_DIRS="$root/libpurple;$AMETHYST_GLIB_SDK/include/glib-2.0;$AMETHYST_GTK_SDK/include/glib-2.0;$AMETHYST_GLIB_SDK/lib/glib-2.0/include" \
    -DPurple_LIBRARIES="$root/libpurple/libpurple.dll.a;$AMETHYST_GLIB_SDK/lib/libglib-2.0.dll.a;$AMETHYST_GLIB_SDK/lib/libgobject-2.0.dll.a;$AMETHYST_GLIB_SDK/lib/libgthread-2.0.dll.a" \
    -DGModule_LIBRARIES="$AMETHYST_GLIB_SDK/lib/libgmodule-2.0.dll.a" \
    -DGIO_LIBRARIES="$AMETHYST_GLIB_SDK/lib/libgio-2.0.dll.a" \
    -DZLIB_INCLUDE_DIR="$AMETHYST_ZLIB_PREFIX/include" \
    -DZLIB_LIBRARY="$AMETHYST_ZLIB_PREFIX/lib/libz.a" \
    -DAPI_ID="${AMETHYST_TELEGRAM_API_ID:-94575}" \
    -DAPI_HASH="${AMETHYST_TELEGRAM_API_HASH:-a3406de8d171bb422bb6ddf3bbd800e2}"

cmake --build "$AMETHYST_TELEGRAM_BUILD_DIR" --target telegram-tdlib --parallel "${JOBS:-4}"
mkdir -p "$AMETHYST_TELEGRAM_OUTPUT_DIR"
SOURCE_DATE_EPOCH=0 i686-w64-mingw32-strip --strip-unneeded \
    -o "$AMETHYST_TELEGRAM_OUTPUT_DIR/libtelegram-tdlib.dll" \
    "$AMETHYST_TELEGRAM_BUILD_DIR/libtelegram-tdlib.dll"

objdump=${AMETHYST_MINGW_OBJDUMP:-i686-w64-mingw32-objdump}
metadata=$("$objdump" -p "$AMETHYST_TELEGRAM_OUTPUT_DIR/libtelegram-tdlib.dll")
major=$(awk '/MajorSubsystemVersion/{print $2; exit}' <<<"$metadata")
minor=$(awk '/MinorSubsystemVersion/{print $2; exit}' <<<"$metadata")
test "$major" = "$subsystem_major" && test "$minor" = "$subsystem_minor"
if [[ "$target" == xp ]] && grep -Eq 'AcquireSRWLock|InitializeSRWLock|ReleaseSRWLock|ConditionVariable|GetTickCount64|GetFileInformationByHandleEx|IdnToAscii|WSASendMsg' <<<"$metadata"; then
    echo "Vista-only imports remain in XP Telegram plugin" >&2
    exit 1
fi
echo "Telegram plugin built for $target (PE subsystem $major.$minor) in $AMETHYST_TELEGRAM_OUTPUT_DIR"
