# Development module: Rust
# Provides Rust toolchain via rustup for both darwin and nixos systems
# Darwin: rustup via Homebrew
# NixOS: rustup via nixpkgs
{ ... }:
{
  # Darwin aspect - rustup via Homebrew
  flake.modules.darwin.rust = { ... }: {
    homebrew.brews = [
      "rustup"
    ];
  };

  # NixOS aspect - rustup via nixpkgs
  flake.modules.nixos.rust = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      rustup
    ];
  };
}
