{ ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "node"  # Includes npm and npx for MCP extensions
      "pandoc" # For converting documents
      "texlive" # For converting MD to PDF (maybe smaller options out there?)
    ];
    # Additional casks for this host
    casks = [
      "bambu-studio"
      "discord"
      "monal"
      "rectangle-pro"
      "steam"
      "zen"
    ];
  };
}
