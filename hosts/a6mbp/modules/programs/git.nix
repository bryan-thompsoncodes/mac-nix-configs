{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    signing = {
      key = "9175041E4A046A5E";
      signByDefault = true;
    };
    settings = {
      user = {
        name = "Bryan Thompson";
        email = "18094023+bryan-thompsoncodes@users.noreply.github.com";
      };
    };

    # Global git ignore patterns (applies to all repos on this machine)
    ignores = [
      ".envrc"
      ".direnv/"
    ];
  };
}
