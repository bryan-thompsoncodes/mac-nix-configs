{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Bryan Thompson";
        email = "18094023+bryan-thompsoncodes@users.noreply.github.com";
      };
    };
  };
}
