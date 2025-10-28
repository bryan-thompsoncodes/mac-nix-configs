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
darwin-rebuild switch --flake ~/code/mac-nix-configs/hosts/a6mbp
```

Or use the alias:

```bash
rebuild
```

**Note**: The aliases assume the repo is at `~/code/mac-nix-configs`. If you cloned elsewhere, update the paths in `modules/programs/zsh.nix`.

### Update Flake Inputs

```bash
cd ~/code/mac-nix-configs/hosts/a6mbp
nix flake update
darwin-rebuild switch --flake ~/code/mac-nix-configs/hosts/a6mbp
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

- The flake references `../../darwin.nix` for system-level Darwin configuration
- Home Manager is integrated via the `home-manager.darwinModules.home-manager` module
- All user-specific configuration is modularized for easier maintenance
