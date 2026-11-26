# Pidgin 2.11.0 for CrossTalk

This fork builds CrossTalk Pecan as Pidgin's in-tree MSN protocol.
Select **CrossTalk (MSNP)** in the account dialog. The protocol ID is
`prpl-msn-pecan`, the same as the standalone CrossTalk plugin.
The Windows and Unix build products are named `libmsn.dll` and `libmsn.so`.

Pecan is vendored from [CrossTalk's repository](https://git.ugnet.xyz/CrossTalk/msn-pecan)
at commit `b5132e75b879c0e90e881f1403bc4057ead3ae68`.
The integration uses Pidgin's ordinary MSN protocol and install targets.
Pecan's C source is unchanged. The Unix build needs GIO 2.22 or later
when the MSN protocol is selected.

## Windows build

Use [Pidgin's Windows build instructions](https://developer.pidgin.im/wiki/BuildingWinPidgin.html)
and add the [GLib 2.28.8 Win32 development archive](https://ftp.gnome.org/pub/gnome/binaries/win32/glib/2.28/glib-dev_2.28.8-1_win32.zip)
to the SDK directory. Unpack it under `win32-dev/glib-2.28.8`, or set
`GLIB_TOP` in `local.mak`. The runtime GLib shipped in the official
2.11.0 offline installer is also 2.28.8.

The root `make -f Makefile.mingw install` includes this protocol in
`win32-install-dir/plugins/libmsn.dll`. The existing installer target
takes its payload from that staging directory. The certificate target
stages the official Let's Encrypt ISRG Root X1 for CrossTalk HTTPS
verification with Pidgin's bundled NSS.

When updating a standalone Pecan installation, keep only one copy of
the CrossTalk protocol DLL in the plugin search paths. The in-tree
DLL uses the same protocol ID, so existing Pecan account settings
can be reused.
