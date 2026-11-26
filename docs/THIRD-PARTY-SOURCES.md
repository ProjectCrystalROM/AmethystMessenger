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

The GTK source archive is 54.7 MB and is not stored in Git history. The original archive and its detached signature were downloaded and checked: GPG reports a good signature from Daniel Atallah's key (`3CE143D8B8E86B319C3BBFA986723FEEDE890574`). The key identity was not independently certified by this build host. The archive SHA-256 is `b45b21bde6e7961682d246d1a68f9f3dce2340fdc9d9497ec316e40a680634dd`.

The release's `amethyst-2.11.0-third-party-sources.tar.gz` includes the GTK archive and signature plus the exact source packages collected for libxml2, GtkSpell, Enchant, NSS/NSPR, SILC, Meanwhile, and Cyrus SASL. Their hashes are recorded in the package's `SHA256SUMS`. The source repository itself contains Pidgin, msn-pecan, and in-tree plugin sources. The compiler's bundled `libssp-0.dll` and the `exchndl.dll` crash helper still need their corresponding source archive or a maintained source offer to make the third-party source set exhaustive; see the official [Windows build guide](https://www.pidgin.im/development/building/2.x.y/windows/) for their historical provenance. Do not describe the installer as fully source-complete until those remaining sources are included or offered.

When redistributing the installer, provide the Amethyst source revision and the third-party source package alongside it, retain all component license notices, and keep the archive hashes with the release. The Windows installer is a prerelease while the remaining source and target-machine runtime checks are outstanding.
