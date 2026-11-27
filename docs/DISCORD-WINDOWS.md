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

The Discord plugin is built as 32-bit Windows code with Vista API and PE
subsystem targets. It imports Vista's SRW-lock API, so it does not load on
Windows XP. It should run on Vista SP2 x86 and under WOW64 on 64-bit Vista, but
those OS combinations have not been runtime-tested in this build environment.
Wine installation, startup, plugin probing, and the first-connect consent
dialog were checked. In a temporary account profile, choosing the default
decline action changed Discord's `auto-login` setting from enabled to disabled;
no credentials were configured in that test. The Vista SP2 tester has
confirmed QR login and Discord send and receive in DMs and servers. Other
server and presence features, and reconnection have not been checked. Vista
runtime testing was on the user's machine; the OS architecture was not
recorded here.

Build the plugin and its JSON-GLib runtime from the checked-in source inputs:

```sh
packaging/windows/build-discord-plugin.sh
```

The script requires the historical GTK2 and GLib SDKs, MinGW-w64 i686 Win32
toolchain, and the existing Amethyst OpenSSL and zlib prefixes. It verifies
the SHA-256 checksums for JSON-GLib 0.14.2 and libqrencode 4.1.1 source
archives, then builds those dependencies locally. It writes `libdiscord.dll`
and `libjson-glib-1.0-0.dll` under `output/discord-plugin/`. The OpenSSL crypto
backend is statically linked for Discord's QR authentication only; Pidgin's
existing TLS backend is unchanged.

Set `AMETHYST_DISCORD_DLL` and `AMETHYST_JSON_GLIB_DLL` to those outputs when
building the full installer. The plugin and dependency licenses and source
archives are staged into its `Licenses` directory.
