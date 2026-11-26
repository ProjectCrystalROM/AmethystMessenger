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
make -f Makefile.mingw installer_offline \
  AMETHYST_INPUTS=/path/to/verified-inputs \
  AMETHYST_OUTPUT="$PWD/output"
```

The output is `amethyst-messenger-2.11.0-win32.exe`, with `SHA256SUMS`. `packaging/windows/build.sh` builds libpurple, the GTK UI, launcher, and msn-pecan plugin, then stages the unaffected official runtime. It omits the old launcher and native MSN plugin. It does not modify an existing installation or user profile.

The build regenerates the Windows `config.h` from the checked-in MinGW template with the release version substituted, then regenerates the MinGW `libpurple/version.h`. It embeds the 32-bit XP subsystem version and uses static MinGW GCC runtime linkage. Review all resulting PE imports with `objdump -p` or PE inspection tools, including the recursively bundled DLLs, whenever compiler or runtime inputs change. These settings alone do not prove XP compatibility.

## Runtime checks and status

A Wine startup smoke test can check installer operation, executable launch, resource metadata, and protocol registration. Wine is not a Windows XP or Vista test. The historical integrated Pecan build was previously used on Vista SP2 to sign in and add a buddy; test the branded package on the target Vista installation before calling that package runtime-verified. XP SP3 and XP x64 SP2 compatibility remain static assessments pending machine or VM tests.

To test MSN, create a new **MSN** account using CrossTalk credentials. The client writes its separate profile to `%APPDATA%\Amethyst Messenger`. Do not put credentials or session logs in the repository. Redact them from diagnostic output.

## Corresponding source

This repository contains the Amethyst/Pidgin and integrated msn-pecan source, Windows build scripts, input hashes, and upstream notices. Third-party binary runtime dependencies retain their upstream licenses and source obligations. See [LICENSING.md](LICENSING.md) for the source provenance and remaining archive work.
