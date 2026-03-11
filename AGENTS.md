# Dotfiles Repository

Personal configuration files managed via symlinks. Each top-level directory is
a "tool" (e.g., `git/`, `fish/`, `pi/`). The `dots` utility symlinks their
contents into `$HOME`.

## Golden Rule

This repo is the source of truth. Never edit config files under `$HOME`
directly—always edit here and let `dots` create the symlinks.

## How `dots` Works

```
./dots install [tool…]        # symlink (all tools if none given)
./dots install --force        # overwrite existing files
./dots diff [tool…]           # preview what would change
./dots remove [tool…]         # unlink managed symlinks
./dots list                   # show install status
./dots doctor                 # check environment health
```

## Tool Layout

Every tool directory has a `tool.config.yaml` that tells `dots` where files go.
There are two mapping styles:

### `root` — whole-directory link

The entire tool directory maps to one target. New files are picked up
automatically.

```yaml
# fish/tool.config.yaml
root:
  target: "~/.config/fish"
  mode: link
```

### `entries` — explicit file mappings

Each file is mapped individually. New files must be wired by adding an entry.

```yaml
# pi/tool.config.yaml
entries:
  - source: "agent/settings.json"
    target: "~/.pi/agent/settings.json"
  - source: "agent/models.json"
    target: "~/.pi/agent/models.json"
```

### Optional sections

- `directories` — pre-create paths (with optional permissions)
- `post_install` — shell commands to run after linking

## Changing Configuration

1. **Find the tool directory** for the application (e.g., `pi/` for the pi
   coding agent, `git/` for git, `fish/` for the fish shell).
2. **Edit or create the file** inside that directory.
3. **If the tool uses `entries`**, add a mapping to `tool.config.yaml` for any
   new file. Tools with a `root` mapping need no manifest change.
4. **Run `./dots install <tool>`** to activate the symlink.

## Conventions

- **Shell scripts**: Bash 3.2+, `set -euo pipefail`, 2-space indent.
- **Filenames**: lowercase with dots or hyphens (`init.fish`, `starship.toml`).
- **Commits**: imperative present tense, under 72 chars, grouped by tool.
  Example: `Add fish abbreviations for git`
- **Secrets**: never commit tokens, keys, or passwords. Use `.example`
  templates.
- **Ignores**: use per-tool `.gitignore` files, not a root-level one.
