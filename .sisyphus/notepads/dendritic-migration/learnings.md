# Learnings - Dendritic Migration

## Conventions & Patterns

_Agents will append findings here as they discover conventions in the codebase._

---

## Task 1: Cursor Cleanup - Completed

### Execution Summary
- **Commit**: 02eb5ba5691a044c087336a2eec3ed1157777744
- **Message**: `chore: remove cursor package references`
- **Files Modified**: 5 (flake.nix, hosts/a6mbp.nix, README.md, flake.lock, pkgs/cursor/update.sh deleted)
- **Status**: ✅ COMPLETE

### Key Findings

1. **Cursor was dead code**: The `pkgs/cursor/` directory only contained `update.sh` with no `default.nix`, confirming it was non-functional.

2. **Three overlay locations**: Cursor was referenced in three places in flake.nix:
   - mkPkgs helper function (lines 29-33)
   - packages.x86_64-linux export (lines 71-74) - removed entire packages block as cursor was the only entry
   - nixosConfigurations gnarbox module (lines 99-103)

3. **Documentation cleanup**: Cursor appeared in README.md in two places:
   - darwin-common casks list (line 11)
   - gnarbox packages list (line 31)

4. **All builds verified**: 
   - nix flake check: PASS
   - darwin-rebuild for mbp, a6mbp, studio: PASS
   - NixOS gnarbox dry-run: PASS
   - No cursor references remain in .nix files

### Patterns for Future Tasks

1. **Overlay removal pattern**: When removing overlays from mkPkgs, ensure to clean up:
   - The overlay definition itself
   - Any exports that depend on it
   - All references in nixosConfigurations

2. **Documentation sync**: Always update README.md when removing packages from hosts to keep documentation accurate.

3. **Verification order**: 
   - nix flake check first (catches syntax errors)
   - darwin-rebuild for each host (catches evaluation errors)
   - NixOS dry-run (catches cross-platform issues)
   - grep verification (catches missed references)

### Blockers Cleared
- ✅ Task 1 complete - unblocks Tasks 2 and 3 (flake-parts setup and modules directory)

## Task 2: Add flake-parts and import-tree Inputs - Completed

### Execution Summary
- **Commit**: 1d816fd
- **Message**: `feat: add flake-parts and import-tree inputs`
- **Files Modified**: 2 (flake.nix, flake.lock)
- **Status**: ✅ COMPLETE

### Key Findings

1. **Input declaration pattern**: New inputs added to the inputs section with proper formatting:
   - flake-parts: Requires `inputs.nixpkgs-lib.follows = "nixpkgs"` to avoid duplicate nixpkgs
   - import-tree: Simple URL-only input, no special configuration needed

2. **Outputs function signature must be updated**: When adding new inputs, the outputs function destructuring must include them:
   - Before: `outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin } @ inputs:`
   - After: `outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin, flake-parts, import-tree } @ inputs:`
   - This is critical - omitting them causes "function 'outputs' called with unexpected argument" error

3. **Flake lock update**: Using `nix flake lock --update-input` (deprecated but functional) successfully:
   - Added flake-parts with narHash and timestamp
   - Added flake-parts/nixpkgs-lib following nixpkgs
   - Added import-tree with narHash and timestamp

4. **Verification workflow**:
   - `nix flake metadata | grep` confirms inputs are registered
   - `nix flake check` validates syntax and evaluates all outputs
   - All dev shells and configurations still evaluate correctly

### Patterns for Future Tasks

1. **Input addition checklist**:
   - Add to inputs section with proper formatting
   - Update outputs function signature
   - Run `nix flake lock --update-input <name>` for each new input
   - Verify with `nix flake metadata | grep <name>`
   - Run `nix flake check` to ensure no evaluation errors

2. **Follows pattern**: When an input has dependencies on nixpkgs, use `inputs.nixpkgs-lib.follows = "nixpkgs"` to prevent duplicate nixpkgs in the dependency tree.

3. **No functional changes needed yet**: Adding inputs doesn't require changes to outputs - they're just available for future use in Task 11 when restructuring outputs.

### Blockers Cleared
- ✅ Task 2 complete - unblocks Tasks 4, 5, 6, 7, 8 (feature module migration)
- ✅ flake-parts framework now available for dendritic module organization
- ✅ import-tree ready for auto-importing modules in Task 11

## Task 3: Create Dendritic Modules Directory Structure - Completed

