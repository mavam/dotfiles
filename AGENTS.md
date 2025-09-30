# Repository Guidelines

## Project Structure & Module Organization
Top-level directories map 1:1 to tools; each mirrors the eventual location under the user’s home (e.g., `neovim/.config/nvim`, `git/.gitconfig`). Scripts like `bootstrap` and the Bash-based `dots` orchestrate installs. Keep ancillary assets (themes, keymaps, fonts) inside the tool that consumes them, and document complex setups with a short `README` next to the files.

## Build, Test, and Development Commands
- `./dots install [tool…]`: link selected tools into `$HOME` (no args installs everything); add `--force` to replace conflicts.
- `./dots diff [tool…]`: preview what would change; combine with `--prefix /tmp/dots` for safe dry runs.
- `./dots remove [tool…]`: drop the managed symlinks while leaving user-created files intact.
- `./dots list` / `./dots doctor`: inspect install status and environment details at a glance.

## Coding Style & Naming Conventions
Shell automation now targets Bash (3.2+), using `set -euo pipefail`, two-space indentation, and minimal external dependencies. Keep filenames lowercase with dots or hyphens (`init.fish`, `starship.toml`), and mirror upstream paths so the manifest logic stays simple. When touching language-specific configs, run native formatters (`fish_indent`, `stylua`, `vale`) before committing.

## Testing Guidelines
Run `./dots diff <tool>` to confirm the planner produces the expected actions, then execute `./dots install <tool> --prefix /tmp/dots` to validate symlink layout without touching your real home. Use `--force` when you need to refresh existing symlinks after manifest changes. For shell changes, lint with `shellcheck`, and for NeoVim updates, execute `nvim --headless "+checkhealth" +qall`. If you edit the Homebrew bundle, verify with `brew bundle --file=homebrew/.Brewfile --no-lock`.

## Commit & Pull Request Guidelines
Use imperative, present-tense commit messages under 72 characters (e.g., `Add Ghostty themes`). Group related changes per tool and mention affected manifests. Pull requests should spell out motivation, tested commands, and any platform notes; include screenshots when UI-facing configs (Ghostty, Kitty, Zed) change.

## Security & Secrets
Never commit personal tokens, SSH keys, or machine-specific secrets. When sensitive paths need to stay local, rely on `tool.config.yaml` to describe exactly which files get linked and which directories must exist (see `gpg/tool.config.yaml`). Prefer environment variables or `.example` templates for values that teammates must populate themselves.
