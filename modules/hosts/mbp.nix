# Host configuration: mbp (Personal MacBook Pro)
#
# Features: fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
# Host-specific: Personal apps (Bambu Studio, Discord, Steam, etc.)
{ inputs, ... }:
{
  flake.modules.darwin.mbp = { pkgs, config, ... }: {
    imports = with inputs.self.modules.darwin; [
      fonts
      nix-settings
      zsh
      homebrew
      editors
      git
      cli-tools
      activation
    ];

    # === Core System Settings ===

    # Set primary user for homebrew and other user-specific options
    system.primaryUser = "bryan";

    # Platform
    nixpkgs.hostPlatform = "aarch64-darwin";

    # System state version
    system.stateVersion = 4;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Add Homebrew to system PATH
    environment.systemPath = [ "/opt/homebrew/bin" ];

    # === Host-specific Homebrew Configuration ===

    homebrew = {
      # Additional brews
      brews = [
        "node"     # Includes npm and npx for MCP extensions
        "pandoc"   # For converting documents
        "texlive"  # For converting MD to PDF
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
  };
}
