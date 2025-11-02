{ 
  inputs,
  outputs,
  config,
  pkgs,
  cursor,
  meta,
  ... 
}:

{
  # Import the generated hardware configuration
  imports = [ ./hardware-configs/gnarbox.nix ];
  
  # Nix settings
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.warn-dirty = false;
  };

  # Nixpkgs configuration with overlays
  nixpkgs = {
    # Add overlays from flake exports
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable
      outputs.overlays.modifications
    ];
    # Configure nixpkgs instance
    config = {
      # Allow unfree packages
      allowUnfree = true;
      # Permit insecure packages if needed
      permittedInsecurePackages = [
        "electron-25.9.0"
      ];
    };
    # Platform
    hostPlatform = "x86_64-linux";
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest linux kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # LUKS device configuration
  boot.initrd.luks.devices."luks-5b933bbd-d285-4b20-8b90-0d18947e77f6".device = "/dev/disk/by-uuid/5b933bbd-d285-4b20-8b90-0d18947e77f6";

  # Networking
  networking.hostName = meta.hostname; # Define your hostname in flake
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable graphics for gaming (Steam)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Define user account
  users.users.bryan = {
    isNormalUser = true;
    description = "Bryan";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  # Sudo configuration
  security.sudo.wheelNeedsPassword = false;

  # Install Firefox
  programs.firefox.enable = true;

  # Enable Zsh
  programs.zsh.enable = true;

  # Enable GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Enable gamemode
  programs.gamemode.enable = true;

  # Steam setup
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
    gamescopeSession = {
      enable = true;
    };
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim

    # Version control
    git
    gh  # GitHub CLI

    # Terminals
    alacritty

    # CLI utilities - modern replacements
    ripgrep  # better grep
    fd       # better find

    # CLI utilities - general
    wget
    tree
    htop
    bat
    eza
    fzf
    direnv
    stow
    tmux
    ncurses

    # Zsh plugins
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting

    # Development tools
    redis
    libpq
    gnupg

    # Media
    vlc

    # Communication
    discord

    # GUI applications
    obsidian

    # Unstable packages
    unstable.claude-code
    cursor  # From jetpham's fork: v2.0.38

    # AI coding assistants
    opencode
    goose-cli

    # Host-specific packages
    #bambu-studio
  ];

  # Fonts configuration
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  # System state version
  system.stateVersion = "25.05";
}