### Execution Summary
- **Commit**: 05f198d
- **Message**: `feat: create dendritic modules directory structure`
- **Files Created**: 7 (6 directories + 1 README.md)
- **Status**: ✅ COMPLETE

### Directory Structure Created

```
modules/
├── base/          # Core system config (fonts, nix-settings, zsh)
├── dev/           # Development tools (editors, git, cli-tools)
├── services/      # System services (ollama, open-webui, monitoring, smb-mount)
├── desktop/       # Desktop environment (gnome, gaming)
├── hosts/         # Host-specific configs (mbp, a6mbp, studio, gnarbox)
├── dev-envs/      # Development environments (vets-website, vets-api, etc.)
├── darwin/        # Pre-existing (will be refactored in Task 4)
└── README.md      # Architecture documentation
```

### Key Findings

1. **Dendritic pattern rationale**: Organizing by feature instead of host enables:
   - Reusable modules across multiple hosts
   - Clear separation of concerns
   - Easier testing and composition
   - Better documentation of what each module does

2. **Module responsibilities**:
   - **base**: System-wide defaults that apply to all hosts
   - **dev**: Tools used across development work
   - **services**: Background processes and daemons
   - **desktop**: GUI and display-related configuration
   - **hosts**: Host-specific composition and overrides
   - **dev-envs**: Isolated project shells (not host-specific)

3. **Pre-existing darwin/ directory**: The `modules/darwin/` directory already existed with a `services/` subdirectory. This will be refactored in Task 4 as part of the feature module migration.

4. **README documentation**: Created comprehensive README explaining:
   - Purpose of dendritic organization
   - What each subdirectory contains
   - Architecture pattern (flake-parts + import-tree)
   - Migration status and task tracking

### Patterns for Future Tasks

1. **Directory creation**: Use `mkdir -p modules/{base,dev,services,desktop,hosts,dev-envs}` to create all at once - atomic and efficient.

2. **README placement**: Each major directory should have a README explaining its purpose and contents. This aids navigation and onboarding.

3. **Migration scaffolding**: Creating the directory structure first (before moving code) allows:
   - Clear planning of what goes where
   - Parallel work on different modules
   - Easier review of the overall structure

### Blockers Cleared
- ✅ Task 3 complete - scaffolding ready for Tasks 4-10
- ✅ Directory structure provides clear targets for feature module migration
- ✅ README documents the architectural pattern for future maintainers

### Next Steps
- Task 4: Migrate base module (fonts, nix-settings, zsh)
- Task 5: Migrate dev module (editors, git, cli-tools)
- Task 6: Migrate services module (ollama, open-webui, monitoring, smb-mount)
- Task 7: Migrate desktop module (gnome, gaming)
- Task 8: Migrate hosts module (mbp, a6mbp, studio, gnarbox)
- Task 9: Migrate dev-envs module
- Task 10: Verify all migrations and clean up old structure
- Task 11: Restructure flake.nix outputs using flake-parts and import-tree

## Task 4: Extract Base Features to Dendritic Modules - Completed

### Execution Summary
- **Commit**: 82339e0
- **Message**: `feat(modules): add base features (fonts, nix-settings, zsh)`
- **Files Created**: 3 (modules/base/fonts.nix, modules/base/nix-settings.nix, modules/base/zsh.nix)
- **Status**: ✅ COMPLETE

### Key Findings

1. **Flake-parts module structure pattern**: Each module exports both darwin and nixos aspects:
   ```nix
   { inputs, ... }:
   {
     flake.modules.darwin.<name> = { pkgs, ... }: { ... };
     flake.modules.nixos.<name> = { pkgs, ... }: { ... };
   }
   ```
   - Top-level function takes `{ inputs, ... }` for flake-parts compatibility
   - Each aspect is a separate attribute under `flake.modules.{darwin,nixos}`
   - Aspect functions take standard module arguments `{ pkgs, ... }`

2. **Platform-specific configuration differences**:
   - **fonts.nix**: Identical configuration for both platforms (nerd-fonts.meslo-lg)
   - **nix-settings.nix**: 
     - Darwin: `nix.enable = false;` (using Determinate Nix installer)
     - NixOS: Full nix configuration (package, extraOptions, settings)
   - **zsh.nix**: Identical configuration for both platforms (programs.zsh.enable = true)

