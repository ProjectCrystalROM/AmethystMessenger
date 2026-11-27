#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 2 ]]; then
    echo "Usage: $0 INPUT_DIRECTORY OUTPUT_DIRECTORY" >&2
    exit 2
fi
telegram_dll=${AMETHYST_TELEGRAM_DLL:-}
if [[ -z "$telegram_dll" || ! -f "$telegram_dll" ]]; then
    echo "Set AMETHYST_TELEGRAM_DLL to the built tdlib-purple DLL." >&2
    exit 2
fi
discord_dll=${AMETHYST_DISCORD_DLL:-}
json_glib_dll=${AMETHYST_JSON_GLIB_DLL:-}
if [[ -z "$discord_dll" || ! -f "$discord_dll" || -z "$json_glib_dll" || ! -f "$json_glib_dll" ]]; then
    echo "Set AMETHYST_DISCORD_DLL and AMETHYST_JSON_GLIB_DLL to the outputs of build-discord-plugin.sh." >&2
    exit 2
fi
root=$(cd "$(dirname "$0")/../.." && pwd)
inputs=$(realpath "$1")
output=$(realpath -m "$2")
work=$(mktemp -d)
trap 'find "$work" -depth -delete' EXIT

(cd "$inputs" && sha256sum -c "$root/packaging/windows/inputs.sha256")
unzip -q "$inputs/gtk-sdk.zip" -d "$work/gtk"
unzip -q "$inputs/glib-sdk.zip" -d "$work/glib"
tar -xzf "$inputs/libxml2-sdk.tar.gz" -C "$work"
tar -xjf "$inputs/gtkspell-sdk.tar.bz2" -C "$work"

# Use the checked-in Windows configuration, even if this checkout was also
# configured for a native Unix build.
version=$(cat "$root/VERSION")
sed -e "s/@VERSION@/$version/; s/@DISPLAY_VERSION@/$version/" "$root/config.h.mingw" > "$root/config.h"
rm -f "$root/libpurple/version.h"

args=(CC=i686-w64-mingw32-gcc-win32 WINDRES=i686-w64-mingw32-windres
      GTK_TOP="$work/gtk" GLIB_TOP="$work/glib"
      LIBXML2_TOP="$work/libxml2-2.9.2_daa1" GTKSPELL_TOP="$work/gtkspell-2.0.16")
cd "$root"
make -C libpurple -f Makefile.mingw -j "${JOBS:-4}" "${args[@]}" libpurple.dll \
    DLL_LD_FLAGS='-lssp -static-libgcc -Wl,--major-subsystem-version,5,--minor-subsystem-version,1,--dynamicbase,--nxcompat,--no-insert-timestamp'
make -C pidgin -f Makefile.mingw -j "${JOBS:-4}" "${args[@]}" pidgin.dll
make -C pidgin -f Makefile.mingw "${args[@]}" amethyst.exe
make -C libpurple/protocols/msn -f Makefile.mingw -j "${JOBS:-4}" "${args[@]}" all
make -C pidgin/plugins/win32/winprefs -f Makefile.mingw -j "${JOBS:-4}" "${args[@]}" all

# Reuse the official 2.11.0 dependency and unaffected plugin payload.
payload="$work/payload"
7z x -y "-o$payload" '-x!$PLUGINSDIR' '-x!pidgin-uninst.exe.nsis' '-x!pidgin.exe' \
      '-x!pidgin.dll' '-x!libpurple.dll' '-x!plugins/libmsn.dll' '-x!plugins/winprefs.dll' \
      '-x!pixmaps/pidgin/icons' "$inputs/pidgin-2.11.0-offline.exe" >/dev/null
7z e -y "-o$work" "$inputs/pidgin-2.11.0-offline.exe" '$PLUGINSDIR/gtk.zip' >/dev/null
unzip -q "$work/gtk.zip" -d "$payload"
test ! -e "$payload/plugins/libmsn.dll"
test ! -e "$payload/pidgin.exe"

