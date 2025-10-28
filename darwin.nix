{ pkgs, ... }:

{
  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

  # System packages (minimal for now)
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

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
    };

    # Taps for additional formulae
    taps = [
      "ddev/ddev"
    ];

    brews = [
      # DDEV local development environment
      "ddev/ddev/ddev"
    ];

    casks = [
      # GUI applications can be added here as needed
      # Add session-manager-plugin as cask if needed
    ];
  };
}
