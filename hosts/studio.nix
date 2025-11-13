{ pkgs, config, ... }:

{
  imports = [
    ./darwin-common.nix
    ../modules/ai-server.nix
    ../modules/monitoring.nix
    ../modules/smb-mount-media.nix
  ];

  # Host-specific packages
  environment.systemPackages = [
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "cloudflared"
    ];
    # Additional casks for this host
    casks = [
      "zen"
    ];
  };
}
