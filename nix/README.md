# Home Manager

- `modules/` configures individual tools using native files from this repository.
- `profiles/minimal.nix` combines Fish and Starship.
  - Fish plugins come from the consumer's pinned nixpkgs, not Fisher.
  - Fish initializes Starship; Home Manager's extra shell integrations are disabled.
  - Git guard helpers and other development tooling are not included yet.
  - Universal variables, history, credentials, and other runtime state remain unmanaged.
- Consumers pin this repository as a flake input with `flake = false` and import
  `${dotfiles}/nix/profiles/minimal.nix` from their Home Manager configuration.
- Keep usernames, home directories, `home.stateVersion`, authorized SSH keys,
  signing identities, and secret provisioning in the consuming infrastructure.
  - Never include plaintext secrets in Nix source files or build inputs.
- Do not run `dots install fish starship` on a home managed by this profile.
  - Existing conflicting files or symlinks must be backed up and removed before activation.
- Publish module changes before updating a consumer's dotfiles lock entry.
  - For local tests, use a temporary source containing only the required configuration
    files and modules, with `--override-input dotfiles path:/absolute/source`
    and `--no-write-lock-file`.
  - Do not use the entire working checkout as a path input: ignored files and local
    state can be copied into the Nix store.
