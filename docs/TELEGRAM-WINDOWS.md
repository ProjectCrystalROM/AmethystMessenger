# Telegram plugin on Windows

The Windows installer includes `libtelegram-tdlib.dll`, built from the
GPL-licensed [tdlib-purple](https://github.com/UnitedMarsupials/tdlib-purple)
plugin. It registers as **Telegram (tdlib)**. The original Pidgin 2.11.0
libpurple runtime remains in use; an application upgrade was not needed.

## Compatibility

The Amethyst executable and existing protocols retain the Windows XP x86
target. The Telegram DLL is built for Vista (PE subsystem 6.0) and imports
Vista-era APIs including `GetTickCount64`, SRW locks, and condition variables.
Consequently Telegram is available on Vista SP2 and later, while the XP-targeted
application and its other plugins remain usable on XP. The DLL does not load on
XP. This is based on static PE inspection; no Vista Telegram login has been
verified yet.

The plugin loads in the Linux-hosted Wine smoke test and is initialized by
libpurple. That verifies plugin packaging and ABI loading only, not Telegram
authentication, message exchange, or target-Windows compatibility.

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
small and compatible with GTK 2.14.7/GLib 2.28.8. Core messaging is available;
feature coverage still needs interactive testing.

## Build the plugin

The plugin uses C++14, TDLib, OpenSSL, fmt, zlib, and the Windows SDKs listed in
[BUILD-WINDOWS.md](BUILD-WINDOWS.md). The build script expects those dependencies
to be built for i686 Windows and installed in separate prefixes. Pins used for
this build are recorded in [THIRD-PARTY-SOURCES.md](THIRD-PARTY-SOURCES.md).
`AMETHYST_TDLIB_SOURCE` and `AMETHYST_TDLIB_BUILD` refer to the same TDLib source
and cross-build directories used to make the static TDLib libraries.

Before configuring TDLib, apply the checked-in Windows compatibility patch:

```sh
patch -d "$AMETHYST_TDLIB_SOURCE" -p1 < third_party/patches/tdlib-desktop-vista.patch
```

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
