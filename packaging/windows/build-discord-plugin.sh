#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
extra=${AMETHYST_WINDOWS_EXTRA:-$(cd "$root/../.amethyst-build/windows-extra" && pwd)}
flavor=${AMETHYST_DISCORD_FLAVOR:-xp}
case "$flavor" in
    xp)
        winver=0x0501
        subsystem_major=5
        subsystem_minor=1
        openssl_default="$extra/openssl-xp-install"
        qr_auth=no
        ;;
    modern)
        # Vista SP2 is the modern flavor's minimum target. This retains QR
        # auth and its upstream OpenSSL crypto implementation.
        winver=0x0600
        subsystem_major=6
        subsystem_minor=0
        openssl_default="$extra/openssl-install"
        qr_auth=yes
        ;;
    *)
        echo "AMETHYST_DISCORD_FLAVOR must be 'xp' or 'modern'" >&2
        exit 2
        ;;
esac

gtk=${AMETHYST_GTK_SDK:-$extra/gtk-sdk}
glib=${AMETHYST_GLIB_SDK:-$extra/glib-sdk}
openssl=${AMETHYST_OPENSSL_PREFIX:-$openssl_default}
zlib=${AMETHYST_ZLIB_PREFIX:-$extra/usr/i686-w64-mingw32}
build=${AMETHYST_DISCORD_BUILD_DIR:-$root/.build/discord-$flavor-win32}
output=${AMETHYST_DISCORD_OUTPUT_DIR:-$root/output/discord-$flavor}
cc=${AMETHYST_MINGW_CC:-i686-w64-mingw32-gcc-win32}
objdump=${AMETHYST_MINGW_OBJDUMP:-i686-w64-mingw32-objdump}

required_paths=("$gtk" "$glib" "$zlib")
if [[ "$qr_auth" == yes ]]; then
    required_paths+=("$openssl")
fi
for path in "${required_paths[@]}"; do
    if [[ ! -d "$path" ]]; then
        echo "Required SDK/prefix directory is missing: $path" >&2
        exit 2
    fi
done
for tool in "$cc" "$objdump" cmake pkg-config; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 2; }
done

source_dir="$root/third_party/sources"
(cd "$source_dir" && sha256sum -c SHA256SUMS-discord)
mkdir -p "$build" "$output"

json_src="$build/json-glib-0.14.2"
json_build="$build/json-glib-build"
json_prefix="$build/json-glib-install"
if [[ ! -f "$json_src/configure" ]]; then
    mkdir -p "$json_src"
    tar -xJf "$source_dir/json-glib-0.14.2.tar.xz" -C "$json_src" --strip-components=1
fi
mkdir -p "$json_build" "$json_prefix"
cat > "$build/pkg-config-glib" <<'EOF'
#!/bin/sh
exec pkg-config --define-variable=prefix="$AMETHYST_GLIB_SDK" "$@"
EOF
chmod +x "$build/pkg-config-glib"
export AMETHYST_GLIB_SDK="$glib"
export PKG_CONFIG_PATH="$glib/lib/pkgconfig"
if [[ ! -f "$json_build/Makefile" ]]; then
    (cd "$json_build" && \
        PKG_CONFIG="$build/pkg-config-glib" \
        CC="$cc" CFLAGS='-O2 -D_WIN32_WINNT=0x0501 -DWINVER=0x0501' \
        CPPFLAGS="-I$gtk/include" \
        LDFLAGS="-L$glib/lib -L$gtk/lib" \
        "$json_src/configure" --host=i686-w64-mingw32 --build=x86_64-pc-linux-gnu \
        --prefix="$json_prefix" --disable-gtk-doc)
fi
make -C "$json_build/json-glib" -j "${JOBS:-4}" \
    CPPFLAGS="-I$gtk/include" LDFLAGS="-L$glib/lib -L$gtk/lib" \
    libjson-glib-1.0.la
make -C "$json_build/json-glib" install-exec-am install-data-am \
    CPPFLAGS="-I$gtk/include" LDFLAGS="-L$glib/lib -L$gtk/lib"

