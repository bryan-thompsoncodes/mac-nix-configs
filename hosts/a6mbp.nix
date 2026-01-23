{ pkgs, ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  environment.systemPackages = with pkgs; [
    # Cloud & DevOps
    awscli2
    docker-compose
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional taps for this host
    taps = [
      "ddev/ddev"
    ];

    # Additional brews for this host
    brews = [
      # DDEV for va.gov-cms development
      "ddev/ddev/ddev"
    ];

    # Additional casks for this host
    casks = [
      "claude-code"
      "cursor"
      "notion"
      "rectangle-pro"
      "slack"
      "zoom"
    ];
  };
}
