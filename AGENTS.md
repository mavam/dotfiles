# Dotfiles Repository

Personal configuration files managed via symlinks. Each top-level directory is
one "tool" whose contents mirror `$HOME` paths (e.g., `neovim/.config/nvim` →
`~/.config/nvim`).

## Commands

- `./dots install [tool…]` — symlink tools to `$HOME` (all if none specified)
- `./dots install --force` — overwrite existing files
- `./dots diff [tool…]` — preview changes before applying
- `./dots remove [tool…]` — unlink managed symlinks
- `./dots list` — show install status
- `./dots doctor` — check environment health

## Changing Tool Configuration

The source of truth for all config lives in this repo, never in `$HOME`
directly. When modifying configuration for any tool:

1. **Edit files inside the tool directory** (e.g., `pi/agent/settings.json`),
   not the symlink target under `$HOME`.
2. **Wire new files in `tool.config.yaml`** if the tool uses explicit `entries`
   mappings. Add a new entry with `source` and `target`. If the tool uses a
   `root` mapping, new files are picked up automatically.
3. **Run `./dots install <tool>`** to create or update symlinks.

### pi (coding agent)

pi configuration lives in `pi/agent/` and symlinks to `~/.pi/agent/`. The tool
uses explicit `entries` in `pi/tool.config.yaml` (no `root` mapping), so every
new file must be wired manually.

Current files:

| File | Purpose |
|------|---------|
| `agent/settings.json` | General settings |
| `agent/models.json` | Model/provider configuration |
| `agent/keybindings.json` | Custom keybindings |

To change pi configuration (settings, keybindings, models):

1. Edit the file in `pi/agent/` in this repo.
2. If adding a new file, add an entry to `pi/tool.config.yaml`.
3. Run `./dots install pi` to symlink.

Do **not** edit `~/.pi/agent/` files directly or modify pi's source code for
personal configuration. Refer to the
[keybindings docs](https://github.com/nicholasgasior/pi-coding-agent/blob/main/docs/keybindings.md)
for available actions and key format.

## Code Style

- **Shell scripts**: Bash 3.2+, `set -euo pipefail`, 2-space indent
- **Filenames**: lowercase, use dots/hyphens (`init.fish`, `starship.toml`)

## Commits

- Imperative present tense, under 72 chars: `Add fish abbreviations for git`
- Group changes by tool

## Structure

- Use `tool.config.yaml` for symlink manifests, directory creation, and
  post-install hooks
- Use per-tool `.gitignore` files (not root `.gitignore`)
- NEVER commit secrets, tokens, or SSH keys—use `.example` templates

## tool.config.yaml

Supports these sections:

- `root`: target path, mode (`link`/`merge`), permissions
- `entries`: individual file mappings with source/target/mode
- `directories`: directories to create
- `post_install`: list of shell commands to run after linking
