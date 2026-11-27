# Compatibility and validation report

## Build target

The distributable is an x86 PE application built with the MinGW-w64 i686 Win32-thread compiler and the Pidgin 2.11.0 GTK2/GLib runtime. The compile flags set `_WIN32_WINNT=0x0501` and `WINVER=0x0501`. The launcher, GTK UI, and libpurple DLL use PE subsystem version 5.1. The rebuilt Windows preferences plugin and installer use subsystem 4.0. `libtelegram-tdlib.dll` is also x86 but uses PE subsystem 6.0 and a Vista API target.

The compiled application dynamically loads the original GTK2 runtime and existing runtime modules. No Universal CRT, Visual C++ redistributable, Windows API-set, or `api-ms-win-*` imports were found in a recursive scan of 111 PE files from the installed tree. The app uses `libssp-0.dll`, which is already included in the official Pidgin 2.11.0 Windows runtime. The built application imports the existing Windows system DLL set. Imports added compared with the official launcher, UI, libpurple, and Windows preferences module are legacy Kernel32/MSVCRT functions and `DnsFree`; no newer Windows dependency was introduced. Three unresolved imports belong to the optional Perl plugin's external `perl520.dll`, which was not part of the official runtime payload; other listed unresolved names are standard Windows modules (`msimg32.dll`, `usp10.dll`, and `wsock32.dll`).

This is static compatibility evidence. The compiler version and PE subsystem alone cannot establish that the binaries run on XP or Vista.

The Telegram plugin statically links TDLib, OpenSSL 3, fmt, zlib, and the MinGW C++ runtime. Its direct DLL imports are the bundled GLib/GIO/GModule and libpurple DLLs, plus standard Windows system libraries; it has no OpenSSL, zlib, libstdc++, or libgcc DLL dependency. The import table includes Vista APIs such as `GetTickCount64`, SRW locks, condition variables, and `GetFileInformationByHandleEx`. It therefore cannot load on XP, even though the Amethyst executable, libpurple, and other protocols retain the XP target. Static import inspection identifies Vista as the minimum target; only Wine loading was performed.

The Discord plugin is a separate Vista-targeted x86 DLL (PE subsystem 6.0). It imports Vista's `InitializeSRWLock`, links OpenSSL crypto and QRencode statically for QR login, and imports JSON-GLib plus the existing bundled GLib, libpurple, and zlib runtimes. JSON-GLib's DLL was built against the bundled GLib 2.28 SDK. Initial PE inspection shows no API-set or Universal CRT dependency; Vista is the minimum indicated by its imports. Wine package and plugin-load smoke testing is pending. Discord authentication, QR approval, messaging, and runtime testing on Vista are unverified. The Discord plugin cannot run on XP.

## Tests performed

| Check | Result |
| --- | --- |
| Windows build and NSIS installer | Passed. `make -f Makefile.mingw installer_offline` path invokes the Amethyst package script. |
| Installer execution | Passed in a new Wine prefix. Silent install and update completed; Start Menu entries and Amethyst uninstall registry values were created. Silent uninstall removed the application and preserved the Amethyst profile. |
| Branding metadata | Passed. Installer reports Product Name `Amethyst Messenger`, Publisher `Project Crystal`, and version `2.11.0`. Launcher reports `amethyst.exe`, `Amethyst Messenger`, and the same version. |
| Launcher startup | Passed in Wine. `amethyst.exe --version` reports `Amethyst Messenger 2.11.0 (libpurple 2.11.0)`. |
| GTK application startup | Passed in Wine with `--debug --nologin`. The GTK2 interface initialized and remained running through the 16-second smoke window. The process was stopped by the timeout. |
| MSN implementation | Passed in Wine using a no-credential protocol probe. The installed `prpl-msn-pecan` implementation loaded and returned account-picker name `MSN`. |
| Telegram plugin | Built against libpurple 2.11.0 and loaded in a fresh Wine-installed package. Debug output confirms plugin initialization. Account-picker interaction and Telegram sign-in/messaging were not tested. |
| Discord plugin build | Passed from checked-in, SHA-256-pinned JSON-GLib 0.14.2 and libqrencode 4.1.1 source archives. `USE_QRCODE_AUTH` is enabled; QRencode and OpenSSL crypto are statically linked. |
| Discord plugin and icon loading | Passed Wine package/startup probe with JSON-GLib runtime and 16, 22, and 48 px protocol icons included. No plugin load error was logged. |
| Discord consent dialog | Passed in Wine using a temporary account with no credentials. The first-connect warning appeared; choosing its default decline action disabled that account (`auto-login=0`). No Discord authentication request was made. Continue/accept behavior remains untested. |
| Discord login and messages | Not tested; QR approval, contacts, presence, chat, and reconnection have not been exercised against Discord. |
| Plugin selection | Passed. The installer contains `plugins/libmsn.dll` from msn-pecan and omits `pidgin.exe` and the upstream native MSN DLL. Existing protocol plugins are retained. |
| Dependencies | Passed static recursive PE inspection for x86 architecture, API-set imports, and Universal CRT imports. Existing GTK2, NSS, and support DLLs were retained. |
| Windows Vista SP2 | Not tested with this branded package. A user previously verified login and adding a buddy with the integrated Pecan implementation on Vista SP2. |
| Windows XP SP3 x86 | Static assessment only; no runtime test. |
| Windows XP Professional x64 SP2 through WOW64 | Static assessment only; no runtime test. |
| Windows Vista SP2 x64 through WOW64 | Static assessment only; no runtime test. |
| Live CrossTalk authentication and messaging | Not tested in this build environment. No account password was available here. Contact synchronization, presence, bidirectional messaging, file transfer, and reconnection remain to be checked with live accounts. |

Wine reported that the optional Perl plugin could not load without Perl 5.20 and emitted a GtkSpell/Enchant setup warning. These components do not prevent Amethyst or MSN from starting. The official Pidgin runtime did not bundle the Perl runtime.

## Platform matrix

| Operating system | Status |
| --- | --- |
| Windows XP SP3 x86 | Static target configured; untested |
| Windows XP Professional x64 SP2 (WOW64) | x86 build; statically assessed; untested |
| Windows Vista SP2 x86 | Earlier integrated Pecan behavior verified by the user; this branded installer untested |
| Windows Vista SP2 x64 (WOW64) | x86 build; statically assessed; untested |
| Wine | Installer, version resource, UI startup, and MSN protocol label checked |

Telegram specifically is unavailable on XP and is only statically assessed for Vista-and-later Windows. Wine confirms the DLL loads under Pidgin 2.11.0 libpurple, but not that Telegram servers accept the default upstream test API ID or that messaging works.
