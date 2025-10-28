# macOS Nix Configuration

A declarative, reproducible macOS system configuration using Nix, nix-darwin, and Home Manager.

## Overview

This repository contains a complete macOS system configuration managed with:

- **[Nix](https://nixos.org/)**: Declarative package management
- **[nix-darwin](https://github.com/LnL7/nix-darwin)**: macOS system configuration
- **[Home Manager](https://github.com/nix-community/home-manager)**: User environment management
- **[Homebrew](https://brew.sh/)**: macOS-specific packages (managed declaratively)

The configuration is designed for Apple Silicon (aarch64) Macs and provides a fully reproducible development environment.

## Features

### 🎯 Development Tools

- **Version Control**: Git, GitHub CLI
- **Languages**: Python 3.12, Java 11
- **Editors**: Neovim (with custom configs), configured with vi/vim aliases
- **Terminal**: Alacritty with Dracula-inspired theme
- **Shell**: Zsh with Powerlevel10k theme, auto-suggestions, syntax highlighting, and extensive aliases

### ☁️ Cloud & DevOps

- AWS CLI v2
- Docker Compose
- DDEV (via Homebrew)

### 🗄️ Databases & Services

- PostgreSQL 16
- Redis
- Memcached
- SQLite

### 🛠️ CLI Utilities

- **Modern replacements**: `eza` (ls), `bat` (cat), `ripgrep` (grep), `fd` (find)
- **Productivity**: fzf, tmux, direnv
- **Network**: curl, wget, socat, autossh
- **Development**: tree, tldr, coreutils, gnupg, mkcert, prettier
- **System**: htop, watch, unzip, zip

### 🎨 Shell Experience

- **Powerlevel10k** theme with Nerd Fonts
- **Auto-suggestions** and **syntax highlighting**
- **Git integration** with extensive custom aliases
- **Enhanced completions** with case-insensitive matching and colored output

## Repository Structure

```
.
├── flake.nix              # Main flake configuration
├── flake.lock             # Lock file for reproducible builds
├── darwin.nix             # System-level macOS configuration
└── hosts/
    └── a6mbp/             # Host-specific configuration
        ├── flake.nix      # Host flake (references root darwin.nix)
        ├── home.nix       # Home Manager entry point
        └── modules/
            ├── programs/  # Individual program configurations
            │   ├── alacritty.nix
            │   ├── bat.nix
            │   ├── direnv.nix
            │   ├── eza.nix
            │   ├── fzf.nix
            │   ├── git.nix
            │   ├── neovim.nix
            │   ├── ssh.nix
            │   ├── tmux.nix
            │   └── zsh.nix
            └── packages/  # Categorized package lists
                ├── build-tools.nix
                ├── cloud.nix
                ├── data.nix
                ├── database.nix
                ├── development.nix
                ├── geospatial.nix
                ├── media.nix
                ├── network.nix
                ├── scientific.nix
                ├── shell.nix
                └── utilities.nix
```

## Prerequisites

1. **Nix Package Manager**: Install the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer):

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **nix-darwin**: Follow the [nix-darwin installation guide](https://github.com/LnL7/nix-darwin#readme)

3. **Homebrew**: Install from [brew.sh](https://brew.sh)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   Note: nix-darwin will manage Homebrew packages declaratively, but Homebrew itself must be installed first.

## Installation

### Initial Setup

1. **Clone this repository**:

   ```bash
   git clone https://github.com/yourusername/mac-nix-configs.git ~/code/mac-nix-configs
   cd ~/code/mac-nix-configs
   ```

2. **Review and customize** the configuration:

   - Update `hosts/a6mbp/modules/programs/git.nix` with your Git user info
   - If you cloned to a different location, update the `rebuild` and `update` aliases in `hosts/a6mbp/modules/programs/zsh.nix`
   - Customize other aliases in `hosts/a6mbp/modules/programs/zsh.nix` to your preferences
   - Review package lists in `hosts/a6mbp/modules/packages/` and remove what you don't need

3. **Build and activate the configuration**:

   ```bash
   darwin-rebuild switch --flake .#a6mbp
   ```

   The `#a6mbp` specifies which host configuration to use from the flake.

### Post-Installation

1. **Configure Powerlevel10k** (if needed):

   ```bash
   p10k configure
   ```

   Configuration is stored in `~/.local/share/p10k/p10k.zsh`.

2. **Restart your terminal** or reload the shell:

   ```bash
   exec zsh
   ```

## Usage

### Applying Changes

After modifying any configuration files:

```bash
rebuild
```

Or explicitly:

```bash
darwin-rebuild switch --flake ~/code/mac-nix-configs#a6mbp
```

### Updating Dependencies

Update all flake inputs to their latest versions:

```bash
update
```

Or manually:

```bash
cd ~/code/mac-nix-configs
nix flake update
darwin-rebuild switch --flake .#a6mbp
```

### Useful Aliases

The configuration includes many convenient aliases:

**Navigation**:

```bash
..      # cd ..
...     # cd ../..
....    # cd ../../..
```

**Git**:

```bash
ga      # git add
gd      # git diff
gs      # git status
gst     # git status (alias)
gp      # git push
gpl     # git pull
gl      # git log --oneline --graph
gco     # git checkout
gcob    # git checkout -b
gaa     # git add --all
gcm     # git commit -m
gbd     # git branch -d
gbD     # git branch -D
gpF     # git push --force
grb     # interactive rebase (default: last 3 commits)
```

**Modern Tools**:

```bash
ls      # eza --icons
ll      # eza -lah --icons
la      # eza -a --icons
lla     # eza -la
lsa     # eza -lah
lt      # eza --tree --icons
cat     # bat (with syntax highlighting)
```

**Development**:

```bash
vim     # nvim
vi      # nvim
```

## Customization

### Adding New Programs

1. Create a new file in `hosts/a6mbp/modules/programs/`:

   ```nix
   # hosts/a6mbp/modules/programs/myprogram.nix
   { config, pkgs, ... }:

   {
     programs.myprogram = {
       enable = true;
       # Additional configuration...
     };
   }
   ```

2. Import it in `hosts/a6mbp/home.nix`:
   ```nix
   imports = [
     # ... existing imports
     ./modules/programs/myprogram.nix
   ];
   ```

### Adding New Packages

Add packages to the appropriate category file in `hosts/a6mbp/modules/packages/`:

```nix
# hosts/a6mbp/modules/packages/development.nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ... existing packages
    nodejs_20
    yarn
  ];
}
```

### Adding Homebrew Packages

Edit `darwin.nix` to add formulae or casks:

```nix
homebrew = {
  enable = true;

  brews = [
    "package-name"
  ];

  casks = [
    "app-name"
  ];
};
```

### Creating a New Host

To set up configuration for another Mac:

1. Copy `hosts/a6mbp` to a new directory (e.g., `hosts/work-macbook`)
2. Add a new configuration in the root `flake.nix`:
   ```nix
   darwinConfigurations = {
     a6mbp = nix-darwin.lib.darwinSystem { ... };  # existing
     work-macbook = nix-darwin.lib.darwinSystem {
       inherit system;
       modules = [
         ./darwin.nix
         home-manager.darwinModules.home-manager
         {
           home-manager.users.bryan = import ./hosts/work-macbook/home.nix;
           # ... other config
         }
       ];
     };
   };
   ```
3. Customize the host-specific configuration in `hosts/work-macbook/`
4. Build with: `darwin-rebuild switch --flake .#work-macbook`

**Note**: The configuration name (e.g., `a6mbp`) doesn't need to match your system hostname.

## Key Configuration Details

### System Settings (darwin.nix)

- Disables nix-darwin's Nix management (uses Determinate Nix)
- Enables Zsh system-wide
- Allows unfree packages
- Declarative Homebrew management with automatic cleanup

### Home Manager (home.nix)

- Modular configuration with separate files for each program/package category
- Forces overwrite of Alacritty config (prevents conflicts)
- State version: 24.05

### Terminal Setup

- **Alacritty**: GPU-accelerated terminal with custom theme and opacity
- **Zsh**: Powerlevel10k theme, auto-suggestions, syntax highlighting, and enhanced completions (no Oh-My-Zsh for faster startup)
- **Tmux**: Vi key bindings, 256 color support, integration with dotfiles
- **Neovim**: Set as default editor, managed plugins via Lazy.nvim (external)

## Notes

- This configuration uses **Determinate Nix**, so nix-darwin's Nix management is disabled
- Homebrew is managed **declaratively** - packages not in the config will be uninstalled

## Troubleshooting

### Configuration doesn't apply

- Ensure you're in the correct directory when running `darwin-rebuild`
- Check for syntax errors: `nix flake check`
- Review logs: `darwin-rebuild switch --flake . --show-trace`

### Homebrew packages not installing

- Verify Homebrew is installed: `which brew`
- Check Homebrew logs: `brew doctor`
- Ensure the tap is added if using third-party formulae

### Shell changes not taking effect

- Restart your terminal or run: `exec zsh`
- Ensure zsh is your default shell: `echo $SHELL`

### Conflicts with existing dotfiles

- Home Manager backs up existing files with `.backup` extension
- Check `~/.config/` for backup files
- Manually merge or remove conflicting configurations

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Documentation](https://daiderd.com/nix-darwin/manual/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixpkgs Package Search](https://search.nixos.org/packages)

## License

This configuration is free to use and modify for your own purposes.

---

**Happy Nix-ing! 🚀**
