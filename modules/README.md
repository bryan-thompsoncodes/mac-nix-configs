# Dendritic Modules Structure

This directory implements a **dendritic (tree-like) module organization** pattern for the nix-configs repository. Instead of organizing code by host (mbp, a6mbp, gnarbox), we organize by **feature/capability**, with each module defining both darwin and nixos aspects.

## Directory Organization

### `base/`
Core system configuration shared across all hosts:
- Fonts and font configuration
- Nix settings and core system options
- Shell configuration (zsh, environment variables)
- System-wide defaults

### `dev/`
Development tools and environments:
- Editor configurations (vim, neovim, emacs)
- Git configuration and tools
- CLI utilities and development tools
- Language-specific tooling

### `services/`
System services and background processes:
- Ollama (local LLM inference)
- Open-WebUI (web interface for Ollama)
- Monitoring and observability tools
- SMB mount configuration
- Other daemon services

### `desktop/`
Desktop environment and GUI applications:
- GNOME desktop configuration
- Gaming setup (Steam, Proton, game-specific configs)
- GUI applications and preferences
- Display and window manager settings

### `hosts/`
Host-specific configurations:
- `mbp/` - Personal MacBook Pro
- `a6mbp/` - Work MacBook Pro
- `studio/` - Studio workstation
- `gnarbox/` - NixOS desktop

Each host module imports and composes the feature modules above.

### `dev-envs/`
Development environment definitions for VA projects:
- `vets-website/` - Node 14.15.0, Yarn 1.x, Cypress
- `vets-api/` - Ruby 3.3.6, PostgreSQL, Redis, Kafka
- `next-build/` - Node 24, Yarn 3.x, Playwright
- `component-library/` - Node 22, Yarn 4.x, Puppeteer

## Architecture Pattern

This follows the **flake-parts + import-tree** organization:

1. **Feature modules** (base, dev, services, desktop) define reusable configurations
2. **Host modules** (hosts/) compose features for specific machines
3. **Development environments** (dev-envs/) provide isolated project shells

Each module is self-contained and can be:
- Imported by multiple hosts
- Extended or overridden per-host
- Tested independently
- Documented with clear purposes

## Migration Status

This structure is being migrated from the original flat organization:
- Task 1: ✓ Cursor cleanup and build verification
- Task 2: In progress - Flake inputs reorganization
- Task 3: ✓ Create dendritic directory structure (this file)
- Tasks 4-10: Feature module migration (pending)

See `.sisyphus/plans/dendritic-migration.md` for detailed task tracking.
