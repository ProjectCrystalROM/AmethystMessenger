# Windows runtime source references

The Amethyst source repository contains the Pidgin 2.11.0 code and the integrated msn-pecan sources. The installer reuses the official Pidgin 2.11.0 Windows runtime for its GTK2 bundle, NSS backend, optional modules, and unchanged protocol plugins. The installer’s retained GPL notices are in `COPYING`, `COPYRIGHT`, and `Licenses/`.

## GTK runtime bundle

The exact upstream GTK runtime source package for bundle version 2.16.6.3 is available from the [Pidgin SourceForge archive](https://sourceforge.net/projects/pidgin/files/GTK%2B%20for%20Windows/2.16.6.3/gtk-runtime-2.16.6.3-src.zip/download). It includes source and build recipes for ATK 1.32.0-2, Cairo 1.8.10-1, Expat 2.1.0-1, Fontconfig 2.8.0-2, Freetype 2.4.10-1, gettext 0.18.1.1-2, GLib 2.28.8-1, GTK+ 2.16.6-2, libpng 1.4.12-1, Pango 1.29.4-1daa, and zlib 1.2.8_daa1. The authoritative versions, source URLs, source hashes, and local patches are listed in [`generate_gtk_zip.sh`](../pidgin/win32/nsis/generate_gtk_zip.sh).

## Other runtime dependencies

- libxml2 2.9.2 source is included inside the historical Windows SDK archive named in `packaging/windows/inputs.sha256` under `src/libxml2-2.9.2.tar.gz`.
- GtkSpell 2.0.16 source and build files are in the corresponding historical Windows SDK input named in `packaging/windows/inputs.sha256`.
- NSS 3.24 and NSPR 4.12 sources are available from the [Mozilla NSS archive](https://archive.mozilla.org/pub/security/nss/releases/NSS_3_24_RTM/src/) and [Mozilla NSPR archive](https://archive.mozilla.org/pub/nspr/releases/v4.12/src/).
- Source for Pidgin’s in-tree protocol plugins and helper modules is present in this repository. The dependency revisions used for the official Windows package are identified in Pidgin’s historical Windows build files and `ChangeLog.win32`.

The GTK source archive is a separate 54.7 MB upstream download and is not stored in Git history. For redistribution of a Windows installer, retain this exact source archive together with its upstream notices and the matching Amethyst source revision. Keep the SHA-256 checksums of acquired source archives with the release. If a source archive or a required source offer for any redistributable component is missing, do not describe that binary package as source-complete.
