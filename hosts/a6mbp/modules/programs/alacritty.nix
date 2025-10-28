{ config, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;

    settings = {
      # Window settings
      window = {
        dimensions = {
          columns = 120;
          lines = 40;
        };
        padding = {
          x = 10;
          y = 10;
        };
        decorations = "full";
        opacity = 0.95;
      };

      # Font configuration
      font = {
        size = 14.0;
        normal = {
          family = "MesloLGS NF";  # Required for p10k
          style = "Regular";
        };
      };

      # Colors (Dracula-inspired theme)
      colors = {
        primary = {
          background = "#1e1e1e";
          foreground = "#d4d4d4";
        };
      };

      # Shell
      shell = {
        program = "${pkgs.zsh}/bin/zsh";
        args = [ "--login" ];
      };
    };
  };
}
