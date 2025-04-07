# dotfiles

> Proper dotfiles are the very heart of an efficient working environment.

- **Terminals**: [GhostTTY](https://ghostty.org/)
- **Shell**: [Fish](https://fishshell.com/)
- **Editor**: [NeoVim](https://neovim.io/)
- **Colorscheme**: GitHub Light & Dark
- **Font**: [Fira Code](https://github.com/tonsky/FiraCode)
  from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

On macOS, [Homebrew](https://brew.sh) is the package manager.

## Usage

### Synopsis

Clone this repository and optionally bootstrap your system:

```sh
git clone git@github.com:mavam/dotfiles.git ~/.dotfiles
cd .dotfiles
./bootstrap
```

The bootstrap script will ask you whether you'd like to setup specific components.

### Dotfile Management

The POSIX shell script [dots](dots) installs (= symlinks) and removes subsets
of dotfiles according to your needs. For example, install all dotfiles as
follows:

```sh
./dots install -a
```

Alternatively, install only dotfiles selectively, with positional arguments
matching directory names in this repository:

```sh
./dots install git gnupg
```

Similarly, remove all installed dotfiles:

```sh
./dots uninstall -a
```

The installer script does not override existing dotfiles unless the command
line includes the `-f` switch. When in doubt what the installation of a subset
of the dotfiles would look like, it is possible to look at the diff first:

```sh
./dots diff -a
```

To add a configuration for an exemplary tool "foo", create a new directory
`foo` and add the dotfiles in there, as if `foo` is your install prefix
(typically `$HOME`). You can "scope" a tool as *local* by adding a tag-file
`foo/LOCAL`. This has the effect of creating a nested configuration directory
in your prefix, instead of symlinking the directory. For example, you may not
want to symlink `~/.gnupg` but only the contained file `~/.gnupg/gpg.conf`.
Without the scope tag `gnupg/LOCAL`, you would end up with:

```sh
~/.gnupg -> dotfiles/gpg/.gnupg
```

as opposed to:

```txt
~/.gnupg (local directory)
~/.gnupg/gpg.conf -> dotfiles/gpg/.gnupg/gpg.conf
```
