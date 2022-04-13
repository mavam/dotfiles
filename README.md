**Proper dotfiles are the very heart of an efficient working environment.**

- **Terminals**: [Kitty](https://sw.kovidgoyal.net/kitty/) and
             [tmux](https://github.com/tmux/tmux)
- **Shell**: [Fish](https://fishshell.com/)
- **Editor**: [NeoVim](https://neovim.io/)
- **Font**: [Meslo](https://github.com/andreberg/Meslo-Font) from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
- **Colorscheme**: [Kanagawa](https://github.com/rebelot/kanagawa.nvim)

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

Alternatively, install only dotfiles selectively, with positional arguments
matching names in this repository:

    ./dots install git gnupg

Similarly, remove all installed dotfiles:

    ./dots uninstall -a

The installer script does not override existing dotfiles unless the command
line includes the `-f` switch. When in doubt what the installation of a subset
of the dotfiles would look like, it is possible to look at the diff first:

    ./dots diff -a

To add a configuration for an exemplary tool "foo", create a new directory
`foo` and add the dotfiles in there, as if `foo` is your install prefix
(typically `$HOME`). You can "scope" a tool as *local* by adding a tag-file
`foo/LOCAL`. This has the effect of creating a nested configuration directory
in your prefix, instead of symlinking the directory. For example, you may not
want to symlink `~/.gnupg` but only the contained file `~/.gnupg/gpg.conf`.
Without the scope tag `gnupg/LOCAL`, you would end up with:


    ~/.gnupg -> dotfiles/gpg/.gnupg

as opposed to:

    ~/.gnupg (local directory)
    ~/.gnupg/gpg.conf -> dotfiles/gpg/.gnupg/gpg.conf

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
