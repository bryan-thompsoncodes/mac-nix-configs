# Host configuration: a6mbp (Work MacBook Pro)
#
# Features: fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
# Host-specific: Work tools (AWS, Docker, DDEV, Slack, Zoom, etc.)
{ inputs, ... }:
{
  flake.modules.darwin.a6mbp = { pkgs, config, ... }: {
    imports = with inputs.self.modules.darwin; [
      fonts
      nix-settings
      zsh
      homebrew
      editors
      git
      cli-tools
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

    # === Host-specific System Packages ===

    environment.systemPackages = with pkgs; [
      # Cloud & DevOps
      awscli2
      docker-compose
    ];

    # === Host-specific Homebrew Configuration ===

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
        "docker-desktop"
        "notion"
        "rectangle-pro"
        "slack"
        "zoom"
      ];
    };
  };
}