3. **Syntax validation**: `nix-instantiate --parse` successfully validates all three modules:
   - Confirms proper Nix syntax
   - Verifies attribute structure
   - Catches typos and structural errors early

4. **Host configurations remain unchanged**: darwin-common.nix and gnarbox.nix still contain the original configuration. These modules will be wired up in Task 11 when restructuring flake.nix outputs.

### Patterns for Future Tasks

1. **Module creation checklist**:
   - Create file with flake-parts structure
   - Define both darwin and nixos aspects (even if identical)
   - Extract exact configuration from host files
   - Validate syntax with `nix-instantiate --parse`
   - Verify host files unchanged with `git status --porcelain`
   - Commit with descriptive message

2. **Platform differences**: When extracting configuration:
   - Check both darwin-common.nix and gnarbox.nix for differences
   - Document why platforms differ (e.g., Determinate Nix on macOS)
   - Keep identical configs identical (easier to maintain)

3. **Module naming**: Use descriptive names that reflect purpose:
   - `fonts.nix` not `meslo.nix` (describes category, not specific package)
   - `nix-settings.nix` not `nix.nix` (avoids confusion with nix attribute)
   - `zsh.nix` not `shell.nix` (specific about what it configures)

### Blockers Cleared
- ✅ Task 4 complete - base features extracted to dendritic modules
- ✅ Pattern established for Tasks 5, 6, 7, 8 (dev, services, desktop, hosts)
- ✅ Syntax validation confirms modules are ready for import-tree in Task 11

### Next Steps
- Task 5: Extract dev features (editors, git, cli-tools)
- Task 6: Extract services features (ollama, open-webui, monitoring, smb-mount)
- Task 7: Extract desktop features (gnome, gaming)
- Task 8: Extract host-specific features (mbp, a6mbp, studio, gnarbox)

## Task 5: Extract Dev Features to Dendritic Modules - Completed

### Execution Summary
- **Commit**: 2e9188f
- **Message**: `feat(modules): add dev features (editors, git, cli-tools)`
- **Files Created**: 3 (modules/dev/editors.nix, modules/dev/git.nix, modules/dev/cli-tools.nix)
- **Status**: ✅ COMPLETE

### Key Findings

1. **Package distribution across modules**:
   - **editors.nix**: vim, neovim (2 packages)
   - **git.nix**: git, gh (2 packages)
   - **cli-tools.nix**: alacritty, ripgrep, fd, wget, tree, htop, bat, eza, fzf, direnv, nix-direnv, stow, tmux, ncurses, nixd, bun, delta, jq, zoxide, shellcheck (20 packages)

2. **Platform differences identified**:
   - **darwin-common.nix** (lines 13-40): Contains subset of packages (no bat, eza, fzf, direnv, stow, tmux, ncurses, delta, jq, zoxide, shellcheck)
   - **gnarbox.nix** (lines 210-277): Contains full set of CLI tools
   - **Decision**: Included ALL packages from both hosts in cli-tools.nix to provide complete toolset across platforms

3. **Module structure consistency**: All three modules follow the flake-parts pattern established in Task 4:
   - Top-level function: `{ inputs, ... }:`
   - Darwin aspect: `flake.modules.darwin.<name>`
   - NixOS aspect: `flake.modules.nixos.<name>`
   - Identical configuration for both platforms (no platform-specific differences needed)

4. **Syntax validation**: All three modules parse successfully with `nix-instantiate --parse`, confirming proper Nix syntax and structure.

### Patterns for Future Tasks

1. **Package categorization**: When extracting packages, group by logical function:
   - Editors: Text editing tools
   - Git: Version control tools
   - CLI tools: Everything else (terminal, utilities, development tools)

2. **Platform superset approach**: When platforms have different package lists, include the superset in the module. This ensures:
   - All hosts have access to the full toolset
   - No functionality is lost during migration
   - Easier to maintain (one source of truth)

3. **Comments preservation**: Maintain inline comments from original configs (e.g., `# better grep`, `# GitHub CLI`) to document package purpose.

### Blockers Cleared
- ✅ Task 5 complete - dev features extracted to dendritic modules
- ✅ Pattern reinforced for Tasks 6, 7, 8 (services, desktop, hosts)
- ✅ All dev modules ready for import-tree in Task 11

### Next Steps
- Task 6: Extract services features (ollama, open-webui, monitoring, smb-mount)
- Task 7: Extract desktop features (gnome, gaming)
- Task 8: Extract host-specific features (mbp, a6mbp, studio, gnarbox)


