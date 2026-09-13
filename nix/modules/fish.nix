{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    shellInit = builtins.readFile ../../fish/config.fish;
    plugins = map (name: {
      inherit name;
      src = pkgs.fishPlugins.${name}.src;
    }) [ "fzf-fish" "puffer" "autopair" "bass" ];
  };

  home.packages = with pkgs; [ fd fzf ];

}
