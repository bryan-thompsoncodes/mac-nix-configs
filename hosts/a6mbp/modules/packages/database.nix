{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Database & Services
    postgresql_16
    redis
    memcached
    sqlite
  ];
}
