{ ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional casks for this host
    casks = [
      "bambu-studio"
      "steam"
    ];
  };
}
