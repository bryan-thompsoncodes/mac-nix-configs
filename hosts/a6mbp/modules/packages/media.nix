{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Media
    imagemagick
    ffmpeg

    # PDF (xpdf removed due to security vulnerabilities)
    poppler  # Includes utilities
  ];
}
