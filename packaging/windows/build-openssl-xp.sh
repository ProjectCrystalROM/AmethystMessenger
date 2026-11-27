#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
extra=${AMETHYST_WINDOWS_EXTRA:-$(cd "$root/../.amethyst-build/windows-extra" && pwd)}
source=${AMETHYST_OPENSSL_SOURCE_DIR:-}
build=${AMETHYST_OPENSSL_BUILD_DIR:-$extra/openssl-xp-build}
prefix=${AMETHYST_OPENSSL_XP_PREFIX:-$extra/openssl-xp-install}
cc_prefix=${AMETHYST_MINGW_PREFIX:-i686-w64-mingw32-}

if [[ -z "$source" || ! -x "$source/Configure" || ! -f "$source/crypto/threads_win.c" ]]; then
    echo "Set AMETHYST_OPENSSL_SOURCE_DIR to the pinned OpenSSL 3.0.0 source tree." >&2
    exit 2
fi
for tool in "${cc_prefix}gcc" make perl; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 2; }
done

mkdir -p "$build" "$prefix"
if [[ ! -f "$build/Makefile" ]]; then
    (
        cd "$build"
        CFLAGS='-Wall -O3 -fomit-frame-pointer -D_WIN32_WINNT=0x0501 -DWINVER=0x0501' \
            perl "$source/Configure" mingw no-shared no-tests no-asm \
            "--cross-compile-prefix=$cc_prefix" "--prefix=$prefix"
    )
fi
if ! grep -Fq -- '-D_WIN32_WINNT=0x0501' "$build/Makefile"; then
    echo "Existing OpenSSL build directory is not configured for Windows XP; choose a fresh AMETHYST_OPENSSL_BUILD_DIR." >&2
    exit 2
fi

make -C "$build" -j "${JOBS:-4}" build_libs
make -C "$build" install_dev
echo "XP-targeted OpenSSL 3.0.0 development files installed in $prefix"
