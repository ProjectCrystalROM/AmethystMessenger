# Telegram plugin on Windows

The Windows installer includes `libtelegram-tdlib.dll`, built from the
GPL-licensed [tdlib-purple](https://github.com/UnitedMarsupials/tdlib-purple)
plugin. It registers as **Telegram (tdlib)**. The original Pidgin 2.11.0
libpurple runtime remains in use; an application upgrade was not needed.

## Compatibility

The Amethyst executable and selected protocols retain the Windows XP target.
TDLib now has a separate XP desktop build path. It keeps the Vista code paths
for Vista builds and provides XP fallbacks for synchronization, file metadata,
timekeeping, IDN/IP formatting, and UDP sends. The XP-built Telegram plugin has
PE subsystem 5.1 and its static import table contains no known Vista-only APIs.
Its MinGW winpthread runtime is linked into the plugin, so it adds no runtime
DLL requirement. This is static compatibility evidence, not an XP runtime test.

The original Vista SP2 runtime test verified Telegram login and buddy addition;
the tester later confirmed send and receive in one-to-one DMs, group chats, and
forum topics. DM/topic history is chronological and paginated. Topic-specific
attachments remain unsupported. Telegram on XP still needs runtime testing on
the user's XP SP3 machine. IPv6 is required for Telegram connectivity in the
reported XP setup; enable the Windows IPv6 networking component.

The plugin also loads in the Linux-hosted Wine smoke test. Wine verifies
packaging and ABI loading; Telegram authentication and messaging were tested
separately on the Vista SP2 machine. The other listed Windows versions remain
untested at runtime.

## Add a Telegram account

Install Amethyst Messenger, open **Accounts → Manage Accounts**, add an account,
and choose **Telegram (tdlib)**. Enter the phone number with its country prefix
and follow Telegram's login-code and two-step verification prompts. The plugin
stores its TDLib database beneath the Amethyst profile.

The upstream source uses Telegram's public test application ID and hash by
default. Upstream warns that these test credentials may be rate limited. A
maintainer can supply their own Telegram API ID and hash at build time using
`AMETHYST_TELEGRAM_API_ID` and `AMETHYST_TELEGRAM_API_HASH`; these values are
compiled into the plugin and must not be committed if private.

The upstream build disables voice calls, animated sticker conversion,
translations, and Pidgin-window-only enhancements to keep the Windows plugin
small and compatible with GTK 2.14.7/GLib 2.28.8. Forum topic support is newly
implemented in Amethyst and still needs interactive testing.

## Forum topics

Forum supergroups appear in the room list as categories, with each visible
topic listed as a child room. They are also added to the buddy list as a
Pidgin contact group with each topic as a chat room beneath it. Joining a topic
opens its own conversation. The plugin loads the latest 50 messages when that
conversation is first opened, sends text to the selected topic, and uses
topic-scoped read receipts. The Vista tester confirmed history displays oldest-to-newest,
with the newest messages at the bottom. Scrolling fetches older topic history, and text is
displayed in both directions. One-to-one DM history also works. Topic-specific file uploads
remain unsupported.

## Build the plugin

The plugin uses C++14, TDLib, OpenSSL, fmt, zlib, and the Windows SDKs listed in
[BUILD-WINDOWS.md](BUILD-WINDOWS.md). The build script expects those dependencies
to be built for i686 Windows and installed in separate prefixes. Pins used for
this build are recorded in [THIRD-PARTY-SOURCES.md](THIRD-PARTY-SOURCES.md).
`AMETHYST_TDLIB_SOURCE` and `AMETHYST_TDLIB_BUILD` refer to the same TDLib source
and cross-build directories used to make the static TDLib libraries.

Before configuring TDLib, apply the checked-in Windows compatibility patches
in order:

```sh
patch -d "$AMETHYST_TDLIB_SOURCE" -p1 < third_party/patches/tdlib-desktop-vista.patch
patch -d "$AMETHYST_TDLIB_SOURCE" -p1 < third_party/patches/tdlib-desktop-xp.patch
```

For an XP build, configure TDLib with its Windows API target set to XP and use
the XP-compatible OpenSSL prefix. With the pinned TDLib source and generated
files available:

```sh
cmake -S "$AMETHYST_TDLIB_SOURCE" -B "$AMETHYST_TDLIB_BUILD" \
  -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_SYSTEM_PROCESSOR=i686 \
  -DCMAKE_C_COMPILER=i686-w64-mingw32-gcc-win32 \
  -DCMAKE_CXX_COMPILER="$AMETHYST_MINGW_CXX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DTD_WINDOWS_VERSION=0x0501 -DTD_NTDDI_VERSION=0x05010300 \
  -DCMAKE_C_FLAGS='-O3 -DNDEBUG' \
  -DCMAKE_CXX_FLAGS='-std=c++17 -fno-exceptions -fno-rtti -O3 -DNDEBUG' \
  -DCMAKE_INSTALL_PREFIX="$AMETHYST_TDLIB_DIR/.." \
  -DOPENSSL_ROOT_DIR="$AMETHYST_OPENSSL_PREFIX" \
  -DOPENSSL_USE_STATIC_LIBS=TRUE \
  -DZLIB_INCLUDE_DIR="$AMETHYST_ZLIB_PREFIX/include" \
  -DZLIB_LIBRARY="$AMETHYST_ZLIB_PREFIX/lib/libz.a" \
  -DTD_ENABLE_DOTNET=OFF -DTD_ENABLE_JNI=OFF -DTD_ENABLE_LTO=OFF -DTD_ENABLE_PCH=OFF
cmake --build "$AMETHYST_TDLIB_BUILD" --target install --parallel 4
```

Set `AMETHYST_TELEGRAM_TARGET=xp` when building the plugin. The build script
links winpthread statically and checks the resulting PE subsystem and imports.
`AMETHYST_TELEGRAM_TARGET=vista` remains the default and preserves the existing
Vista build behavior. Build into separate TDLib install/build directories for
XP and Vista so their static libraries cannot be mixed.

```sh
export AMETHYST_MINGW_CXX=/path/to/i686-w64-mingw32-g++
export AMETHYST_TDLIB_DIR=/path/to/tdlib-install/lib/cmake/Td
export AMETHYST_TDLIB_SOURCE=/path/to/tdlib-source
export AMETHYST_TDLIB_BUILD=/path/to/tdlib-build
export AMETHYST_OPENSSL_PREFIX=/path/to/openssl-install
export AMETHYST_FMT_PREFIX=/path/to/fmt-install
export AMETHYST_ZLIB_PREFIX=/path/to/i686-w64-mingw32
export AMETHYST_GTK_SDK=/path/to/gtk-sdk
export AMETHYST_GLIB_SDK=/path/to/glib-sdk
export AMETHYST_TELEGRAM_BUILD_DIR=/path/to/telegram-plugin-build
export AMETHYST_TELEGRAM_OUTPUT_DIR=/path/to/telegram-plugin-output
packaging/windows/build-telegram-plugin.sh
```

Then build the installer with the resulting DLL:

```sh
AMETHYST_TELEGRAM_DLL=/path/to/telegram-plugin-output/libtelegram-tdlib.dll \
  packaging/windows/build.sh /path/to/verified-pidgin-inputs output/
```

The installer stages Telegram protocol icons and the plugin license beside the
DLL. It continues to exclude the superseded native MSN plugin and includes the
CrossTalk-configured msn-pecan replacement.
