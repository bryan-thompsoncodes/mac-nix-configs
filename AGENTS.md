# Agent Guidelines for nix-configs

## Build/Lint/Test Commands

### Nix Configuration
- **Build system:** `darwin-rebuild switch --flake '.#hostname'` (macOS) or `sudo nixos-rebuild switch --flake '.#hostname'` (NixOS)
- **Update dependencies:** `nix flake update`
- **Check flake:** `nix flake check`
- **Format code:** `nixpkgs-fmt .`

### Development Environments
Activate with: `nix develop '.#project-name'` (provides environments for vets-website, vets-api, next-build, component-library, content-build)

## Code Style Guidelines

### Nix Code
- **Formatting:** Use `nixpkgs-fmt` for consistent formatting
- **Naming:** Use camelCase for variables, PascalCase for modules
- **Imports:** Group imports by type (pkgs, lib, local modules)
- **Error handling:** Use `throw` for fatal errors, `abort` for user errors
- **Comments:** Use `#` for single-line comments, document complex logic
- **Structure:** Keep flake.nix clean, use separate .nix files for complex configurations

## Documentation Maintenance

**IMPORTANT:** Keep README.md in sync with configuration changes.

### When to Update README.md

Update the README when modifying:

| Change Type | README Section to Update |
|-------------|--------------------------|
| Add/remove homebrew brew or cask in `modules/base/homebrew.nix` | "Shared Configuration" → Homebrew brews/casks |
| Add/remove service module in `modules/services/` | Architecture tree + relevant host sections |
| Modify host-specific packages in `modules/hosts/*.nix` | Host section (mbp, a6mbp, studio, gnarbox) |
| Change dev environment versions in `modules/dev-envs/*.nix` | "Development Environments" section |
| Add new host or module | Architecture tree + new host section |

### README Sections Reference

- **Lines 10-17:** Module architecture tree
- **Lines 23-50:** Host configurations (features, services, host-specific packages)
- **Lines 52-59:** Shared configuration (Nix packages, Homebrew brews/casks)
- **Lines 121-125:** Development environment versions

### Verification Command

After making changes, verify README accuracy:
```bash
# Check that README matches actual config
grep -E "casks|brews" modules/base/homebrew.nix
grep -E "services\." modules/hosts/*.nix
```

## OpenCode with oh-my-opencode

This repository uses OpenCode with the oh-my-opencode plugin for enhanced AI agent capabilities.

### Key Features

**Sisyphus Agent:** Main orchestrator that delegates tasks to specialized subagents:
- oracle - Architecture, code review, strategy (GPT)
- librarian - Multi-repo analysis, doc lookup (Claude/Gemini)
- explore - Fast codebase exploration (Grok/Gemini/Haiku)
- frontend-ui-ux-engineer - UI development (Gemini)

**Productivity Tools:**
- LSP tools for refactoring and analysis
- AST grep for structural code patterns
- Background agents for parallel execution
- Todo continuation enforcement
- Context window management

### Usage Guidelines

**For Maximum Performance:**
Include `ultrawork` or `ulw` in prompts to enable:
- Parallel agent orchestration
- Background task delegation
- Deep exploration
- Relentless execution until completion

**For Search Tasks:**
Use keywords like `search`, `find`, `analyze`, `investigate` to activate specialized search and analysis modes.

**Multi-Model Orchestration:**
Sisyphus automatically selects appropriate models for different tasks:
- Complex reasoning → Claude Opus 4.5
- Frontend/UI → Gemini 3 Pro
- Documentation/Research → Claude Sonnet 4.5 or Gemini 3 Flash
- Fast exploration → Grok Code or Haiku

### Project Structure Integration

The oh-my-opencode plugin automatically:
- Injects AGENTS.md and README.md files from project hierarchy
- Loads commands from `~/.claude/commands/` and `.claude/commands/`
- Loads skills from `~/.claude/skills/` and `.claude/skills/`
- Loads MCP configurations from `.mcp.json` files

### Configuration

oh-my-opencode configuration is managed in:
- User config: `~/.config/opencode/oh-my-opencode.json`
- Project config: `.opencode/oh-my-opencode.json`

The plugin is installed automatically via activation script in each host module. Default settings use:
- Claude Team account enabled
- ChatGPT Team account enabled
- Gemini free account disabled

### Hooks

Available productivity hooks (all enabled by default):
- `todo-continuation-enforcer` - Forces agents to finish all todos
- `comment-checker` - Prevents excessive comments
- `context-window-monitor` - Warns at 70%+ token usage
- `keyword-detector` - Auto-activates modes based on prompts
- `ralph-loop` - Self-referential development loop
- And many more (see oh-my-opencode docs)

Disable specific hooks in `~/.config/opencode/oh-my-opencode.json`:
```json
{
  "disabled_hooks": ["comment-checker", "startup-toast"]
}
```