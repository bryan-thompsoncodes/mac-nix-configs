# Host configuration: studio (Media Server Mac)
#
# Features: fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
# Services: ollama, open-webui, monitoring, smb-mount
# Host-specific: Media server tools (cloudflared, ffmpeg, etc.)
{ inputs, ... }:
{
  flake.modules.darwin.studio = { pkgs, config, ... }: {
    imports = with inputs.self.modules.darwin; [
      # Base features
      fonts
      nix-settings
      zsh
      homebrew
      editors
      git
      cli-tools
      # Service modules
      ollama
      open-webui
      monitoring
      smb-mount
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

    # === oh-my-opencode Plugin Activation ===

    system.activationScripts.extraActivation.text = ''
      # Run as the primary user to install oh-my-opencode plugin
      echo "Checking oh-my-opencode installation..."
      su - ${config.system.primaryUser} -c '
        if ! grep -q "oh-my-opencode" ~/.config/opencode/opencode.json 2>/dev/null; then
          echo "Installing oh-my-opencode plugin..."
          # Install with all AI providers enabled
          # Adjust flags: claude=yes (team), chatgpt=yes (team), gemini=no (free account)
          ${pkgs.bun}/bin/bunx oh-my-opencode install --no-tui --claude=yes --chatgpt=yes --gemini=no || true
          echo "oh-my-opencode installed!"
          echo "Next steps:"
          echo "  1. Authenticate with providers: opencode auth login"
          echo "  2. Start OpenCode: opencode"
        else
          echo "oh-my-opencode already installed"
        fi
      '
    '';

    # === Enable Services ===

    services.ollama.enable = true;
    services.open-webui.enable = true;
    services.monitoring.enable = true;
    services.smb-mount.enable = true;

    # === Host-specific Homebrew Configuration ===

    homebrew = {
      brews = [
        "cloudflared"
        "node"         # Includes npm and npx for MCP extensions
        "ollama"
        "prometheus"
        "grafana"
        "python@3.11"  # For Open WebUI
      ];
      casks = [
        "zen"
      ];
    };
  };
}
