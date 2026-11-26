# msn-pecan
This is a fork of the MSN Messenger plugin for libpurple that has been modified to connect to CrossTalk's servers.

## Dependencies
In order to compile, you will need to first install the development headers for libpurple as well as the tools required to build:
- Debian-based (Ubuntu, Mint etc): `sudo apt install libpurple-dev build-essential`
- RedHat-based (CentOS, Fedora etc): `sudo dnf install libpurple-devel make automake gcc gcc-g++`
- openSUSE: `sudo zypper install libpurple-devel devel_basis`

### Arch-based distributions (CachyOS, Manjaro etc)
> [!WARNING]
> As of writing, it appears Pidgin being moved from the official repositories to the AUR created a regression that causes msn-pecan to segfault.
>
> Until a fix is found, Arch users are recommended to either run the official MSN Messenger clients via [Wine](https://wiki.archlinux.org/title/Wine) or use other third-party clients (such as [meowsn](https://github.com/campos02/meowsn)).

Pidgin (and its libpurple library) are no longer packaged in Arch's official repos due to their dependence on GTK2, so you need to install it from the AUR.
The easiest way of doing so is by first installing an AUR *helper*, such as [yay](https://github.com/jguer/yay).

Once done, you can run the following: `yay -S libpurple base-devel`

## Compiling
To compile msn-pecan, follow the steps below:
1. Clone this repository: `git clone https://git.ugnet.xyz/CrossTalk/msn-pecan && cd msn-pecan`
2. Compile and install: `make && sudo make install`

## Usage
If installed properly, it should show up when creating a new account. You can then enter your username and password and press "Add" to add the account.