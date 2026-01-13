# Dotfiles Repository

Personal configuration files managed via symlinks. Each top-level directory = one tool, mirroring `$HOME` paths (e.g., `neovim/.config/nvim` → `~/.config/nvim`).

## Commands

- `./dots install [tool…]` — symlink tools to `$HOME` (all if none specified)
- `./dots install --force` — overwrite existing files
- `./dots diff [tool…]` — preview changes before applying
- `./dots remove [tool…]` — unlink managed symlinks
- `./dots list` — show install status
- `./dots doctor` — check environment health

## Code Style

- **Shell scripts**: Bash 3.2+, `set -euo pipefail`, 2-space indent
- **Filenames**: lowercase, use dots/hyphens (`init.fish`, `starship.toml`)

## Testing Changes

1. Preview: `./dots diff <tool>`
2. Dry run: `./dots install <tool> --prefix /tmp/dots`
3. Shell lint: `shellcheck <script>`
4. Neovim health: `nvim --headless "+checkhealth" +qall`

## Commits

- Imperative present tense, under 72 chars: `Add fish abbreviations for git`
- Group changes by tool

## Structure

- Use `tool.config.yaml` for symlink manifests and directory creation
- Use per-tool `.gitignore` files (not root `.gitignore`)
- NEVER commit secrets, tokens, or SSH keys—use `.example` templates
