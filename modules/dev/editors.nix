# Development module: Editor configuration
# Provides vim and neovim for both darwin and nixos systems
# NixOS additionally includes sublime text
{ inputs, ... }:
{
  flake.modules.darwin.editors = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      vim
      neovim
    ];
  };

  flake.modules.nixos.editors = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      vim
      neovim
      sublime
    ];
  };
}
