# Windows build and compatibility

Amethyst Messenger builds as a 32-bit Windows application based on the Pidgin
2.11.0 GTK2/GLib runtime. The main application uses MinGW-w64 i686,
`_WIN32_WINNT=0x0501`, `WINVER=0x0501`, and PE subsystem 5.1. The Discord plugin
is built separately for each release flavor: XP (subsystem 5.1, no QR auth) or
modern (Vista API target/subsystem 6.0, QR auth enabled). The unchanged official
Pidgin 2.11.0 runtime supplies bundled GTK2 and supporting protocol
dependencies.

## Pinned inputs

The build script expects these files in an input directory. Obtain the original
artifacts from their upstream distribution sources and verify the hashes
recorded in `packaging/windows/inputs.sha256` before use.

- `pidgin-2.11.0-offline.exe`, official Windows runtime distribution.
- `gtk-sdk.zip`, GTK+ 2.14.7 development SDK used by the historical build.
- `glib-sdk.zip`, GLib 2.28.8 development SDK.
- `libxml2-sdk.tar.gz`, libxml2 2.9.2 Windows SDK.
- `gtkspell-sdk.tar.bz2`, GtkSpell 2.0.16 Windows SDK.

Use a Linux host with MinGW-w64 i686 GCC/binutils, GNU make, 7-Zip, NSIS 3,
Python 3, `unzip`, and `tar`. Build Discord once for each flavor:

```sh
AMETHYST_DISCORD_FLAVOR=xp packaging/windows/build-discord-plugin.sh
AMETHYST_DISCORD_FLAVOR=modern packaging/windows/build-discord-plugin.sh
```

Build both installers by passing the matching plugin paths and release flavor
to `packaging/windows/build.sh`:

```sh
AMETHYST_TELEGRAM_DLL=/path/to/telegram-plugin-output/libtelegram-tdlib.dll \
AMETHYST_DISCORD_DLL=/path/to/discord-xp/libdiscord.dll \
AMETHYST_JSON_GLIB_DLL=/path/to/discord-xp/libjson-glib-1.0-0.dll \
AMETHYST_RELEASE_FLAVOR=xp \
packaging/windows/build.sh /path/to/verified-inputs output/release-xp

AMETHYST_TELEGRAM_DLL=/path/to/telegram-plugin-output/libtelegram-tdlib.dll \
AMETHYST_DISCORD_DLL=/path/to/discord-modern/libdiscord.dll \
AMETHYST_JSON_GLIB_DLL=/path/to/discord-modern/libjson-glib-1.0-0.dll \
AMETHYST_RELEASE_FLAVOR=modern \
packaging/windows/build.sh /path/to/verified-inputs output/release-modern
```

The installers are named `amethyst-messenger-2.11.0-win32-xp.exe` and
`amethyst-messenger-2.11.0-win32.exe`, respectively. Each output folder
contains its own `SHA256SUMS`. The release retains AIM, MSN (the integrated
msn-pecan implementation), XMPP, Discord, and Telegram. Other upstream
protocol plugin DLLs are removed from the installers while their source
remains in the repository. Telegram currently requires Vista or later; its DLL
is retained in both packages as before, but is not available on XP.

The installer packages the official runtime and does not modify an existing
installation or user profile. It omits the old launcher and native MSN plugin.

## Compatibility and validation

The main app, launcher, and libpurple use the x86 XP API target and PE
subsystem 5.1 with static MinGW GCC runtime linkage. The installer has no OS
version gate; the same 32-bit package is intended to run natively on XP x86 and
through WOW64 on XP x64. Review PE imports of all new binaries and recursively
bundled DLLs whenever compiler/runtime inputs change. Static inspection does
not replace OS testing.

The XP Discord build omits the QR remote-auth implementation, QRencode, and
OpenSSL crypto; password and 2FA login are retained. The modern build keeps QR
login for Vista SP2 and later. The user successfully logged in with password
and 2FA on XP before this release split, using the prior XP-targeted build that
still included QR; testing the final no-QR package remains. The user confirmed
QR login and Discord DM/server messaging on Vista using the earlier modern
build. See [COMPATIBILITY.md](COMPATIBILITY.md) for the tested/static/untested
matrix.

To test MSN, create a new **MSN** account using CrossTalk credentials. The
client writes its separate profile to `%APPDATA%/Amethyst Messenger`. Do not
put credentials or session logs in the repository. Redact them from diagnostic
output.

## Corresponding source

This repository contains the Amethyst/Pidgin and integrated msn-pecan source,
Windows build scripts, input hashes, and upstream notices. Third-party binary
runtime dependencies retain their upstream licenses and source obligations.
See [LICENSING.md](LICENSING.md) for source provenance and archive details.
