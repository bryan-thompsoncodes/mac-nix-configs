{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Nerd Fonts for p10k (new package structure)
    nerd-fonts.meslo-lg

    # Shell & Terminal
    tree-sitter
  ];
}
