# Licensing and bundled components

Amethyst Messenger is derived from Pidgin 2.11.0. The source tree retains the upstream `COPYING`, `COPYRIGHT`, `AUTHORS`, and file-level notices. Pidgin and libpurple are licensed under the GNU GPL version 2 or, at the recipient's option, any later version, as specified in `COPYING`.

The Windows package includes msn-pecan source integrated under `libpurple/protocols/msn/`, its retained copyright notices, `COPYING`, and its bundled libmspack `COPYING.LIB`. The package also reuses the official Pidgin 2.11.0 Windows runtime for GTK2 and existing dependencies and protocol plugins. Their names and licenses are retained in the distribution where available. The source tree and build scripts do not replace those upstream component terms.

Windows dependencies include GTK+/GLib and related components, GTKSpell/Enchant, libxml2, NSS/NSPR, SQLite, and other upstream Pidgin runtime modules. Consult the corresponding upstream license and source distributions for each exact runtime version. The historical Pidgin Windows packaging recipes and pinned inputs are documented in `pidgin/win32/` and `docs/BUILD-WINDOWS.md`. Exact GTK and other runtime source locations are listed in [THIRD-PARTY-SOURCES.md](THIRD-PARTY-SOURCES.md).

Before publishing a Windows binary, provide corresponding source or a valid source offer for every component whose license requires it, including the exact versions and patches used. The Amethyst source and reproducible scripts alone do not replace that obligation for bundled third-party binaries. The initial source publication documents the remaining third-party source archive collection; a binary release must link or attach those archives and notices before being represented as fully source-complete.

Artwork in `artwork/` and the application icon derivatives are original placeholder assets prepared for Amethyst Messenger. They are intended to be replaceable. The Windows package also retains original Pidgin notices and identifies this derivative project. Amethyst Messenger is not endorsed by Pidgin developers, Microsoft, msn-pecan developers, or CrossTalk operators.
