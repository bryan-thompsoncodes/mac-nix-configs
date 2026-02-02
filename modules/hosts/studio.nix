# Host configuration: studio (Media Server Mac)
#
# Features: fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
# Services: ollama, open-webui, monitoring, smb-mount, syncthing, icloud-backup
# Host-specific: Media server tools (cloudflared, ffmpeg, etc.)
{ inputs, ... }:
{
  flake.modules.darwin.studio = { ... }: {
    imports = with inputs.self.modules.darwin; [
      # Base features
      fonts
      nix-settings
      zsh
      homebrew
      editors
      git
      cli-tools
      activation
      # Service modules
      ollama
      open-webui
      monitoring
      smb-mount
      syncthing
      icloud-backup
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

    # === Enable Services ===

    services.ollama.enable = true;
    services.open-webui.enable = true;
    services.monitoring.enable = true;
    services.smb-mount.enable = true;
    services.syncthing.enable = true;
    services.icloud-backup.enable = true;

    # === Host-specific Homebrew Configuration ===

    homebrew = {
      brews = [
        "cloudflared"
        "node"         # Includes npm and npx for MCP extensions
        "ollama"
        "prometheus"
        "grafana"
        "python@3.11"  # For Open WebUI
        "syncthing"
      ];
      casks = [
        "zen"
      ];
    };
  };
}
