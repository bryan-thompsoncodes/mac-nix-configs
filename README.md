# Nix Configuration

Declarative, reproducible system configuration using Nix for macOS (nix-darwin) and NixOS. Includes cross-platform development environments for VA projects.

## Architecture

This repository uses a **dendritic (tree-like) modular architecture** with [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree). Configurations are organized by **feature/capability** rather than by host:

```
modules/
├── base/       # Core system: fonts, homebrew, nix-settings, zsh
├── dev/        # Development: cli-tools, editors, git
├── desktop/    # GUI: gnome, gaming, audio (NixOS)
├── services/   # Daemons: ollama, open-webui, monitoring, smb-mount, syncthing, icloud-backup (Darwin)
├── hosts/      # Host-specific: a6mbp, gnarbox, mbp, studio
└── dev-envs/   # VA project environments
```

Each host imports and composes feature modules. See [modules/README.md](modules/README.md) for detailed structure.

## Hosts

### mbp (personal macOS)

**Features:** fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
**Services:** syncthing
**Host-specific:** bambu-studio, discord, monal, rectangle-pro, steam, zen, node, pandoc, texlive, syncthing
**Location:** `modules/hosts/mbp.nix`

### a6mbp (work macOS)

**Features:** fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
**Services:** syncthing
**Host-specific:** awscli2, docker-compose, ddev, claude, claude-code, docker-desktop, notion, rectangle-pro, slack, syncthing, zoom
**Location:** `modules/hosts/a6mbp.nix`

### studio (media server macOS)

**Features:** fonts, nix-settings, zsh, homebrew, editors, git, cli-tools
**Services:** ollama, open-webui, monitoring, smb-mount, syncthing, icloud-backup
**Host-specific:** cloudflared, node, ollama, podman, prometheus, grafana, python@3.11, syncthing, zen
**Location:** `modules/hosts/studio.nix`

### gnarbox (NixOS desktop)

**Features:** fonts, nix-settings, zsh, editors, git, cli-tools
**Desktop:** gnome, gaming, audio
**Services:** syncthing
**Host-specific:** redis, libpq, gnupg, vlc, discord, obsidian, claude-code, opencode, yaak, firefox, steam (with proton-ge-bin)
**Location:** `modules/hosts/gnarbox.nix`

### Shared Configuration

All darwin hosts share these packages via feature modules:

**Nix packages:** vim, neovim, alacritty, ripgrep, fd, wget, tree, htop, bat, eza, fzf, direnv, nix-direnv, stow, ncurses, nixd, bun, delta, jq, zoxide, shellcheck, tea, vacuum-go
**Homebrew brews:** powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, bat, bind, ca-certificates, delta, direnv, eza, ffmpeg, fzf, gnupg, jq, just, lazydocker, lazygit, libpq, marksman, ncurses, opencode, pinentry-mac, pipx, poetry, python, redis, shellcheck, stow, tlrc, tmux, zoxide
**Homebrew casks:** obsidian, opencode-desktop, sol, sublime-text, yaak
**Font:** MesloLGS Nerd Font

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
darwin-rebuild switch --flake '.#mbp'  # or '.#a6mbp', '.#studio'
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

- **vets-website:** Node 22.22.0, Yarn 1.x, Cypress → [vets-website](https://github.com/department-of-veterans-affairs/vets-website)
- **vets-api:** Ruby 3.3.6, PostgreSQL, Redis, Kafka → [vets-api](https://github.com/department-of-veterans-affairs/vets-api)
- **next-build:** Node 24, Yarn 3.x, Playwright → [next-build](https://github.com/department-of-veterans-affairs/next-build)
- **component-library:** Node 22, Yarn 4.x, Puppeteer → [component-library](https://github.com/department-of-veterans-affairs/component-library)
- **content-build:** Node 14.15.0, Yarn 1.x, Cypress → content-build
- **simpler-grants:** Node 20, Python 3.11, pnpm (corepack), Poetry → [simpler-grants-protocol](https://github.com/HHS/simpler-grants-protocol)

**Activate manually:**

```bash
nix develop '~/code/nix-configs#vets-website'
```

Development environment definitions are located in `modules/dev-envs/`.

## OpenCode & oh-my-opencode

OpenCode is installed via Homebrew on all darwin systems. The oh-my-opencode plugin is automatically installed on rebuild (via activation script in each host module).

**Installation:**

The oh-my-opencode plugin installs automatically on the first rebuild after adding the configuration. Run:

```bash
darwin-rebuild switch --flake '.#mbp'
```

**Authentication:**

After installation, authenticate your AI providers:

```bash
opencode auth login
```

Follow the prompts to authenticate with:
- Anthropic (Claude) - select "Claude Team"
- OpenAI (ChatGPT) - select "ChatGPT Team"

**Usage:**

Start OpenCode:

```bash
opencode
```

The oh-my-opencode plugin provides:
- **Sisyphus** - Main orchestrator agent with specialized subagents
- **Multi-model support** - Claude, ChatGPT, Gemini
- **Enhanced tools** - LSP, AST grep, background agents
- **Productivity hooks** - Todo enforcement, comment checker, context management

Include `ultrawork` in your prompts for maximum parallel agent performance.

**Documentation:**
- [OpenCode Repository](https://github.com/opencode-ai/opencode)
- [oh-my-opencode Repository](https://github.com/code-yeongyu/oh-my-opencode)

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Documentation](https://daiderd.com/nix-darwin/manual/)
- [Nixpkgs Package Search](https://search.nixos.org/packages)
- [flake-parts Documentation](https://flake.parts/)

## 3 gits, one repo

This repository syncs to multiple remotes. The primary repository is at [git.snowboardtechie.com](https://git.snowboardtechie.com/bryan/nix-configs), with backups on [Codeberg](https://codeberg.org/SnowboardTechie/nix-configs) and [GitHub](https://github.com/bryan-thompsoncodes/nix-configs).

## License

This configuration is free to use and modify for your own purposes.
