{ pkgs, ... }:

{
  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

  # Add MesloLGS Nerd Font
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim

    # Version control
    git
    gh  # GitHub CLI

    # Terminal
    alacritty

    # CLI utilities - modern replacements
    ripgrep  # better grep
    fd       # better find

    # CLI utilities - general
    wget
    tree
    htop

    # Nix development
    nix-direnv  # Fast, persistent Nix shell caching for direnv

    # JavaScript toolchain
    bun
  ];

  # Add Homebrew to system PATH
  environment.systemPath = [ "/opt/homebrew/bin" ];

  # Zsh configuration
  programs.zsh.enable = true;

  # System state version
  system.stateVersion = 4;

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set primary user for homebrew and other user-specific options
  system.primaryUser = "bryan";

  # Homebrew integration (declarative management)
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
      "eza"
      "fzf"
      "direnv"
      "redis"
      "libpq"
      "gnupg"
      "ca-certificates"
      "stow"
      "tmux"
      "ncurses"
      "pinentry-mac"
      "opencode"
    ];

    # Common Homebrew casks
    casks = [
      "claude"
      "codex"
      "cursor"
      "cursor-cli"
      "obsidian"
    ];
  };
}
