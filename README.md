# Nix Configuration

Declarative, reproducible system configuration using Nix for macOS (nix-darwin) and NixOS. Includes cross-platform development environments for VA projects.

## Hosts

### darwin-common (all macOS)

**Nix packages:** vim, neovim, git, gh, alacritty, ripgrep, fd, wget, tree, htop
**Homebrew brews:** powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, bat, eza, fzf, direnv, redis, libpq, gnupg, ca-certificates, stow, tmux, ncurses, pinentry-mac
**Homebrew casks:** claude, cursor, obsidian, rectangle-pro
**Font:** MesloLGS Nerd Font

### mbp (personal)

Includes `darwin-common` plus:

**Homebrew casks:** bambu-studio, steam

### a6mbp (work)

Includes `darwin-common` plus:

**Nix packages:** awscli2, docker-compose
**Homebrew brews:** ddev
**Homebrew casks:** notion, slack, zoom

### gnarbox (NixOS)

**System:** GNOME desktop, systemd-boot, NetworkManager
**Packages:** vim, neovim, git, gh, alacritty, ripgrep, fd, wget, tree, htop, bat, eza, fzf, direnv, stow, tmux, redis, libpq, gnupg, vlc, discord, obsidian, claude-code, cursor, firefox, steam (with proton-ge-bin)
**Zsh plugins:** powerlevel10k, autosuggestions, syntax-highlighting
**Font:** MesloLGS Nerd Font

## Prerequisites

Install [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer):

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

**macOS only:** Install [Homebrew](https://brew.sh) and [nix-darwin](https://github.com/LnL7/nix-darwin) (see their docs for setup).

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/nix-configs.git ~/code/nix-configs
cd ~/code/nix-configs
```

Build and activate:

**macOS:**

```bash
darwin-rebuild switch --flake .#mbp  # or .#a6mbp for work machine
```

**NixOS:**

```bash
sudo nixos-rebuild switch --flake .#gnarbox
```

## Usage

### Apply Changes

**macOS:**

```bash
darwin-rebuild switch --flake ~/code/nix-configs#mbp
```

**NixOS:**

```bash
sudo nixos-rebuild switch --flake ~/code/nix-configs#gnarbox
```

### Update Dependencies

```bash
nix flake update
# then rebuild using commands above
```

## Development Environments

Cross-platform development environments for VA projects:

- **vets-website:** Node 14.15.0, Yarn 1.x, Cypress → [vets-website](https://github.com/department-of-veterans-affairs/vets-website)
- **vets-api:** Ruby 3.3.6, PostgreSQL, Redis, Kafka → [vets-api](https://github.com/department-of-veterans-affairs/vets-api)
- **next-build:** Node 24, Yarn 3.x, Playwright → [next-build](https://github.com/department-of-veterans-affairs/next-build)
- **component-library:** Node 22, Yarn 4.x, Puppeteer → [component-library](https://github.com/department-of-veterans-affairs/component-library)

**Activate manually:**

```bash
nix develop ~/code/nix-configs#vets-website
```

**Auto-activate with direnv:**

```bash
cd ~/code/nix-configs
./dev-envs/setup-va-envrcs.sh  # Creates .envrc files for all VA repos
```

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Documentation](https://daiderd.com/nix-darwin/manual/)
- [Nixpkgs Package Search](https://search.nixos.org/packages)

## License

This configuration is free to use and modify for your own purposes.
