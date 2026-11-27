# Windows build and compatibility

Amethyst Messenger builds as a 32-bit Windows application. The compiler target uses MinGW-w64 i686, `_WIN32_WINNT=0x0501`, `WINVER=0x0501`, and PE subsystem 5.1. Runtime and development libraries follow the Pidgin 2.11.0 GTK2 build. The GTK SDK and GLib SDK serve compilation; the unchanged official Pidgin 2.11.0 runtime supplies bundled GTK2 and supporting protocol dependencies.

## Pinned inputs

The build script expects these files in an input directory. Obtain the original artifacts from their upstream distribution sources and verify the hashes recorded in `packaging/windows/inputs.sha256` before use.

- `pidgin-2.11.0-offline.exe`, official Windows runtime distribution.
- `gtk-sdk.zip`, GTK+ 2.14.7 development SDK used by the historical build.
- `glib-sdk.zip`, GLib 2.28.8 development SDK.
- `libxml2-sdk.tar.gz`, libxml2 2.9.2 Windows SDK.
- `gtkspell-sdk.tar.bz2`, GtkSpell 2.0.16 Windows SDK.

Use a Linux host with MinGW-w64 i686 GCC/binutils, GNU make, 7-Zip, NSIS 3, Python 3, `unzip`, and `tar`. The upstream generated Windows makefiles are retained. Build with:

```sh
AMETHYST_TELEGRAM_DLL=/path/to/telegram-plugin-output/libtelegram-tdlib.dll \
AMETHYST_DISCORD_DLL=/path/to/discord-plugin-output/libdiscord.dll \
AMETHYST_JSON_GLIB_DLL=/path/to/discord-plugin-output/libjson-glib-1.0-0.dll \
make -f Makefile.mingw installer_offline \
  AMETHYST_INPUTS=/path/to/verified-inputs \
  AMETHYST_OUTPUT="$PWD/output"
```

The output is `amethyst-messenger-2.11.0-win32.exe`, with `SHA256SUMS`. `packaging/windows/build.sh` builds libpurple, the GTK UI, launcher, and msn-pecan plugin, then stages the unaffected official runtime plus Telegram and Discord plugins. Build tdlib-purple as described in [Telegram on Windows](TELEGRAM-WINDOWS.md). Build Discord and its QR login support with [Discord on Windows](DISCORD-WINDOWS.md); this emits both the plugin and its JSON-GLib runtime. The package omits the old launcher and native MSN plugin. It does not modify an existing installation or user profile.

The build regenerates the Windows `config.h` from the checked-in MinGW template with the release version substituted, then regenerates the MinGW `libpurple/version.h`. The application and libpurple use the x86 XP API target and PE subsystem version 5.1 with static MinGW GCC runtime linkage. The NSIS installer contains no OS-version gate; source inspection found no launcher check that rejects NT 5.2 (XP x64) or distinguishes x86 from x64 Vista. A launcher version check only selects a DLL-search compatibility path. The same 32-bit package is intended to run natively on x86 and through WOW64 on x64. Review all resulting PE imports with `objdump -p` or PE inspection tools, including recursively bundled DLLs, whenever compiler or runtime inputs change. Static inspection does not replace XP runtime testing.

## Runtime checks and status

A Wine startup smoke test can check installer operation, executable launch, resource metadata, and protocol registration. Wine is not a Windows XP or Vista test. The branded package has been used on Vista SP2; the tester confirmed Telegram DM/group/topic send and receive, Discord QR login and DM/server send and receive, and earlier MSN sign-in and buddy addition. XP remains statically assessed pending a machine or VM test.

To test MSN, create a new **MSN** account using CrossTalk credentials. The client writes its separate profile to `%APPDATA%\Amethyst Messenger`. Do not put credentials or session logs in the repository. Redact them from diagnostic output.

## Corresponding source

This repository contains the Amethyst/Pidgin and integrated msn-pecan source, Windows build scripts, input hashes, and upstream notices. Third-party binary runtime dependencies retain their upstream licenses and source obligations. See [LICENSING.md](LICENSING.md) for the source provenance and remaining archive work.
