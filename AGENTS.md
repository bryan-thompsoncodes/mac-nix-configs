# Agent Guidelines for nix-configs

## Build/Lint/Test Commands

### Nix Configuration
- **Build system:** `darwin-rebuild switch --flake '.#hostname'` (macOS) or `sudo nixos-rebuild switch --flake '.#hostname'` (NixOS)
- **Update dependencies:** `nix flake update`
- **Check flake:** `nix flake check`
- **Format code:** `nixpkgs-fmt .`

### Development Environments
Activate with: `nix develop '.#project-name'` (provides environments for vets-website, vets-api, next-build, component-library)

## Code Style Guidelines

### Nix Code
- **Formatting:** Use `nixpkgs-fmt` for consistent formatting
- **Naming:** Use camelCase for variables, PascalCase for modules
- **Imports:** Group imports by type (pkgs, lib, local modules)
- **Error handling:** Use `throw` for fatal errors, `abort` for user errors
- **Comments:** Use `#` for single-line comments, document complex logic
- **Structure:** Keep flake.nix clean, use separate .nix files for complex configurations