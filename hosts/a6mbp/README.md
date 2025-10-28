# a6mbp Host Configuration

This directory contains the complete Nix configuration for the a6mbp (Apple Silicon MacBook Pro) host.

## Structure

```
a6mbp/
├── flake.nix           # Main flake configuration for this host
├── flake.lock          # Lock file for reproducible builds
├── home.nix            # Home Manager entry point with module imports
└── modules/
    ├── programs/       # Individual program configurations
    │   ├── git.nix
    │   ├── alacritty.nix
    │   ├── zsh.nix
    │   └── ...
    └── packages/       # Categorized package lists
        ├── development.nix
        ├── database.nix
        ├── utilities.nix
        └── ...
```

## Usage

### Rebuild System

From anywhere:

```bash
darwin-rebuild switch --flake ~/code/mac-nix-configs#a6mbp
```

Or use the alias:

```bash
rebuild
```

**Note**: The configuration is managed from the root `flake.nix`, not a per-host flake. The `#a6mbp` specifies which host configuration to use and doesn't need to match your system hostname.

### Update Flake Inputs

```bash
cd ~/code/mac-nix-configs
nix flake update
darwin-rebuild switch --flake ~/code/mac-nix-configs#a6mbp
```

Or use the alias:

```bash
update
```

## Adding New Programs

1. Create a new file in `modules/programs/` (e.g., `modules/programs/myprogram.nix`)
2. Add the program configuration
3. Import it in `home.nix`

## Adding New Packages

1. Add packages to the appropriate category file in `modules/packages/`
2. Or create a new category file if needed and import it in `home.nix`

## Notes

- This host is configured in the root `flake.nix` as `darwinConfigurations.a6mbp`
- The configuration name (`a6mbp`) is independent of the system hostname
- The root flake references `../../darwin.nix` for system-level Darwin configuration
- Home Manager is integrated via the `home-manager.darwinModules.home-manager` module
- All user-specific configuration is modularized for easier maintenance
- Single `flake.lock` at the root ensures consistent package versions across all hosts
