{
  description = "Shared Home Manager modules for personal environments";

  outputs = { self }: {
    homeManagerModules = {
      default = self.homeManagerModules.minimal;
      minimal = ./nix/profiles/minimal.nix;
      fish = ./nix/modules/fish.nix;
    };
  };
}
