This directory is based on UnitedMarsupials/tdlib-purple commit
`0fb0ae4634dd72a34f71d9fadfef5c148eed1637` (2026-11-26), licensed under GPL-2.0-or-later.

The local Windows/GLib compatibility changes are limited to `client-utils.cpp`,
`clipboard.cpp`, `format.h`, `log-history.cpp`, `receiving.cpp`, `td-client.cpp`,
and `thumbnail.cpp`. They replace APIs unavailable in GTK 2.14.7 / GLib 2.28.8
and guard one Purple message flag added after libpurple 2.11. See Amethyst's
Git history for the individual source diff.
