# Discord plugin on Windows

The installer includes the `purple-discord` protocol plugin as
`plugins/libdiscord.dll`. The vendored code is based on EionRobb's
`purple-discord` commit `2b85bbfad5e915f60f2c4ca30c1e7d720762c148`; Amethyst's
consent handling and build integration are local changes. Releases have two
Discord builds: the XP flavor uses email/password login (including 2FA) and
omits QR login; the modern flavor retains QR and email/password login.

## Consent and service policy

Before the first connection for each account, Amethyst displays a notice that
Discord does not authorize or support this third-party client integration and
that access may be blocked or the account restricted. **Continue at My Own
Risk** records consent on that account and starts login. **Decline and Disable
Account** disables that account in Amethyst. Declining does not disable other
accounts. If the user later re-enables the declined account, the warning is
shown again. Consent is per account and stored in Amethyst's account
configuration.

Discord's current [Platform Manipulation Policy](https://discord.com/safety/platform-manipulation-policy-explainer)
says client modifications are not allowed. It does not provide official
approval or a guarantee of tolerance for this client. Account use is at the
user's risk. This is an independent third-party plugin and is not endorsed by
Discord.

## Login

Add an account and choose **Discord**. On modern builds, QR login is available
when no saved token or email/password is configured; scan the displayed code
with the Discord mobile app. On XP builds, configure email and password, then
complete the second-factor prompt if the account requires it. Password and 2FA
login succeeded on the user's XP test before this release split; the final
no-QR installer still needs a retest. Do not share QR codes, tokens, or debug
logs that contain authentication data.

## Windows compatibility and validation

The XP Discord plugin is 32-bit, built with XP API macros and PE subsystem
5.1. QR auth is compiled out, so this DLL has no QRencode or OpenSSL crypto
dependency. Static inspection found no Vista-only imports in it or its
JSON-GLib runtime. The modern Discord plugin retains QR auth, OpenSSL crypto,
and QRencode and targets Vista API level/subsystem 6.0. The same x86 XP plugin
is intended to run natively on XP x86 and under WOW64 on XP x64. The user
successfully logged in on XP with password and 2FA using the previous
QR-enabled XP-targeted build; final no-QR package validation remains pending.
Vista SP2 QR login and DM/server messaging were confirmed by the user. Other
server and presence features, and reconnection have not been checked.

Build both flavors and their JSON-GLib runtime from the checked-in source
inputs:

```sh
AMETHYST_DISCORD_FLAVOR=xp packaging/windows/build-discord-plugin.sh
AMETHYST_DISCORD_FLAVOR=modern packaging/windows/build-discord-plugin.sh
```

The scripts require the historical GTK2 and GLib SDKs, MinGW-w64 i686 Win32
toolchain, and zlib prefix. They verify SHA-256 checksums for JSON-GLib 0.14.2
and libqrencode 4.1.1 source archives. Both flavors build JSON-GLib locally;
only modern builds QRencode and links OpenSSL crypto. Outputs are kept separate
under `output/discord-xp/` and `output/discord-modern/`. Pidgin's existing TLS
backend is unchanged. The XP flavor's default build directory is
`.build/discord-xp-win32`; modern uses `.build/discord-modern-win32`.

The complete installer build accepts the matching plugin paths and
`AMETHYST_RELEASE_FLAVOR=xp` or `modern`; see [BUILD-WINDOWS.md](BUILD-WINDOWS.md).
Licenses and the corresponding source archives are included in the installers.
