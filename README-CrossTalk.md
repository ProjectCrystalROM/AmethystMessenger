# CrossTalk MSN integration

Amethyst Messenger integrates the CrossTalk msn-pecan implementation in the Pidgin 2.11.0 source tree. It is built into the ordinary Windows and Unix protocol plugin targets and is displayed as **MSN**. Its protocol ID remains `prpl-msn-pecan`, so account data from the standalone CrossTalk plugin uses the same ID. Native Pidgin MSN is excluded from the Windows package.

The source is vendored at `libpurple/protocols/msn/`; its upstream origin and commit are recorded in the integration history. Existing CrossTalk endpoint configuration and CA trust support are retained.

For the complete Windows package build, see [docs/BUILD-WINDOWS.md](docs/BUILD-WINDOWS.md). The default project identity, profile locations, and compatibility status are in [README.md](README.md).
