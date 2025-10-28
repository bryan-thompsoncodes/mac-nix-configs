{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Network Tools
    curl
    wget
    socat
    autossh
  ];
}
