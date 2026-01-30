# Base module: Homebrew configuration
# Provides Homebrew package management for darwin systems
# Note: Homebrew is darwin-only, no nixos aspect needed
{ inputs, ... }:
{
  flake.modules.darwin.homebrew = { pkgs, ... }: {
    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };

      # Common Homebrew taps
      taps = [
      ];

      # Common Homebrew brews
      brews = [
        # Zsh plugins
        "powerlevel10k"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"

         # CLI tools
         "bat"
         "bind"
         "ca-certificates"
         "delta"
         "direnv"
         "eza"
         "ffmpeg"
         "fzf"
         "gnupg"
         "jq"
         "just"
         "lazydocker"
         "lazygit"
         "libpq"
         "marksman"
         "ncurses"
         "opencode"
         "pinentry-mac"
         "redis"
         "shellcheck"
         "stow"
         "tlrc"
         "tmux"
         "zoxide"
      ];

      # Common Homebrew casks
      casks = [
        "claude"
        "obsidian"
        "opencode-desktop"
        "sol"
        "sublime-text"
        "yaak"
      ];
    };
  };
}
