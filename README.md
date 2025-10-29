# macOS Nix Configuration

A declarative, reproducible macOS system configuration using Nix, nix-darwin, and Home Manager.

## Overview

This repository contains a complete macOS system configuration managed with:

- **[Nix](https://nixos.org/)**: Declarative package management
- **[nix-darwin](https://github.com/LnL7/nix-darwin)**: macOS system configuration
- **[Home Manager](https://github.com/nix-community/home-manager)**: User environment management
- **[Homebrew](https://brew.sh/)**: macOS-specific packages (managed declaratively)
- **Development Shells**: Project-specific environments with pinned dependencies

The configuration is designed for Apple Silicon (aarch64) Macs and provides fully reproducible development environments.

## Features

### 🎯 Development Tools

- **Version Control**: Git, GitHub CLI
- **Languages**: Python 3.12, Java 11
- **Editors**: Neovim (with custom configs), configured with vi/vim aliases
- **Terminal**: Alacritty with Dracula-inspired theme
- **Shell**: Zsh with Powerlevel10k theme, auto-suggestions, syntax highlighting, and extensive aliases
- **Project Environments**: Pre-configured Nix shells for VA projects (vets-website, vets-api, next-build, component-library)

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
└── dev-envs/              # Development environment shells
    ├── component-library.nix
    ├── next-build.nix
    ├── vets-api.nix
    └── vets-website.nix
```

## Prerequisites

1. **Nix Package Manager**: Install the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer):

   ```bash
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
   ```

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

## Installation

### Initial Setup

1. **Clone this repository**:

   ```bash
   git clone https://github.com/yourusername/mac-nix-configs.git ~/code/mac-nix-configs
   cd ~/code/mac-nix-configs
   ```


3. **Build and activate the configuration**:

   ```bash
   darwin-rebuild switch --flake .#darwin
   ```

   The `#darwin` specifies which host configuration to use from the flake.

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
darwin-rebuild switch --flake ~/code/mac-nix-configs#darwin
```

### Updating Dependencies

Update all flake inputs to their latest versions:

```bash
update
```

Or manually:

```bash
nix flake update
darwin-rebuild switch --flake .#darwin
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

### Using Development Environments

This repository includes several pre-configured development environments:

- **vets-website**: Node.js 14.15.0, Yarn 1.x, Cypress dependencies
- **vets-api**: Ruby 3.3.6, PostgreSQL, Redis, Kafka
- **next-build**: Node.js 24, Yarn 3.x, Playwright, Docker
- **component-library**: Node.js 22, Yarn 4.x, Puppeteer

Activate a development environment:

```bash
cd ~/path/to/project
nix develop ~/code/mac-nix-configs#vets-website
```

Or use direnv for automatic activation:

```bash
# In your project directory
echo "use flake ~/code/mac-nix-configs#vets-website" > .envrc
direnv allow
```

## Key Configuration Details

### System Settings (darwin.nix)

- Disables nix-darwin's Nix management (uses Determinate Nix)
- Enables Zsh system-wide
- Allows unfree packages
- Declarative Homebrew management with automatic cleanup

### Development Environments

- **vets-website**: Node.js 14.15.0 with Yarn 1.x and Cypress dependencies
- **vets-api**: Ruby 3.3.6 with PostgreSQL, Redis, and Kafka
- **next-build**: Node.js 24 with Yarn 3.x, Playwright, and Docker
- **component-library**: Node.js 22 with Yarn 4.x and Puppeteer
- Each environment includes all necessary system dependencies and build tools

### Terminal Setup

- **Alacritty**: GPU-accelerated terminal with custom theme and opacity
- **Zsh**: Powerlevel10k theme, auto-suggestions, syntax highlighting, and enhanced completions (no Oh-My-Zsh for faster startup)
- **Tmux**: Vi key bindings, 256 color support, integration with dotfiles
- **Neovim**: Set as default editor, managed plugins via Lazy.nvim (external)

## Notes

- This configuration uses **Determinate Nix**, so nix-darwin's Nix management is disabled
- Homebrew is managed **declaratively** - packages not in the config will be uninstalled
- **SSH configuration is NOT managed by Nix** - We use `vtk socks` for VA work, which dynamically writes to `~/.ssh/config`. Managing SSH with Nix creates conflicts with vtk's configuration. Manage `~/.ssh/config` manually instead.

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
