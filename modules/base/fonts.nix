# Base module: Font configuration
# Provides MesloLGS Nerd Font for both darwin and nixos systems
{ inputs, ... }:
{
  flake.modules.darwin.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      nerd-fonts.meslo-lg
    ];
  };
  
  flake.modules.nixos.fonts = { pkgs, ... }: {
    fonts.packages = with pkgs; [
      nerd-fonts.meslo-lg
    ];
  };
}
