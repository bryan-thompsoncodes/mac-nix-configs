# Nix Configuration

A declarative, reproducible system configuration using Nix, supporting both macOS (via nix-darwin) and NixOS.

## Overview

This repository contains system configurations for multiple platforms:

- **[Nix](https://nixos.org/)**: Declarative package management
- **[nix-darwin](https://github.com/LnL7/nix-darwin)**: macOS system configuration
- **[NixOS](https://nixos.org/)**: Linux system configuration
- **[Homebrew](https://brew.sh/)**: macOS-specific packages (managed declaratively via nix-darwin)
- **Development Shells**: Cross-platform project-specific environments with pinned dependencies

The configuration supports both macOS (Apple Silicon) and NixOS (x86_64 Linux), providing fully reproducible development environments across platforms.

## Features

### 🎯 Development Tools

- **Version Control**: Git, GitHub CLI
- **Editors**: Neovim (with custom configs), Vim, Cursor
- **Terminal**: Alacritty
- **Shell**: Zsh with Powerlevel10k theme, auto-suggestions, and syntax highlighting (via Homebrew)
- **Project Environments**: Pre-configured Nix shells for VA projects (vets-website, vets-api, next-build, component-library)

### ☁️ Cloud & DevOps

- AWS CLI v2
- Docker Compose
- DDEV (via Homebrew)

### 🗄️ Databases & Services

- Redis (via Homebrew)
- PostgreSQL, Memcached, SQLite (available in project-specific dev-envs)

### 🛠️ CLI Utilities

- **Modern replacements**: `eza` (ls), `bat` (cat), `ripgrep` (grep), `fd` (find)
- **Productivity**: fzf, tmux, direnv (via Homebrew)
- **Network**: wget
- **Development**: tree, gnupg (via Homebrew)
- **System**: htop

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
├── hosts/                 # Host-specific configurations
│   ├── darwin-common.nix  # Shared macOS configuration for all Darwin hosts
│   ├── a6mbp.nix          # Work MacBook Pro (macOS, Apple Silicon)
│   ├── mbp.nix            # Personal MacBook Pro (macOS, Apple Silicon)
│   └── gnarbox.nix        # (Future) NixOS machine (x86_64 Linux)
└── dev-envs/              # Cross-platform development environment shells
    ├── lib.nix            # Shared utilities and platform detection
    ├── component-library.nix
    ├── next-build.nix
    ├── vets-api.nix
    └── vets-website.nix
```

## Prerequisites

### For All Systems

1. **Nix Package Manager**: Install the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer):

   ```bash
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
   ```

### For macOS

2. **nix-darwin**: Follow the [nix-darwin installation guide](https://github.com/LnL7/nix-darwin#readme)

3. **Homebrew**: Install from [brew.sh](https://brew.sh)

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   Note: nix-darwin will manage Homebrew packages declaratively, but Homebrew itself must be installed first.

4. Install Nix Flakes and Experimental Commands
   ```bash
   sudo nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .
   ```

### For NixOS

NixOS comes with Nix pre-installed. Simply ensure flakes are enabled in your system configuration:

```nix
# /etc/nixos/configuration.nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

## Installation

### Initial Setup

1. **Clone this repository**:

   ```bash
   git clone https://github.com/yourusername/nix-configs.git ~/code/nix-configs
   cd ~/code/nix-configs
   ```

2. **Build and activate the configuration**:

   **For macOS:**
   ```bash
   darwin-rebuild switch --flake .#mbp
   ```

   The `#mbp` specifies which host configuration to use from the flake (use `#a6mbp` for work machine).

   **For NixOS:**
   ```bash
   sudo nixos-rebuild switch --flake .#gnarbox
   ```

   Replace `gnarbox` with your host configuration name.

### Post-Installation

**For macOS users:**

1. **Configure Powerlevel10k** (if needed):

   ```bash
   p10k configure
   ```

   Configuration is stored in `~/.local/share/p10k/p10k.zsh`.

2. **Restart your terminal** or reload the shell:

   ```bash
   exec zsh
   ```

**For NixOS users:**

1. **Restart your system** or reload your user session to apply all changes.

2. **Configure your shell and terminal emulator** as defined in your host configuration.

## Usage

### Applying Changes

After modifying any configuration files:

**For macOS:**
```bash
rebuild  # If you have this alias set up
```

Or explicitly:

```bash
darwin-rebuild switch --flake ~/code/nix-configs#mbp  # or #a6mbp for work machine
```

**For NixOS:**
```bash
sudo nixos-rebuild switch --flake ~/code/nix-configs#gnarbox
```

### Updating Dependencies

Update all flake inputs to their latest versions:

**For macOS:**
```bash
update  # If you have this alias set up
```

Or manually:

```bash
nix flake update
darwin-rebuild switch --flake .#mbp
```

**For NixOS:**
```bash
nix flake update
sudo nixos-rebuild switch --flake .#gnarbox
```

## Customization

### Adding Development Environments

Add new development shell configurations in the `dev-envs/` directory:

```nix
# dev-envs/my-project.nix
{ pkgs }:

pkgs.mkShell {
  buildInputs = [
    pkgs.nodejs_20
    pkgs.yarn
    # ... other dependencies
  ];

  shellHook = ''
    echo "🚀 my-project development environment"
    # ... setup commands
  '';
}
```

Then add it to `flake.nix`:

```nix
devShells.${system} = {
  # ... existing shells
  my-project = import ./dev-envs/my-project.nix {
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
};
```

Activate with: `nix develop .#my-project`

### Adding Homebrew Packages

**For packages shared across all macOS hosts**, edit `hosts/darwin-common.nix`:

```nix
homebrew = {
  brews = [
    "package-name"
  ];

  casks = [
    "app-name"
  ];
};
```

**For host-specific packages**, edit the appropriate host configuration file (`hosts/mbp.nix` or `hosts/a6mbp.nix`):

```nix
homebrew = {
  brews = [
    "package-name"
  ];

  casks = [
    "app-name"
  ];
};
```

Note: Homebrew lists are automatically merged, so each host gets both the common packages from `darwin-common.nix` and their host-specific additions.

### Using Development Environments

This repository includes several pre-configured cross-platform development environments:

- **vets-website**: Node.js 14.15.0, Yarn 1.x, Cypress dependencies
- **vets-api**: Ruby 3.3.6, PostgreSQL, Redis, Kafka
- **next-build**: Node.js 24, Yarn 3.x, Playwright, Docker
- **component-library**: Node.js 22, Yarn 4.x, Puppeteer

These environments work on both macOS and Linux, with platform-specific dependencies automatically selected.

Activate a development environment:

```bash
cd ~/path/to/project
nix develop ~/code/nix-configs#vets-website
```

Or use direnv for automatic activation:

```bash
# In your project directory
echo "use flake ~/code/nix-configs#vets-website" > .envrc
direnv allow
```

### Automatic Direnv Setup for VA Repositories

For a fresh workstation setup, use the included script to automatically create `.envrc` files for all VA repositories:

```bash
cd ~/code/nix-configs
./dev-envs/setup-va-envrcs.sh
```

This interactive script will:

- Check which VA repositories exist in `~/code/department-of-veterans-affairs/`
- Identify which repos already have `.envrc` files
- Create `.envrc` files for repos that need them
- Show instructions for running `direnv allow` for each new configuration

**Prerequisites:**

- direnv must be installed (included in host configuration Homebrew packages)
- VA repositories must be cloned (use `~/code/dotfiles/setup-va-repos.sh` first)

**Repositories configured:**

- `vets-website` → Node.js 14.15.0 environment
- `next-build` → Node.js 24 environment
- `vets-api` → Ruby 3.3.6 environment
- `component-library` → Node.js 22 environment

After running the script, the development environment will load automatically when you `cd` into any VA repository directory.

## Key Configuration Details

### System Settings (Host Configurations)

This repository supports multiple host configurations across platforms:

**macOS Hosts (nix-darwin):**
- **`hosts/darwin-common.nix`**: Shared configuration for all macOS hosts
  - System packages (editors, version control, terminal, CLI utilities)
  - Font configuration (MesloLGS Nerd Font)
  - Zsh configuration
  - Common Homebrew packages (zsh plugins, CLI tools, common apps)
  - System settings (disables nix-darwin's Nix management, allows unfree packages)
- **`hosts/mbp.nix`**: Personal MacBook Pro configuration
  - Imports `darwin-common.nix`
  - Additional casks: bambu-studio, steam
- **`hosts/a6mbp.nix`**: Work MacBook Pro configuration
  - Imports `darwin-common.nix`
  - Additional packages: awscli2, docker-compose
  - Additional Homebrew: DDEV (for va.gov-cms development)
  - Additional casks: notion, slack, zoom

Each macOS host configuration includes:
- Disables nix-darwin's Nix management (uses Determinate Nix)
- Enables Zsh system-wide
- Allows unfree packages
- Declarative Homebrew management with automatic cleanup

**NixOS Hosts:**
- **`hosts/gnarbox.nix`**: (Future) NixOS machine configuration

NixOS host configurations will include standard NixOS system settings, user management, and package declarations.

### Development Environments

All development environments are cross-platform compatible:

- **vets-website**: Node.js 14.15.0 with Yarn 1.x and Cypress dependencies
- **vets-api**: Ruby 3.3.6 with PostgreSQL, Redis, and Kafka
- **next-build**: Node.js 24 with Yarn 3.x, Playwright, and Docker
- **component-library**: Node.js 22 with Yarn 4.x and Puppeteer
- Each environment includes all necessary system dependencies and build tools
- Platform-specific dependencies (e.g., browser testing libraries) are automatically selected based on the host system

### Terminal Setup (macOS)

- **Alacritty**: GPU-accelerated terminal with custom theme and opacity
- **Zsh**: Powerlevel10k theme, auto-suggestions, syntax highlighting, and enhanced completions (no Oh-My-Zsh for faster startup)
- **Tmux**: Vi key bindings, 256 color support, integration with dotfiles
- **Neovim**: Set as default editor, managed plugins via Lazy.nvim (external)

Note: NixOS terminal setup will be configured per-host in the respective host configuration files.

## Notes

### General
- This configuration uses **Determinate Nix** for all systems
- Development environments are **cross-platform** and work on both macOS and NixOS
- **SSH configuration is NOT managed by Nix** - We use `vtk socks` for VA work, which dynamically writes to `~/.ssh/config`. Managing SSH with Nix creates conflicts with vtk's configuration. Manage `~/.ssh/config` manually instead.

### macOS-Specific
- nix-darwin's Nix management is disabled (uses Determinate Nix)
- Homebrew is managed **declaratively** - packages not in the config will be uninstalled

### NixOS-Specific
- System configuration will be managed through standard NixOS modules
- No Homebrew dependency on NixOS systems

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

- nix-darwin may conflict with existing configurations
- Check `~/.config/` for any conflicting files
- Manually merge or remove conflicting configurations as needed

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Documentation](https://daiderd.com/nix-darwin/manual/)
- [Nixpkgs Package Search](https://search.nixos.org/packages)

## License

This configuration is free to use and modify for your own purposes.

---

**Happy Nix-ing! 🚀**
