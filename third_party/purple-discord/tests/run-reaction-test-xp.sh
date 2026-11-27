#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../../.." && pwd)
extra=${AMETHYST_WINDOWS_EXTRA:-$(cd "$root/../.amethyst-build/windows-extra" && pwd)}
gtk=${AMETHYST_GTK_SDK:-$extra/gtk-sdk}
glib=${AMETHYST_GLIB_SDK:-$extra/glib-sdk}
json=${AMETHYST_JSON_GLIB_PREFIX:-$root/.build/discord-xp-win32/json-glib-install}
cc=${AMETHYST_MINGW_CC:-i686-w64-mingw32-gcc-win32}
wine=${WINE:-wine}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

"$cc" -std=c99 -Wall -Wextra \
	-I"$root/third_party/purple-discord" \
	-I"$json/include/json-glib-1.0" \
	-I"$glib/include/glib-2.0" \
	-I"$gtk/include/glib-2.0" \
	-I"$glib/lib/glib-2.0/include" \
	-o "$tmp/test-reaction-lookup.exe" \
	"$root/third_party/purple-discord/reaction-lookup.c" \
	"$root/third_party/purple-discord/tests/test_reaction_lookup.c" \
	-L"$json/lib" -L"$glib/lib" \
	-ljson-glib-1.0 -lgobject-2.0 -lglib-2.0

cp "$json/bin/libjson-glib-1.0-0.dll" "$tmp/"
for dll in libglib-2.0-0.dll libgobject-2.0-0.dll libgio-2.0-0.dll \
	libgmodule-2.0-0.dll zlib1.dll; do
	if [[ -f "$gtk/bin/$dll" ]]; then
		cp "$gtk/bin/$dll" "$tmp/"
	fi
done
(cd "$tmp" && WINEDEBUG=${WINEDEBUG:--all} "$wine" test-reaction-lookup.exe)
