{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Data Processing
    jq
    yq
  ];
}
