# Amethyst Messenger

### Keeping forgotten conversations alive.

*A Project Crystal initiative.*

Amethyst Messenger is an independently maintained multiprotocol instant messaging client derived from Pidgin 2.11.0. The project preserves the classic desktop messaging experience on historical operating systems and restores access to networks left behind by their original operators.

The Windows build integrates msn-pecan as the MSN protocol implementation and configures it for CrossTalk. MSN appears as **MSN** in account setup. The Windows installer also includes the tdlib-purple Telegram plugin; its Vista minimum and login status are documented below. The project values historical compatibility, lightweight software, user choice, and preservation.

Amethyst Messenger is independent and is not affiliated with the original Pidgin developers, Microsoft, the msn-pecan developers, or the CrossTalk operators. Its source preserves upstream copyright notices and licensing terms.

## Compatibility

| Platform | Status |
| --- | --- |
| Windows Vista SP2 x86 and x64 (32-bit app through WOW64) | Previously tested with the integrated MSN client for sign-in and adding a buddy. The Amethyst rebranded package still needs a fresh installation test. |
| Windows XP SP3 x86 | Build targets the Windows XP API and PE subsystem. Static assessment only; runtime test pending. |
| Windows XP Professional x64 SP2 (WOW64) | 32-bit build is intended to run. Static assessment only; runtime test pending. |
| Windows Vista SP2 x64 (WOW64) | 32-bit build is intended to run. Static assessment only; runtime test pending. |
| Wine | Used for packaging and startup smoke tests; this does not establish Windows compatibility. |

The application and existing bundled protocols retain the XP SP3 x86 target. The Telegram plugin requires Windows Vista or later; it imports Vista APIs and will not load on XP.

The Windows application uses the original Pidgin-era GTK2 runtime and 32-bit MinGW build. Amethyst keeps the libpurple library, plugin ABI, and protocol IDs. Other bundled protocols remain available, subject to their network operators and services still operating. Retired services may be unavailable independently of the client.

## Install and connect to MSN

Install the Windows package from the project’s [Releases](https://github.com/ProjectCrystalROM/AmethystMessenger/releases). Open **Accounts → Manage Accounts**, add an account, select **MSN**, enter the CrossTalk account name and password, and enable the account. CrossTalk-specific endpoints are included in the MSN plugin.

The application stores its Windows profile under `%APPDATA%\Amethyst Messenger` and its Unix profile under `~/.amethyst`. A separate profile prevents Amethyst from overwriting a Pidgin profile. To migrate data, first back up both profiles, then selectively copy supported account, buddy list, and preference files. Existing native MSN protocol accounts use a different protocol ID from msn-pecan, so create a new MSN account in Amethyst and enter its CrossTalk credentials. Do not copy third-party plugins into the new profile without checking their compatibility.

## Build

See [Windows build instructions](docs/BUILD-WINDOWS.md) for the pinned historical SDKs, compiler setup, reproducible installer command, and [compatibility report](docs/COMPATIBILITY.md). The standard MinGW `installer` and `installer_offline` targets produce the integrated Amethyst package. The build accepts a separate directory of locally acquired, checksum-verified SDK archives and writes packages to `output/`.

For Unix GTK2 builds, use the upstream Pidgin 2.11.0 Autotools build process. The executable is named `amethyst`; libpurple retains its original library and ABI names.

## MSN implementation and limits

The integrated msn-pecan protocol is packaged as `plugins/libmsn.dll` with protocol ID `prpl-msn-pecan` and display name MSN. The retired native Pidgin MSN protocol DLL is excluded. CrossTalk supports historical MSN client behaviors; this project preserves the supplied msn-pecan implementation and its endpoint configuration. Contact synchronization, presence, switching conversations, and messaging should be verified with a live account and contacts. No stronger functionality claim is made from build or startup tests alone.

## Telegram

The Windows installer includes [tdlib-purple](https://github.com/UnitedMarsupials/tdlib-purple), registered as **Telegram (tdlib)**. Forum supergroups appear as Pidgin contact groups, with each visible topic as a chat room beneath its group. Topic text sends reach Telegram, but topic messages currently fail to display in the client; this is under investigation. Only the initial 50-message topic history is loaded; older-topic-history paging and topic-specific attachment sending are not implemented yet. Wine startup testing confirms libpurple loads the plugin, and Vista account authentication and regular chat messaging have been tested. See [Telegram on Windows](docs/TELEGRAM-WINDOWS.md) for account setup, API credential overrides, feature limits, and the Vista requirement.

## Source, attribution, and contributions

This source derives from the Pidgin 2.11.0 release and includes msn-pecan for CrossTalk connectivity and tdlib-purple for Telegram. Retain the upstream notices. Amethyst Messenger is distributed under the GNU GPL as described by `COPYING`; see [licensing notes](docs/LICENSING.md) and the [third-party source list](docs/THIRD-PARTY-SOURCES.md) for bundled component details. Reproducible Windows build inputs and checksums are documented in [BUILD-WINDOWS.md](docs/BUILD-WINDOWS.md).

Contributions should focus on preservation, tested compatibility, and small changes with clear user benefit. Include target OS, build command, and test evidence with compatibility changes. See [CONTRIBUTING.md](CONTRIBUTING.md).

- Source: [ProjectCrystalROM/AmethystMessenger](https://github.com/ProjectCrystalROM/AmethystMessenger)
- Project Crystal: [GitHub organization](https://github.com/ProjectCrystalROM)
- Upstream Pidgin: [pidgin.im](https://pidgin.im/)
- CrossTalk: [crosstalk.im](https://crosstalk.im/)
