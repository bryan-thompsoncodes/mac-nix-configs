{ ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "block-goose-cli"
      "node"  # Includes npm and npx for MCP extensions
    ];
    # Additional casks for this host
    casks = [
      "bambu-studio"
      "block-goose"
      "discord"
      "steam"
      "zen"
    ];
  };
}
