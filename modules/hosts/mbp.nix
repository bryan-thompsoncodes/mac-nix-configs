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

    # === Activation Scripts ===

    system.activationScripts.extraActivation.text = ''
      # Run as the primary user for user-specific setup
      su - ${config.system.primaryUser} -c '
        # --- Alacritty platform config ---
        ALACRITTY_DIR="$HOME/.config/alacritty"
        ALACRITTY_TOML="$ALACRITTY_DIR/alacritty.toml"
        if [ -d "$ALACRITTY_DIR" ] && [ ! -L "$ALACRITTY_TOML" ]; then
          echo "Setting up Alacritty config symlink..."
          ln -sf alacritty-macos.toml "$ALACRITTY_TOML"
          echo "  Linked alacritty.toml -> alacritty-macos.toml"
        fi

        # --- oh-my-opencode plugin ---
        if ! grep -q "oh-my-opencode" ~/.config/opencode/opencode.json 2>/dev/null; then
          echo "Installing oh-my-opencode plugin..."
          ${pkgs.bun}/bin/bunx oh-my-opencode install --no-tui --claude=yes --chatgpt=no --gemini=no || true
          echo "oh-my-opencode installed!"
          echo "Next steps:"
          echo "  1. Authenticate with providers: opencode auth login"
          echo "  2. Start OpenCode: opencode"
        fi
      '
    '';

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