install_pe() {
    SOURCE_DATE_EPOCH=0 i686-w64-mingw32-strip --strip-unneeded -o "$payload/$2" "$1"
}
install_pe pidgin/amethyst.exe amethyst.exe
install_pe pidgin/pidgin.dll pidgin.dll
install_pe libpurple/libpurple.dll libpurple.dll
install_pe libpurple/protocols/msn/libmsn.dll plugins/libmsn.dll
install_pe "$telegram_dll" plugins/libtelegram-tdlib.dll
install_pe "$discord_dll" plugins/libdiscord.dll
install -m 644 "$json_glib_dll" "$payload/libjson-glib-1.0-0.dll"
install_pe pidgin/plugins/win32/winprefs/winprefs.dll plugins/winprefs.dll
mkdir -p "$payload/pixmaps/pidgin/protocols"/{16,22,48}
install -m 644 third_party/tdlib-purple/data/telegram16.png "$payload/pixmaps/pidgin/protocols/16/telegram.png"
install -m 644 third_party/tdlib-purple/data/telegram22.png "$payload/pixmaps/pidgin/protocols/22/telegram.png"
install -m 644 third_party/tdlib-purple/data/telegram48.png "$payload/pixmaps/pidgin/protocols/48/telegram.png"
make -C pidgin/pixmaps -f Makefile.mingw PIDGIN_INSTALL_DIR="$payload" install
make -C share/ca-certs -f Makefile.mingw PIDGIN_INSTALL_DIR="$payload" install

mkdir -p "$payload/Licenses"
cp COPYING "$payload/COPYING"
cp COPYRIGHT "$payload/Licenses/Pidgin-Copyright.txt"
cp libpurple/protocols/msn/{COPYING,AUTHORS,pidgin-copyright} "$payload/Licenses/"
cp libpurple/protocols/msn/ext/libmspack/COPYING.LIB "$payload/Licenses/"
cp docs/LICENSING.md "$payload/Licenses/"
cp third_party/tdlib-purple/LICENSE "$payload/Licenses/tdlib-purple-GPL.txt"
cp third_party/tdlib-purple/README.md "$payload/Licenses/tdlib-purple-README.md"
cp third_party/purple-discord/LICENSE "$payload/Licenses/purple-discord-GPL.txt"
cp third_party/purple-discord/README.md "$payload/Licenses/purple-discord-README.md"
cp third_party/sources/json-glib-0.14.2.tar.xz "$payload/Licenses/"
cp third_party/sources/libqrencode-4.1.1.tar.gz "$payload/Licenses/"
cp third_party/sources/SHA256SUMS-discord "$payload/Licenses/"
tar -xOf third_party/sources/json-glib-0.14.2.tar.xz json-glib-0.14.2/COPYING > "$payload/Licenses/JSON-GLib-LGPL-2.1.txt"
tar -xOf third_party/sources/libqrencode-4.1.1.tar.gz libqrencode-4.1.1/COPYING > "$payload/Licenses/libqrencode-LGPL-2.1.txt"
cp third_party/licenses/* "$payload/Licenses/"
touch "$payload/.amethyst-messenger"

python3 - "$payload" > "$work/remove.nsh" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
for entry in sorted(root.rglob("*"), key=lambda path: (-len(path.parts), path)):
    target = str(entry.relative_to(root)).replace("/", "\\").replace("$", "$$")
    command = "RMDir" if entry.is_dir() else "Delete"
    print(f'    {command} "$INSTDIR\\{target}"')
PY

mkdir -p "$output"
setup="$output/amethyst-messenger-2.11.0-win32.exe"
makensis "-DOUTPUT=$setup" "-DPAYLOAD=$payload" "-DREMOVAL=$work/remove.nsh" \
    "-DICON=$root/pidgin/pixmaps/pidgin.ico" "$root/packaging/windows/amethyst.nsi"
(cd "$output" && sha256sum "$(basename "$setup")" > SHA256SUMS)
