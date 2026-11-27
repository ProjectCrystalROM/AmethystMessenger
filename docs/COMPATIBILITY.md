# Compatibility and validation report

## Build target

The distributable is an x86 PE application built with the MinGW-w64 i686 Win32-thread compiler and the Pidgin 2.11.0 GTK2/GLib runtime. The compile flags set `_WIN32_WINNT=0x0501` and `WINVER=0x0501`. The launcher, GTK UI, and libpurple DLL use PE subsystem version 5.1. The rebuilt Windows preferences plugin and installer use subsystem 4.0. `libtelegram-tdlib.dll` is also x86 but uses PE subsystem 6.0 and a Vista API target.

The compiled application dynamically loads the original GTK2 runtime and existing runtime modules. No Universal CRT, Visual C++ redistributable, Windows API-set, or `api-ms-win-*` imports were found in a recursive scan of 111 PE files from the installed tree. The app uses `libssp-0.dll`, which is already included in the official Pidgin 2.11.0 Windows runtime. The built application imports the existing Windows system DLL set. Imports added compared with the official launcher, UI, libpurple, and Windows preferences module are legacy Kernel32/MSVCRT functions and `DnsFree`; no newer Windows dependency was introduced. Three unresolved imports belong to the optional Perl plugin's external `perl520.dll`, which was not part of the official runtime payload; other listed unresolved names are standard Windows modules (`msimg32.dll`, `usp10.dll`, and `wsock32.dll`).

This is static compatibility evidence. The compiler version and PE subsystem alone cannot establish that the binaries run on XP or Vista.

The Telegram plugin statically links TDLib, OpenSSL 3, fmt, zlib, and the MinGW C++ runtime. Its direct DLL imports are the bundled GLib/GIO/GModule and libpurple DLLs, plus standard Windows system libraries; it has no OpenSSL, zlib, libstdc++, or libgcc DLL dependency. The import table includes Vista APIs such as `GetTickCount64`, SRW locks, condition variables, and `GetFileInformationByHandleEx`. It therefore cannot load on XP, even though the Amethyst executable, libpurple, and other protocols retain the XP target. Static inspection identifies Vista as the minimum; the user has also tested Telegram messaging on a Vista SP2 machine.

The Discord plugin is a separate Vista-targeted x86 DLL (PE subsystem 6.0). It imports Vista's `InitializeSRWLock`, links OpenSSL crypto and QRencode statically for QR login, and imports JSON-GLib plus the existing bundled GLib, libpurple, and zlib runtimes. JSON-GLib's DLL was built against the bundled GLib 2.28 SDK. PE inspection shows no API-set or Universal CRT dependency; Vista is the minimum indicated by its imports. Wine installation, plugin probing, and consent-decline behavior passed. The user confirmed Discord QR login and DM/server send and receive on Vista SP2. Reconnection and other Discord features remain untested. The Discord plugin cannot run on XP.

## Tests performed

| Check | Result |
| --- | --- |
| Windows build and NSIS installer | Passed. `make -f Makefile.mingw installer_offline` path invokes the Amethyst package script. |
| Installer execution | Passed in a new Wine prefix. Silent install and update completed; Start Menu entries and Amethyst uninstall registry values were created. Silent uninstall removed the application and preserved the Amethyst profile. |
| Branding metadata | Passed. Installer reports Product Name `Amethyst Messenger`, Publisher `Project Crystal`, and version `2.11.0`. Launcher reports `amethyst.exe`, `Amethyst Messenger`, and the same version. |
| Launcher startup | Passed in Wine. `amethyst.exe --version` reports `Amethyst Messenger 2.11.0 (libpurple 2.11.0)`. |
| GTK application startup | Passed in Wine with `--debug --nologin`. The GTK2 interface initialized and remained running through the 16-second smoke window. The process was stopped by the timeout. |
| MSN implementation | Passed in Wine using a no-credential protocol probe. The installed `prpl-msn-pecan` implementation loaded and returned account-picker name `MSN`. |
| Telegram plugin and messaging | User confirmed Telegram DM, group chat, and topic send/receive on a Vista SP2 test machine. DM/topic history and pagination were also confirmed. |
| Discord plugin build | Passed from checked-in, SHA-256-pinned JSON-GLib 0.14.2 and libqrencode 4.1.1 source archives. `USE_QRCODE_AUTH` is enabled; QRencode and OpenSSL crypto are statically linked. |
| Discord plugin and icon loading | Passed Wine package/startup probe with JSON-GLib runtime and 16, 22, and 48 px protocol icons included. No plugin load error was logged. |
| Discord consent dialog | Passed in Wine using a temporary account with no credentials. The first-connect warning appeared; choosing its default decline action disabled that account (`auto-login=0`). The user's successful connection and messaging also confirms the continue path. |
| Discord login and messaging | User confirmed QR login and DM and server send/receive on a Vista SP2 test machine. Reconnection and other Discord features remain untested. |
| Plugin selection | Passed. The installer contains `plugins/libmsn.dll` from msn-pecan and omits `pidgin.exe` and the upstream native MSN DLL. Existing protocol plugins are retained. |
| Dependencies | Passed static recursive PE inspection for x86 architecture, API-set imports, and Universal CRT imports. Existing GTK2, NSS, and support DLLs were retained. |
| Windows Vista SP2 (32-bit app on x86 or through WOW64) | User confirmed Telegram DM/group/topic and Discord QR login plus DM/server send/receive. MSN sign-in and buddy addition were previously tested with the integrated Pecan implementation; full CrossTalk messaging remains unverified. |
| Windows XP SP3 and XP Professional x64 SP2 (32-bit app; x64 through WOW64) | Static assessment only; neither edition has been runtime-tested. The installer and launcher contain no OS-version gate. |
| Live CrossTalk authentication and messaging | No CrossTalk credentials were available in this build environment. The user had previously tested sign-in and buddy addition on Vista using the integrated Pecan implementation; bidirectional CrossTalk messaging and other features remain unverified here. |

Wine reported that the optional Perl plugin could not load without Perl 5.20 and emitted a GtkSpell/Enchant setup warning. These components do not prevent Amethyst or MSN from starting. The official Pidgin runtime did not bundle the Perl runtime.

## Platform matrix

| Operating system | Status |
| --- | --- |
| Windows XP SP3 x86 and XP Professional x64 SP2 | Same x86 app; x64 edition uses WOW64. Static assessment only; runtime untested. |
| Windows Vista SP2 | 32-bit app runs natively on x86 and through WOW64 on x64. User confirmed Telegram DM/group/topic and Discord QR login plus DM/server send/receive. |
| Wine | Installer, version resource, UI startup, and MSN protocol label checked |

Telegram and Discord are unavailable on XP. Vista runtime messaging has been confirmed. The same x86 package applies across 32-bit and 64-bit Vista; 64-bit Windows runs it through WOW64. XP x64 is likewise intended to run the x86 package through WOW64, with runtime compatibility still untested. Wine checks cover installer and plugin behavior, not Windows OS compatibility.
