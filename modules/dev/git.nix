# Development module: Git configuration
# Provides git, GitHub CLI, delta, and lazygit for both darwin and nixos
# Darwin: git/gh via nix, delta/lazygit via Homebrew
# NixOS: all packages via nixpkgs
{ inputs, ... }:
{
  # Darwin aspect - git/gh via nix, delta/lazygit via Homebrew
  flake.modules.darwin.git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh # GitHub CLI
    ];
    homebrew.brews = [
      "delta"
      "lazygit"
    ];
  };

  # NixOS aspect - all packages via nixpkgs
  flake.modules.nixos.git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh # GitHub CLI
      delta
      lazygit
    ];
  };
}
