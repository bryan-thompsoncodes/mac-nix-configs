# Development module: Git configuration
# Provides git and GitHub CLI for both darwin and nixos systems
{ inputs, ... }:
let
  # Shared package list for both platforms
  gitPackages = pkgs: with pkgs; [
    git
    gh  # GitHub CLI
  ];
in
{
  flake.modules.darwin.git = { pkgs, ... }: {
    environment.systemPackages = gitPackages pkgs;
  };

  flake.modules.nixos.git = { pkgs, ... }: {
    environment.systemPackages = gitPackages pkgs;
  };
}
