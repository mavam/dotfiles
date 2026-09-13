{ ... }:

{
  programs.starship = {
    enable = true;
    # The shared Fish configuration initializes Starship exactly once.
    enableFishIntegration = false;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };

  xdg.configFile."starship.toml".source = ../../starship/starship.toml;
}
