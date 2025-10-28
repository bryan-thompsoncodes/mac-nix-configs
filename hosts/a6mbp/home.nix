{ config, pkgs, ... }:

{
  # Import all program modules
  imports = [
    # Programs
    ./modules/programs/git.nix
    ./modules/programs/alacritty.nix
    ./modules/programs/zsh.nix
    ./modules/programs/direnv.nix
    ./modules/programs/fzf.nix
    ./modules/programs/bat.nix
    ./modules/programs/eza.nix
    ./modules/programs/tmux.nix
    ./modules/programs/neovim.nix
    ./modules/programs/ssh.nix

    # Packages
    ./modules/packages/shell.nix
    ./modules/packages/development.nix
    ./modules/packages/database.nix
    ./modules/packages/cloud.nix
    ./modules/packages/network.nix
    ./modules/packages/data.nix
    ./modules/packages/build-tools.nix
    ./modules/packages/geospatial.nix
    ./modules/packages/scientific.nix
    ./modules/packages/media.nix
    ./modules/packages/utilities.nix
  ];

  # Home Manager state version
  home.stateVersion = "24.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Force overwrite existing config files
  xdg.configFile."alacritty/alacritty.toml".force = true;

  # Preserve your p10k configuration
  # Uncomment after backing up your .p10k.zsh
  # home.file.".p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink "/Users/bryan/.p10k.zsh.backup";
}
