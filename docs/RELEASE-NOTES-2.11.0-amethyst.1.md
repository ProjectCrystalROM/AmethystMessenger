# Amethyst Messenger 2.11.0-amethyst.1

Initial Project Crystal source release, derived from Pidgin 2.11.0. The Windows package integrates msn-pecan as the MSN account protocol and directs it to CrossTalk. The application has its own name, icon, Windows metadata, profile location, installer identity, and Project Crystal help links while retaining libpurple ABI and the GTK2 interface.

The 32-bit Windows build targets the XP API and PE subsystem. Vista SP2 MSN sign-in and buddy addition were previously observed with the integrated plugin; the Amethyst installer package still requires target-machine installation and account retesting. XP and XP x64 remain statically assessed. Consult the compatibility table in the README.

Presence across contacts, switchboard conversations, bidirectional messaging, file transfers, and reconnect behavior require more live CrossTalk accounts and contacts to validate. Third-party Windows binary source archives must accompany any redistributable installer package before the package can be described as source-complete. This release is therefore marked prerelease while those checks are completed.
