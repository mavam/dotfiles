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

The Bash utility [dots](dots) links configuration content from this repository
into your prefix (default: `$HOME`), treating each top-level directory as a
"tool" whose contents mirror the layout you want under `$HOME`. Add files to a
tool directory and, with a `root` mapping, they will be picked up automatically.

Install everything:

```sh
./dots install
```

Install a subset (your shell expands globs before the script runs):

```sh
./dots install git gpg "neovim*"
```

Preview the plan without touching the filesystem:

```sh
./dots diff git
```

Remove previously linked files:

```sh
./dots remove git
```

Inspect overall status or the current environment:

```sh
./dots list
./dots doctor
```

The script is careful about existing files unless you pass `--force`. Use the
`--prefix DIR` flag to dry-run installs into an alternate location.

To add a new tool, create a directory (e.g., `foo/`) and drop your config files
inside. When you need custom targets or directory preparation, add a
`foo/tool.config.yaml` manifest:

```yaml
root:
  target: "~/.config/fish"
directories:
  - path: "~/.gnupg"
    permissions: "700"
```

`root` mirrors the tool directory under the given target so new files are picked up automatically, and the optional `directories` entries let you pre-create sensitive paths with the right permissions.