qr_prefix="$build/qrencode-install"
if [[ "$qr_auth" == yes ]]; then
    qr_src="$build/libqrencode-4.1.1"
    qr_build="$build/qrencode-build"
    if [[ ! -f "$qr_src/CMakeLists.txt" ]]; then
        mkdir -p "$qr_src"
        tar -xzf "$source_dir/libqrencode-4.1.1.tar.gz" -C "$qr_src" --strip-components=1
    fi
    cmake -S "$qr_src" -B "$qr_build" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=i686 \
        -DCMAKE_C_COMPILER="$cc" -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$qr_prefix" -DBUILD_SHARED_LIBS=OFF \
        -DWITH_TOOLS=OFF -DWITH_TESTS=OFF -DWITHOUT_PNG=ON
    cmake --build "$qr_build" --parallel "${JOBS:-4}"
    cmake --install "$qr_build"
fi

discord="$root/third_party/purple-discord"
version="0.9.2026.11.27.amethyst.$(git -C "$root" rev-parse --short HEAD)-$flavor"
defines=(-D_WIN32_WINNT="$winver" -DWINVER="$winver"
    -DDISCORD_PLUGIN_VERSION='"'"$version"'"' -DMARKDOWN_PIDGIN)
includes=(-I"$root/libpurple" -I"$root/libpurple/win32" -I"$root"
    -I"$discord/purple2compat"
    -I"$glib/include/glib-2.0" -I"$glib/lib/glib-2.0/include" -I"$gtk/include"
    -I"$json_prefix/include/json-glib-1.0" -I"$zlib/include")
libs=(-L"$root/libpurple" -L"$glib/lib" -L"$json_prefix/lib"
    -L"$gtk/lib" -L"$zlib/lib")
link_flags=(-ljson-glib-1.0 -lgio-2.0 -lgobject-2.0 -lgmodule-2.0
    -lgthread-2.0 -lglib-2.0 -lintl)
if [[ "$qr_auth" == yes ]]; then
    defines+=(-DUSE_QRCODE_AUTH -DUSE_OPENSSL_CRYPTO)
    includes+=(-I"$openssl/include" -I"$qr_prefix/include")
    libs+=(-L"$openssl/lib" -L"$qr_prefix/lib")
    link_flags+=(-lqrencode -lcrypto)
fi

"$cc" -O2 -std=c99 -Wall -Wextra -Wno-deprecated-declarations \
    -Wno-unused-parameter -fno-strict-aliasing -Wformat -static-libgcc -shared \
    "${defines[@]}" "${includes[@]}" "${libs[@]}" \
    -Wl,--major-subsystem-version,"$subsystem_major",--minor-subsystem-version,"$subsystem_minor" \
    -Wl,--enable-auto-image-base,--enable-auto-import \
    -o "$output/libdiscord.dll" \
    "$discord/libdiscord.c" "$discord/markdown.c" "$discord/discord_lottie.c" \
    "$discord"/purple2compat/*.c \
    -lpurple "${link_flags[@]}" \
    -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic -lz -lws2_32 -lgdi32 -lcrypt32

install -m 644 "$json_prefix/bin/libjson-glib-1.0-0.dll" "$output/"
"${cc%gcc*}strip" --strip-unneeded "$output/libdiscord.dll" "$output/libjson-glib-1.0-0.dll"
sha256sum "$output/libdiscord.dll" "$output/libjson-glib-1.0-0.dll" > "$output/SHA256SUMS"

if [[ "$flavor" == xp ]]; then
    for dll in "$output/libdiscord.dll" "$output/libjson-glib-1.0-0.dll"; do
        imports=$("$objdump" -p "$dll")
        if grep -Eq 'AcquireSRWLock|InitializeSRWLock|ReleaseSRWLock|ConditionVariable|GetTickCount64|GetFileInformationByHandleEx' <<<"$imports"; then
            echo "Vista-only imports remain in $dll" >&2
            exit 1
        fi
    done
fi
discord_metadata=$("$objdump" -p "$output/libdiscord.dll")
discord_subsystem=$(awk '/MajorSubsystemVersion/{print $2; exit}' <<<"$discord_metadata")
discord_minor=$(awk '/MinorSubsystemVersion/{print $2; exit}' <<<"$discord_metadata")
test "$discord_subsystem" = "$subsystem_major" && test "$discord_minor" = "$subsystem_minor"
discord_strings=$(strings "$output/libdiscord.dll")
if [[ "$qr_auth" == no ]] && grep -Eqi 'remote-auth-gateway|remote-auth/login' <<<"$discord_strings"; then
    echo "QR authentication symbols or endpoints remain in XP Discord DLL" >&2
    exit 1
fi
echo "Discord $flavor plugin and JSON-GLib runtime built in $output (QR auth: $qr_auth)"
