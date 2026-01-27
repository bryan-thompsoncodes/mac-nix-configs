# Base module: Nix daemon and configuration
# Darwin: Disables nix-darwin's Nix management (using Determinate Nix)
# NixOS: Configures Nix package, experimental features, and settings
{ inputs, ... }:
{
  flake.modules.darwin.nix-settings = { pkgs, ... }: {
    # Disable nix-darwin's Nix management (using Determinate Nix)
    nix.enable = false;
  };
  
  flake.modules.nixos.nix-settings = { pkgs, ... }: {
    nix = {
      package = pkgs.nixVersions.stable;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      settings = {
        warn-dirty = false;
        download-buffer-size = "1073741824"; # 1GB buffer
      };
    };
  };
}
