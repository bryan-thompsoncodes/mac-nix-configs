{ pkgs, ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "block-goose-cli"
      "cloudflared"
      "docker"
      "docker-compose"
      "node"  # Includes npm and npx for MCP extensions
      "ollama"
    ];
    # Additional casks for this host
    casks = [
      "block-goose"
      "zen"
    ];
  };
}
