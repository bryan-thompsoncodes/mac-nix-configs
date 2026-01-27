{ inputs, ... }:
{
  flake.modules.nixos.gaming = { pkgs, lib, ... }: {
    # Enable graphics for gaming (Steam)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Enable gamemode
    programs.gamemode.enable = true;

    # Steam setup
    programs.steam = {
      enable = true;
      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
      gamescopeSession = {
        enable = true;
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };
}
