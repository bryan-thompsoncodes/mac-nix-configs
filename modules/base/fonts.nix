# Base module: Font configuration
# Provides MesloLGS Nerd Font for both darwin and nixos systems
{ inputs, ... }:
let
  # Shared font list for both platforms
  fontPackages = pkgs: with pkgs; [
    nerd-fonts.meslo-lg
  ];
in
{
  flake.modules.darwin.fonts = { pkgs, ... }: {
    fonts.packages = fontPackages pkgs;
  };
  
  flake.modules.nixos.fonts = { pkgs, ... }: {
    fonts.packages = fontPackages pkgs;
  };
}
