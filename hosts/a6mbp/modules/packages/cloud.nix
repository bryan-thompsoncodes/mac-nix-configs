{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud & DevOps
    awscli2
    docker-compose
  ];
}