## Task 6: Homebrew Module Extraction

**Pattern Applied:**
- Darwin-only module (no nixos aspect needed)
- Homebrew is macOS-specific, NixOS uses native package management
- Followed flake-parts structure: `flake.modules.darwin.homebrew`

**Critical Settings Preserved:**
- `onActivation.cleanup = "zap"` - Removes unmanaged packages
- `onActivation.autoUpdate = true` - Auto-updates Homebrew
- `onActivation.upgrade = true` - Auto-upgrades packages

**Brew List Extracted:**
- Zsh plugins: powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting
- CLI tools: bat, bind, ca-certificates, delta, direnv, eza, ffmpeg, fzf, gnupg, jq, just, lazydocker, lazygit, libpq, ncurses, opencode, pinentry-mac, redis, shellcheck, stow, tlrc, tmux, zoxide

**Cask List Extracted:**
- obsidian, opencode-desktop, sol, yaak

**Validation:**
- `nix-instantiate --parse` confirmed syntax validity
- Module structure matches fonts.nix pattern

**Next Steps:**
- Task 9 will import this module into darwin host configurations
- Host-specific brews/casks (like ddev for a6mbp) will be added in host modules

## Task 7: Migrate Darwin Services to Dendritic Structure - Completed

### Execution Summary
- **Commit**: 3432558
- **Message**: `feat(modules): migrate darwin services to dendritic structure`
- **Files Created**: 4 (modules/services/ollama.nix, open-webui.nix, monitoring.nix, smb-mount.nix)
- **Status**: ✅ COMPLETE

### Key Findings

1. **Service module complexity varies significantly**:
   - **ollama.nix**: 77 lines - Simple launchd agent with environment variables and firewall rules
   - **monitoring.nix**: 103 lines - Dual service (Prometheus + Grafana) with separate launchd agents
   - **smb-mount.nix**: 154 lines - Complex mount script with retry logic and network monitoring
   - **open-webui.nix**: 190 lines - Most complex with 3 shell scripts (runner, updater, manual upgrade)

2. **Darwin services use launchd agents pattern**:
   - All services use `launchd.user.agents.<name>` for service definition
   - Common serviceConfig attributes: ProgramArguments, RunAtLoad, KeepAlive, StandardOutPath, StandardErrorPath
   - Environment variables passed via EnvironmentVariables attribute
   - Firewall rules configured via system.activationScripts

3. **Shell script generation with pkgs.writeShellScript(Bin)**:
   - open-webui.nix uses `pkgs.writeShellScriptBin` for user-facing commands (upgrade-open-webui)
   - open-webui.nix and smb-mount.nix use `pkgs.writeShellScript` for service runners
   - Scripts must be defined in `let` block before options/config sections
   - Scripts reference cfg options, so must be inside module function scope

4. **NixOS stubs are simple TODO comments**:
   - Each module includes `flake.modules.nixos.<name>` with TODO comment
   - Comments reference appropriate NixOS equivalents (systemd services, native packages)
   - Stubs maintain module structure consistency for future implementation

5. **Original modules remain unchanged**:
   - All 4 files in `modules/darwin/services/` are untouched
   - Migration is additive - new modules created alongside old ones
   - Old modules will be deleted in Task 12 after host migration complete

### Patterns for Future Tasks

1. **Service module migration checklist**:
   - Read original module to understand structure
   - Identify all let bindings (scripts, variables)
   - Wrap in flake-parts structure: `{ inputs, ... }: { flake.modules.darwin.<name> = { pkgs, config, lib, ... }: { ... }; }`
   - Preserve ALL options, config, scripts, and activation scripts
   - Add simple nixos stub with TODO comment
   - Validate with `nix-instantiate --parse`
   - Verify original unchanged with `git status --porcelain`

2. **Let binding scope considerations**:
   - Scripts that reference cfg must be inside module function (after options defined)
   - Scripts that reference pkgs need pkgs in module function arguments
   - homeDir variable pattern: `homeDir = "/Users/${config.system.primaryUser}";`

3. **Service complexity indicators**:
   - Simple: Single launchd agent, basic options
   - Medium: Multiple launchd agents, firewall rules
   - Complex: Shell scripts, retry logic, network monitoring, auto-updates

