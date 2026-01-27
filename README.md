# Nix Configuration

Declarative, reproducible system configuration using Nix for macOS (nix-darwin) and NixOS. Includes cross-platform development environments for VA projects.

## Architecture

This repository uses a modular architecture with configurations organized in `modules/`:

- **`modules/hosts/`** - Host-specific configurations (mbp, a6mbp, gnarbox)
- **`modules/common/`** - Shared configurations across all hosts
- **`modules/dev-envs/`** - Development environment definitions for VA projects
- **`flake.nix`** - Main entry point that composes modules into complete configurations

## Hosts

### mbp (personal macOS)

**Base:** darwin-common (shared macOS configuration)
**Additional packages:** bambu-studio, steam
**Location:** `modules/hosts/mbp.nix`

### a6mbp (work macOS)

**Base:** darwin-common (shared macOS configuration)
**Additional packages:** awscli2, docker-compose, ddev, notion, slack, zoom
**Location:** `modules/hosts/a6mbp.nix`

### gnarbox (NixOS)

**System:** GNOME desktop, systemd-boot, NetworkManager
**Packages:** vim, neovim, git, gh, alacritty, ripgrep, fd, wget, tree, htop, bat, eza, fzf, direnv, stow, tmux, redis, libpq, gnupg, vlc, discord, obsidian, claude-code, firefox, steam (with proton-ge-bin)
**Zsh plugins:** powerlevel10k, autosuggestions, syntax-highlighting
**Font:** MesloLGS Nerd Font
**Location:** `modules/hosts/gnarbox.nix`

### Common (darwin-common)

Shared configuration for all macOS hosts:

**Nix packages:** vim, neovim, git, gh, alacritty, ripgrep, fd, wget, tree, htop
**Homebrew brews:** powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, bat, eza, fzf, direnv, redis, libpq, gnupg, ca-certificates, stow, tmux, ncurses, pinentry-mac
**Homebrew casks:** claude, obsidian, rectangle-pro
**Font:** MesloLGS Nerd Font
**Location:** `modules/common/darwin-common.nix`

## Prerequisites

**macOS only:** Install [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer):

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
```

**NixOS:** Nix comes pre-installed.

## Installation

Clone the repository:

```bash
git clone https://git.snowboardtechie.com/bryan/nix-configs.git ~/code/nix-configs
cd ~/code/nix-configs
```

Build and activate:

**macOS:**

```bash
darwin-rebuild switch --flake '.#mbp'  # or '.#a6mbp' for work machine
```

**NixOS** (first build requires experimental features flag):

```bash
sudo nixos-rebuild switch --flake '.#gnarbox' --extra-experimental-features 'nix-command flakes'
```

## Usage

### Apply Changes

**macOS:**

```bash
darwin-rebuild switch --flake '~/code/nix-configs#mbp'
```

**NixOS:**

```bash
sudo nixos-rebuild switch --flake '~/code/nix-configs#gnarbox'
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
nix develop '~/code/nix-configs#vets-website'
```

Development environment definitions are located in `modules/dev-envs/`.

## Claude Code & oh-my-Claude

Claude Code is installed via Homebrew on all macOS systems. The oh-my-Claude plugin is automatically installed on rebuild (via activation script in darwin-common.nix).

**Installation:**

The oh-my-Claude plugin installs automatically on the first rebuild after adding the configuration. Run:

```bash
darwin-rebuild switch --flake '.#mbp'
```

**Authentication:**

After installation, authenticate your AI providers:

```bash
Claude auth login
```

Follow the prompts to authenticate with:
- Anthropic (Claude) - select "Claude Team"
- OpenAI (ChatGPT) - select "ChatGPT Team"

**Usage:**

Start Claude Code:

```bash
Claude
```

The oh-my-Claude plugin provides:
- **Sisyphus** - Main orchestrator agent with specialized subagents
- **Multi-model support** - Claude, ChatGPT, Gemini
- **Enhanced tools** - LSP, AST grep, background agents
- **Productivity hooks** - Todo enforcement, comment checker, context management

Include `ultrawork` in your prompts for maximum parallel agent performance.

**Documentation:**
- [Claude Code Docs](https://Claude.ai/docs)
- [oh-my-Claude Repository](https://github.com/code-yeongyu/oh-my-Claude)

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Documentation](https://daiderd.com/nix-darwin/manual/)
- [Nixpkgs Package Search](https://search.nixos.org/packages)

## 3 gits, one repo

This repository syncs to multiple remotes. The primary repository is at [git.snowboardtechie.com](https://git.snowboardtechie.com/bryan/nix-configs), with backups on [Codeberg](https://codeberg.org/SnowboardTechie/nix-configs) and [GitHub](https://github.com/bryan-thompsoncodes/nix-configs).

## License

This configuration is free to use and modify for your own purposes.
