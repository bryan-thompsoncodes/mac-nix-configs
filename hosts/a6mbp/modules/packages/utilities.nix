{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Utilities
    tree
    stow
    tldr
    coreutils
    gnupg
    mkcert
    prettier
    ripgrep
    fd
    htop
    watch
    unzip
    zip
    ttyper
    opencode
  ];
}