4. **NixOS equivalents to document**:
   - launchd.user.agents → systemd.user.services
   - Homebrew binaries → Native nixpkgs packages
   - macOS firewall rules → NixOS firewall configuration
   - mount_smbfs → fileSystems with fsType = "cifs"

### Blockers Cleared
- ✅ Task 7 complete - all darwin services migrated to dendritic structure
- ✅ Pattern established for service modules with complex shell scripts
- ✅ Ready for Task 9 (host configuration migration to import these modules)

### Next Steps
- Task 8: Migrate desktop features (gnome, gaming) - parallel with Task 9
- Task 9: Migrate host configurations to import dendritic modules
- Task 10: Verify all migrations and test builds
- Task 11: Restructure flake.nix outputs using flake-parts and import-tree
- Task 12: Delete old module structure after verification


## Task 8: Desktop Features Extraction (2026-01-27)

### Pattern: NixOS-Only Desktop Modules
- Desktop environments (GNOME, gaming, audio) are NixOS-exclusive
- Use ONLY `flake.modules.nixos.<name>` aspect (no darwin aspect needed)
- Structure: `{ inputs, ... }: { flake.modules.nixos.<name> = { pkgs, lib, ... }: { ... }; }`

### Extracted Modules
1. **gnome.nix** - X11, GDM, GNOME desktop with power management overrides
2. **gaming.nix** - Steam, Proton GE, gamemode, graphics acceleration
3. **audio.nix** - PipeWire audio stack with ALSA/PulseAudio compatibility

### Configuration Preservation
- All settings from gnarbox.nix:81-116 (GNOME) preserved exactly
- All settings from gnarbox.nix:121-128 (audio) preserved exactly
- All settings from gnarbox.nix:131-134, 161-174 (gaming) preserved exactly
- No values changed, only reorganized into modular structure

### Validation
- All three modules pass `nix-instantiate --parse` validation
- Commit: 4837ae7 "feat(modules): add desktop features (gnome, gaming, audio)"

## Task 9: Host Configuration Modules

### Host Module Pattern
Host modules follow this structure:
```nix
{ inputs, ... }:
{
  flake.modules.darwin.<hostname> = { pkgs, config, ... }: {
    imports = with inputs.self.modules.darwin; [ ... ];
    # Host-specific config
  };
}
```

### Darwin Hosts Common Setup
All Darwin hosts need these settings that were in darwin-common.nix:
- `system.primaryUser = "bryan"`
- `nixpkgs.hostPlatform = "aarch64-darwin"`
- `system.stateVersion = 4`
- `nixpkgs.config.allowUnfree = true`
- `environment.systemPath = [ "/opt/homebrew/bin" ]`
- The oh-my-opencode activation script

### NixOS Host Imports
For NixOS, imports combine feature modules with local paths:
```nix
imports = (with inputs.self.modules.nixos; [ ... ]) ++ [
  ../../hosts/hardware-configs/gnarbox.nix
];
```

### Service Module Enabling
Service modules define `services.<name>.enable` options. Host modules enable them:
```nix
services.ollama.enable = true;
services.open-webui.enable = true;
```

## Task 10: Dev-Envs Migration (2026-01-27)

### Pattern: perSystem for devShells
Successfully wrapped all 5 VA dev environments in flake-parts perSystem structure:
```nix
{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.<name> = let
      lib = import ./lib.nix { inherit pkgs; };
      # ... original shell definition ...
    in pkgs.mkShell { ... };
  };
}
```

### Key Decisions
1. **lib.nix remains unchanged**: Shared utilities used by all dev-envs, no wrapping needed
2. **Relative import for lib.nix**: Each module uses `./lib.nix` to import shared utilities
3. **Shell content preserved**: All original configurations, environment variables, and shellHooks maintained exactly
4. **Helper scripts preserved**: yarnInstallWithScripts, rebuildNodeLibcurl, etc. remain in their original locations

### Validation
- All 6 files pass `nix-instantiate --parse` validation
- Original dev-envs/ files remain unchanged (deletion deferred to Task 12)

### Files Created
- modules/dev-envs/lib.nix (86 lines)
- modules/dev-envs/vets-website.nix (109 lines)
- modules/dev-envs/vets-api.nix (117 lines)
- modules/dev-envs/next-build.nix (64 lines)
- modules/dev-envs/component-library.nix (54 lines)
- modules/dev-envs/content-build.nix (164 lines)

Total: 594 lines of migrated code
