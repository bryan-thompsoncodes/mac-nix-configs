# Host configuration: gnarbox (NixOS Desktop)
#
# Features: fonts, nix-settings, zsh, editors, git, cli-tools
# Desktop: gnome, gaming, audio
# Host-specific: Boot, networking, users, power management, etc.
{ inputs, ... }:
{
  flake.modules.nixos.gnarbox = { 
    outputs, 
    config, 
    pkgs, 
    lib, 
    meta, 
    ... 
  }: {
    imports = (with inputs.self.modules.nixos; [
      # Base features
      fonts
      nix-settings
      zsh
      editors
      git
      cli-tools
      # Desktop features
      gnome
      gaming
      audio
    ]) ++ [
      # Hardware configuration (keep original path reference)
      ../../hosts/hardware-configs/gnarbox.nix
    ];

    # === Enable nix-ld ===
    # For running dynamically linked executables (needed for bunx, npm binaries, etc.)
    programs.nix-ld.enable = true;

    # === Nixpkgs Configuration ===

    nixpkgs = {
      # Add overlays from flake exports
      overlays = [
        outputs.overlays.unstable
      ];
      # Platform
      hostPlatform = "x86_64-linux";
    };

    # === Boot Configuration ===

    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      # Use LTS kernel (6.6) - linuxPackages_latest (6.18) breaks xpad-noone driver
      kernelPackages = pkgs.linuxPackages_6_6;
      # LUKS device configuration
      initrd.luks.devices."luks-5b933bbd-d285-4b20-8b90-0d18947e77f6".device = 
        "/dev/disk/by-uuid/5b933bbd-d285-4b20-8b90-0d18947e77f6";
      # Hibernation support - configure resume device for power button hibernation
      resumeDevice = "/dev/disk/by-uuid/84deb268-57ba-4cfe-ab1a-85a971db89ce";
    };

    # === Networking ===

    networking = {
      hostName = meta.hostname;
      networkmanager.enable = true;
    };

    # === Localization ===

    time.timeZone = "America/Los_Angeles";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
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
    };

    # === User Configuration ===

    users.users.bryan = {
      isNormalUser = true;
      description = "Bryan";
      extraGroups = [ "networkmanager" "wheel" ];
      shell = pkgs.zsh;
    };

    # === Security ===

    security.sudo.wheelNeedsPassword = false;

    # === Programs ===

    programs = {
      firefox.enable = true;
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-gnome3;
      };
    };

    # === Services ===

    services = {
      printing.enable = true;
      # Disable upower - not needed on desktop without batteries
      upower.enable = lib.mkForce false;
      # DualShock controller touchpad disable
      udev.extraRules = ''
        # DualShock 4 touchpad (USB)
        SUBSYSTEM=="input", ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
        # DualShock 4 touchpad (Bluetooth)
        SUBSYSTEM=="input", ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
        # DualSense touchpad (USB)
        SUBSYSTEM=="input", ATTRS{name}=="Sony Interactive Entertainment DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
        # DualSense touchpad (Bluetooth)
        SUBSYSTEM=="input", ATTRS{name}=="DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
      '';
      # Power management - prevent auto-sleep for Steam streaming
      logind = {
        settings.Login = {
          HandlePowerKey = "hibernate";
          HandleSuspendKey = "ignore";
          HandleLidSwitch = "ignore";
          IdleAction = "ignore";
          IdleActionSec = 0;
        };
      };
    };

    # === Host-specific System Packages ===

    environment.systemPackages = with pkgs; [
      # Zsh plugins (NixOS needs these as packages)
      zsh-powerlevel10k
      zsh-autosuggestions
      zsh-syntax-highlighting

      # Development tools
      redis
      libpq
      gnupg
      pinentry-gnome3

      # Media
      vlc

      # Communication
      discord

      # GUI applications
      obsidian

      # Unstable packages
      unstable.claude-code

      # AI coding assistants
      opencode
      goose-cli

      # GNOME extensions
      gnomeExtensions.hide-top-bar

      # Host-specific packages
      yaak
    ];

    # === System State ===

    system.stateVersion = "25.05";
  };
}
