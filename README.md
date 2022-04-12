<p align="center">
  <img width="600" alt="zsh" src="https://user-images.githubusercontent.com/53797/46028848-ee273b80-c0f1-11e8-9e32-a750cd84692b.png">
</p>

Proper dotfiles are the very heart of an efficient working environment.

- Terminals:
  - [Kitty](https://sw.kovidgoyal.net/kitty/)
  - [tmux](https://github.com/tmux/tmux)
- Shell: [Fish](https://fishshell.com/)
- Editor: [NeoVim](https://neovim.io/)
- Font: [Meslo](https://github.com/andreberg/Meslo-Font) from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

On macOS, [Homebrew](https://brew.sh) is the package manager.

## Usage

### Synopsis

These are the quick start instructions to get up and running:

    git clone git@github.com:mavam/dotfiles.git ~/.dotfiles
    cd .dotfiles
    ./bootstrap dotfiles

Next, on a macOS, bootstrap Homebrew:

    ./bootstrap system homebrew

Thereafter, make fish your login shell and install plugins from various tools
with plugin managers.

    ./bootstrap fish neovim tmux

### Dotfile Management

The POSIX shell script [dots](dots) installs (= symlinks) and removes subsets
of dotfiles according to your needs. For example, install all dotfiles as
follows:

    ./dots install -a

Alternatively, install only dotfiles for git and gnupg:

    ./dots install git gnupg

Similarly, remove all installed dotfiles:

    ./dots uninstall -a

The installer script does not override existing dotfiles unless the command
line includes the `-f` switch. When in doubt what the installation of a subset
of the dotfiles would look like, it is possible to look at the diff first:

    ./dots diff -a

### System Bootstrapping

In addition to managing dotfiles, the script [bootstrap](bootstrap) facilitates
getting up and running on a new machine. Passing `-h` shows the available
aspects available for configuration:

1. `system`: adjust system defaults for productivity
1. `homebrew`:setup Homebrew and install bundled packages
1. `dotfiles`: setup dotfiles via `./dots install -a`
1. `postfix`: setup [postfix](http://www.postfix.org) as GMail relay
1. `tmux`: install tmux plugins
1. `neovim`: install NeoVim plugins
1. `fish`: setup fish as login shell

Invoking

    ./bootstrap

without any arguments sets up all aspects in the above order. On macOS, (1)
includes:

1. Adjust various default settings, e.g.:
   - Improve security and privacy settings
   - Disable boot sound
   - Reduce UI effects for improved speed
   - Make the keyboard faster
2. Perform a software update
3. Install XCode
