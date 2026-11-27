# Discord plugin on Windows

The Windows installer includes the `purple-discord` protocol plugin as
`plugins/libdiscord.dll`. The vendored code is based on EionRobb's
`purple-discord` commit `2b85bbfad5e915f60f2c4ca30c1e7d720762c148`; Amethyst's
consent handling and build integration are local changes. QR-code login is
enabled in the Windows build.

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

Add an account and choose **Discord**. QR login is available when no saved token
or email/password is configured. The plugin displays a QR code for scanning
with the Discord mobile app. The plugin also retains its upstream
email/password login path. Do not share QR codes, tokens, or debug logs that
contain authentication data.

## Windows compatibility and validation

The Discord plugin is built as 32-bit Windows code with XP API macros and PE
subsystem version 5.1. Its statically linked OpenSSL 3.0.0 is also built for
XP, selecting OpenSSL's existing `CRITICAL_SECTION` lock backend instead of
Vista's SRW locks. Static inspection found no Vista-only imports in the plugin
or JSON-GLib DLL. The same x86 plugin is intended to run natively on XP x86 and
under WOW64 on XP x64. Wine XP-mode loading and protocol registration are being
checked; actual Windows XP x64 login and messaging still need confirmation.
Vista SP2 login and DM/server messaging were previously confirmed by the user.
Wine installation, startup, plugin probing, and the first-connect consent
dialog were checked. In a temporary account profile, choosing the default
decline action changed Discord's `auto-login` setting from enabled to disabled;
no credentials were configured in that test. The Vista SP2 tester has
confirmed QR login and Discord send and receive in DMs and servers. Other
server and presence features, and reconnection have not been checked.

Build XP-targeted OpenSSL 3.0.0 from the pinned source used by the Telegram
source bundle, then build the plugin and its JSON-GLib runtime from the checked-
in source inputs:

```sh
AMETHYST_OPENSSL_SOURCE_DIR=/path/to/openssl-3.0.0 \
  packaging/windows/build-openssl-xp.sh
packaging/windows/build-discord-plugin.sh
```

The OpenSSL recipe outputs to `../.amethyst-build/windows-extra/openssl-xp-install`
by default. The Discord build uses that prefix and emits an XP-targeted DLL;
`AMETHYST_OPENSSL_PREFIX` can select another XP-targeted prefix. The scripts
require the historical GTK2 and GLib SDKs, MinGW-w64 i686 Win32 toolchain, and
zlib prefix. The OpenSSL build requires the exact 3.0.0 source archive named in
`THIRD-PARTY-SOURCES.md`. It verifies
the SHA-256 checksums for JSON-GLib 0.14.2 and libqrencode 4.1.1 source
archives, then builds those dependencies locally. It writes `libdiscord.dll`
and `libjson-glib-1.0-0.dll` under `output/discord-plugin/`. The OpenSSL crypto
backend is statically linked for Discord's QR authentication only; Pidgin's
existing TLS backend is unchanged.

Set `AMETHYST_DISCORD_DLL` and `AMETHYST_JSON_GLIB_DLL` to those outputs when
building the full installer. The plugin and dependency licenses and source
archives are staged into its `Licenses` directory.
