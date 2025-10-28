{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Build Tools
    cmake
    pkg-config
    autoconf
    automake
    libtool
    gnumake
  ];
}
