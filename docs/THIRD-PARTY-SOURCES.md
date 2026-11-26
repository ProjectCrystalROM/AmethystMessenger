# Windows runtime source references

The Amethyst source repository contains the Pidgin 2.11.0 code and the integrated msn-pecan sources. The installer reuses the official Pidgin 2.11.0 Windows runtime for its GTK2 bundle, NSS backend, optional modules, and unchanged protocol plugins. The installer’s retained GPL notices are in `COPYING`, `COPYRIGHT`, and `Licenses/`.

## GTK runtime bundle

The exact upstream GTK runtime source package for bundle version 2.16.6.3 is available from the [Pidgin SourceForge archive](https://sourceforge.net/projects/pidgin/files/GTK%2B%20for%20Windows/2.16.6.3/gtk-runtime-2.16.6.3-src.zip/download). It includes source and build recipes for ATK 1.32.0-2, Cairo 1.8.10-1, Expat 2.1.0-1, Fontconfig 2.8.0-2, Freetype 2.4.10-1, gettext 0.18.1.1-2, GLib 2.28.8-1, GTK+ 2.16.6-2, libpng 1.4.12-1, Pango 1.29.4-1daa, and zlib 1.2.8_daa1. The authoritative versions, source URLs, source hashes, and local patches are listed in [`generate_gtk_zip.sh`](../pidgin/win32/nsis/generate_gtk_zip.sh).

## Other runtime dependencies

The [official Pidgin Windows build guide](https://www.pidgin.im/development/building/2.x.y/windows/) lists the historical source archives for the Windows runtime dependencies and their extraction instructions. Relevant versions for the 2.11.0-era build include:

- libxml2 2.9.2 (`libxml2-2.9.2_daa1.tar.gz`).
- GtkSpell 2.0.16 (`gtkspell-2.0.16.tar.bz2`) and Enchant 1.6.0.
- NSS 3.24 and NSPR 4.12 (`nss-3.24-nspr-4.12.tar.gz`).
- SILC Toolkit 1.1.12, Meanwhile 1.0.2, and Cyrus SASL 2.1.26.
- MinGW GCC 4.7.2 runtime sources for libssp, as described in the Pidgin build guide.
- Pidgin's 2013 Windows installation dependencies bundle, which contains the crash reporting runtime.

The build inputs include the libxml2 SDK archive and GtkSpell archive used for this build. The official Pidgin source tree contains the in-tree protocol plugins and their source. For reproducibility, use the exact historical versions and patches documented by those recipes rather than substituting current releases.

The GTK source archive is a separate 54.7 MB upstream download and is not stored in Git history. The source archive is signed by the upstream Pidgin Windows maintainer and has a matching `.asc` file in the same SourceForge directory. For redistribution of a Windows installer, retain this exact source archive and signature, the Amethyst source revision, and the exact source archives or valid source offers for the other bundled runtime libraries. Keep the SHA-256 checksums with the release. If a required source archive or source offer is missing, do not describe the binary package as source-complete.
