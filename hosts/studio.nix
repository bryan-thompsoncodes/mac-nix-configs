{ pkgs, ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "cloudflared"
      "node"  # Includes npm and npx for MCP extensions
      "ollama"
    ];
    # Additional casks for this host
    casks = [
      "zen"
    ];
  };
}
