#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
extra=${AMETHYST_WINDOWS_EXTRA:-$(cd "$root/../.amethyst-build/windows-extra" && pwd)}
gtk=${AMETHYST_GTK_SDK:-$extra/gtk-sdk}
glib=${AMETHYST_GLIB_SDK:-$extra/glib-sdk}
openssl=${AMETHYST_OPENSSL_PREFIX:-$extra/openssl-install}
zlib=${AMETHYST_ZLIB_PREFIX:-$extra/usr/i686-w64-mingw32}
build=${AMETHYST_DISCORD_BUILD_DIR:-$root/.build/discord-win32}
output=${AMETHYST_DISCORD_OUTPUT_DIR:-$root/output/discord-plugin}
cc=${AMETHYST_MINGW_CC:-i686-w64-mingw32-gcc-win32}

for path in "$gtk" "$glib" "$openssl" "$zlib"; do
    if [[ ! -d "$path" ]]; then
        echo "Required SDK/prefix directory is missing: $path" >&2
        exit 2
    fi
done
for tool in "$cc" cmake pkg-config; do
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
        CC="$cc" CFLAGS='-O2 -D_WIN32_WINNT=0x0600 -DWINVER=0x0600' \
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

qr_src="$build/libqrencode-4.1.1"
qr_build="$build/qrencode-build"
qr_prefix="$build/qrencode-install"
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

discord="$root/third_party/purple-discord"
version=0.9.2026.11.26.amethyst.2b85bbf
"$cc" -O2 -std=c99 -Wall -Wextra -Wno-deprecated-declarations \
    -Wno-unused-parameter -fno-strict-aliasing -Wformat -static-libgcc -shared \
    -D_WIN32_WINNT=0x0600 -DWINVER=0x0600 \
    -DDISCORD_PLUGIN_VERSION='"'"$version"'"' -DMARKDOWN_PIDGIN \
    -DUSE_QRCODE_AUTH -DUSE_OPENSSL_CRYPTO \
    -I"$root/libpurple" -I"$root/libpurple/win32" -I"$root" \
    -I"$discord/purple2compat" \
    -I"$glib/include/glib-2.0" -I"$glib/lib/glib-2.0/include" -I"$gtk/include" \
    -I"$json_prefix/include/json-glib-1.0" -I"$openssl/include" \
    -I"$qr_prefix/include" -I"$zlib/include" \
    -L"$root/libpurple" -L"$glib/lib" -L"$json_prefix/lib" \
    -L"$qr_prefix/lib" -L"$openssl/lib" -L"$gtk/lib" -L"$zlib/lib" \
    -Wl,--major-subsystem-version,6,--minor-subsystem-version,0 \
    -Wl,--enable-auto-image-base,--enable-auto-import \
    -o "$output/libdiscord.dll" \
    "$discord/libdiscord.c" "$discord/markdown.c" "$discord/discord_lottie.c" \
    "$discord"/purple2compat/*.c \
    -lpurple -ljson-glib-1.0 -lgio-2.0 -lgobject-2.0 -lgmodule-2.0 \
    -lgthread-2.0 -lglib-2.0 -lintl -lqrencode -lcrypto \
    -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic -lz -lws2_32 -lgdi32 -lcrypt32

install -m 644 "$json_prefix/bin/libjson-glib-1.0-0.dll" "$output/"
"${cc%gcc*}strip" --strip-unneeded "$output/libdiscord.dll" "$output/libjson-glib-1.0-0.dll"
sha256sum "$output/libdiscord.dll" "$output/libjson-glib-1.0-0.dll" > "$output/SHA256SUMS"
echo "Discord plugin and JSON-GLib runtime built in $output"
