# Dendritic Pattern Migration for nix-configs

## TL;DR

> **Quick Summary**: Migrate nix-configs from host-centric to feature-centric (dendritic) architecture using flake-parts. Includes pre-requisite cursor cleanup.
> 
> **Deliverables**:
> - All cursor references removed
> - flake.nix restructured with flake-parts
> - modules/ directory with dendritic feature organization
> - dev-envs integrated into modules/dev-envs/
> - All hosts building identically to before
> 
> **Estimated Effort**: Large (multi-day)
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Cursor Cleanup → flake-parts Setup → Base Modules → Host Migration → Dev-envs Integration

---

## Context

### Original Request
User wants to migrate nix-configs repository to the "dendritic pattern" for Nix flakes, with a preliminary cleanup of leftover cursor package references.

### Interview Summary
**Key Discussions**:
- Cursor cleanup should happen first (quick fix)
- No home-manager integration (user manages dotfiles in ../dotfiles)
- Dev-envs should be integrated into modules/ following dendritic pattern
- Incremental migration approach (one feature at a time, keep buildable)

**Research Findings**:
- Dendritic pattern uses flake-parts modules as universal building blocks
- Features contain "aspects" for each platform (darwin, nixos)
- Key tools: flake-parts (framework), import-tree (auto-importing)
- Pattern: `flake.modules.<class>.<feature>` or with flake-aspects: `flake.aspects.<feature>.<class>`

### Metis Review
**Identified Gaps** (addressed):

| Gap | Resolution |
|-----|------------|
| pkgs/cursor/ only has update.sh, no default.nix | Confirmed dead code - delete entire directory |
| Darwin service modules fate unclear | Migrate into modules/services/ with darwin aspects |
| darwin-common.nix handling | Distribute into multiple feature aspects (base, dev, homebrew) |
| dev-envs/lib.nix handling | Keep as shared lib, imported by dev-env modules |
| Verification strategy | Test both mbp (Darwin) and gnarbox (NixOS) at each step |
| flake-aspects vs manual | Use flake-parts + import-tree (simpler than flake-aspects for this scope) |

---

## Work Objectives

### Core Objective
Transform nix-configs from host-centric organization to feature-centric (dendritic) architecture while maintaining 100% functional equivalence.

### Concrete Deliverables
- `flake.nix` using flake-parts with auto-importing
- `modules/` directory with dendritic feature structure
- All 4 hosts building and working identically
- All 5 dev-envs working on both platforms
- Clean cursor removal with no orphaned references

### Definition of Done
- [ ] `nix flake check` passes
- [ ] All 4 hosts build: mbp, a6mbp, studio, gnarbox
- [ ] All 5 dev-envs evaluate on both aarch64-darwin and x86_64-linux
- [ ] No cursor references remain in codebase
- [ ] Module structure follows dendritic pattern

### Must Have
- flake-parts as flake framework
- Auto-importing of modules via import-tree
- Incremental migration with verification at each step
- Git checkpoints at stable states

### Must NOT Have (Guardrails)
- NO home-manager integration
- NO package list changes during migration
- NO modifications to hardware-configs/gnarbox.nix
- NO changes to oh-my-opencode activation script logic
- NO host renaming
- NO homebrew.onActivation changes
- NO feature additions (pure structural refactor)

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: YES (nix flake check, darwin-rebuild, nixos-rebuild)
- **User wants tests**: Manual verification commands
- **Framework**: Nix build system

### Verification Commands

**After each structural change, run:**

```bash
# 1. Flake syntax check
nix flake check

# 2. Darwin hosts (from macOS)
darwin-rebuild build --flake '.#mbp'
darwin-rebuild build --flake '.#a6mbp'
darwin-rebuild build --flake '.#studio'

# 3. NixOS host (evaluates without switching)
nix build '.#nixosConfigurations.gnarbox.config.system.build.toplevel' --dry-run

# 4. Dev shells (both platforms)
nix build '.#devShells.aarch64-darwin.vets-website' --dry-run
nix build '.#devShells.x86_64-linux.vets-website' --dry-run
```

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately):
└── Task 1: Cursor cleanup (no dependencies)

Wave 2 (After Wave 1):
├── Task 2: Add flake-parts + import-tree inputs
└── Task 3: Create modules/ directory structure

Wave 3 (After Wave 2):
├── Task 4: Migrate base features (fonts, nix-settings)
├── Task 5: Migrate dev features (editors, git, cli-tools)
└── Task 6: Migrate homebrew configuration

Wave 4 (After Wave 3):
├── Task 7: Migrate darwin services (ollama, etc.)
└── Task 8: Migrate desktop features (gnome, gaming)

Wave 5 (After Wave 4):
├── Task 9: Migrate host configurations
└── Task 10: Integrate dev-envs into modules

Wave 6 (Final):
└── Task 11: Update flake.nix to use new structure
└── Task 12: Cleanup old files and update README
```

### Dependency Matrix

| Task | Depends On | Blocks | Parallel With |
|------|------------|--------|---------------|
| 1 | None | 2, 3 | None |
| 2 | 1 | 4, 5, 6, 7, 8 | 3 |
| 3 | 1 | 4, 5, 6, 7, 8 | 2 |
| 4 | 2, 3 | 9 | 5, 6 |
| 5 | 2, 3 | 9 | 4, 6 |
| 6 | 2, 3 | 9 | 4, 5 |
| 7 | 2, 3 | 9 | 8 |
| 8 | 2, 3 | 9 | 7 |
| 9 | 4, 5, 6, 7, 8 | 11 | 10 |
| 10 | 2, 3 | 11 | 9 |
| 11 | 9, 10 | 12 | None |
| 12 | 11 | None | None |

---

## TODOs

### Phase 0: Cursor Cleanup

- [x] 1. Remove all cursor package references

  **What to do**:
  - Remove cursor overlay from mkPkgs in flake.nix (lines 29-33)
  - Remove packages.x86_64-linux.cursor export (lines 71-74)
  - Remove cursor overlay from nixosConfigurations (lines 99-103)
  - Remove "cursor" from homebrew.casks in hosts/a6mbp.nix (line 30)
  - Remove cursor references from README.md (lines 11, 31)
  - Delete pkgs/cursor/ directory entirely

  **Must NOT do**:
  - Do not remove any other packages
  - Do not modify any other homebrew settings

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple find-and-remove task, minimal complexity
  - **Skills**: [`git-master`]
    - `git-master`: Clean atomic commit after cleanup

  **Parallelization**:
  - **Can Run In Parallel**: NO (prerequisite for all other tasks)
  - **Parallel Group**: Wave 1 (solo)
  - **Blocks**: Tasks 2, 3
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - None needed - straightforward deletion

  **Files to Modify**:
  - `flake.nix:29-33` - Remove cursor overlay block from mkPkgs
  - `flake.nix:71-74` - Remove entire packages output or just cursor entries
  - `flake.nix:99-103` - Remove cursor overlay from nixosConfigurations
  - `hosts/a6mbp.nix:30` - Remove "cursor" from casks list
  - `README.md:11,31` - Remove cursor from package lists

  **Directory to Delete**:
  - `pkgs/cursor/` - Contains only update.sh, no default.nix

  **Acceptance Criteria**:
  - [ ] `grep -r "cursor" --include="*.nix" .` returns no matches
  - [ ] `ls pkgs/cursor/` returns "No such file or directory"
  - [ ] `nix flake check` passes
  - [ ] `darwin-rebuild build --flake '.#mbp'` succeeds
  - [ ] `darwin-rebuild build --flake '.#a6mbp'` succeeds
  - [ ] `darwin-rebuild build --flake '.#studio'` succeeds
  - [ ] `nix build '.#nixosConfigurations.gnarbox.config.system.build.toplevel' --dry-run` succeeds

  **Commit**: YES
  - Message: `chore: remove cursor package references`
  - Files: `flake.nix, hosts/a6mbp.nix, README.md, pkgs/cursor/ (deleted)`
  - Pre-commit: `nix flake check`

---

### Phase 1: flake-parts Foundation

- [x] 2. Add flake-parts and import-tree inputs

  **What to do**:
  - Add flake-parts input to flake.nix inputs
  - Add import-tree input to flake.nix inputs
  - Ensure inputs.nixpkgs.follows is set appropriately
  - Run `nix flake lock --update-input flake-parts --update-input import-tree`

  **Must NOT do**:
  - Do not restructure outputs yet (that's task 11)
  - Do not remove existing code

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple input additions
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 3)
  - **Blocks**: Tasks 4, 5, 6, 7, 8
  - **Blocked By**: Task 1

  **References**:

  **External References**:
  - flake-parts docs: https://flake.parts/getting-started
  - import-tree: https://github.com/vic/import-tree

  **Example Input Block**:
  ```nix
  inputs = {
    # ... existing inputs ...
    
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    
    import-tree.url = "github:vic/import-tree";
  };
  ```

  **Acceptance Criteria**:
  - [ ] `nix flake metadata` shows flake-parts and import-tree inputs
  - [ ] `nix flake check` passes
  - [ ] All existing builds still work (no functional changes)

  **Commit**: YES
  - Message: `feat: add flake-parts and import-tree inputs`
  - Files: `flake.nix, flake.lock`
  - Pre-commit: `nix flake check`

---

- [x] 3. Create modules/ directory structure

  **What to do**:
  - Create directory tree:
    ```
    modules/
    ├── base/
    ├── dev/
    ├── services/
    ├── desktop/
    ├── hosts/
    └── dev-envs/
    ```
  - Add placeholder README.md in modules/ explaining structure

  **Must NOT do**:
  - Do not move any code yet
  - Do not create actual module files yet

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Directory creation only
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 2)
  - **Blocks**: Tasks 4, 5, 6, 7, 8
  - **Blocked By**: Task 1

  **References**:

  **Target Structure** (from dendritic research):
  ```
  modules/
  ├── base/           # fonts, nix-settings, zsh
  ├── dev/            # editors, git, cli-tools
  ├── services/       # ollama, open-webui, monitoring, smb-mount
  ├── desktop/        # gnome, gaming
  ├── hosts/          # mbp, a6mbp, studio, gnarbox
  └── dev-envs/       # vets-website, vets-api, etc.
  ```

  **Acceptance Criteria**:
  - [ ] `ls modules/` shows: base, dev, services, desktop, hosts, dev-envs
  - [ ] All directories exist

  **Commit**: YES
  - Message: `feat: create dendritic modules directory structure`
  - Files: `modules/` directories
  - Pre-commit: None needed

---

### Phase 2: Feature Module Migration

- [x] 4. Migrate base features (fonts, nix-settings)

  **What to do**:
  - Create `modules/base/fonts.nix` with flake-parts module structure
  - Create `modules/base/nix-settings.nix` with nix configuration
  - Create `modules/base/zsh.nix` with zsh enable
  - Extract relevant code from darwin-common.nix and gnarbox.nix

  **Must NOT do**:
  - Do not modify darwin-common.nix yet (keep both working)
  - Do not change any font or nix settings values

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Code extraction and restructuring
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 5, 6)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 2, 3

  **References**:

  **Pattern References**:
  - `darwin-common.nix:7-10` - fonts.packages configuration
  - `gnarbox.nix:280-282` - fonts.packages configuration
  - `darwin-common.nix:5` - nix.enable = false (Darwin)
  - `gnarbox.nix:19-28` - nix settings (NixOS)

  **Module Structure Pattern**:
  ```nix
  # modules/base/fonts.nix
  { inputs, ... }:
  {
    flake.modules.darwin.fonts = { pkgs, ... }: {
      fonts.packages = with pkgs; [ nerd-fonts.meslo-lg ];
    };
    
    flake.modules.nixos.fonts = { pkgs, ... }: {
      fonts.packages = with pkgs; [ nerd-fonts.meslo-lg ];
    };
  }
  ```

  **Acceptance Criteria**:
  - [ ] `modules/base/fonts.nix` exists with darwin and nixos aspects
  - [ ] `modules/base/nix-settings.nix` exists
  - [ ] `modules/base/zsh.nix` exists
  - [ ] Modules are syntactically valid: `nix-instantiate --parse modules/base/fonts.nix`

  **Commit**: YES
  - Message: `feat(modules): add base features (fonts, nix-settings, zsh)`
  - Files: `modules/base/*.nix`
  - Pre-commit: Syntax validation

---

- [x] 5. Migrate dev features (editors, git, cli-tools)

  **What to do**:
  - Create `modules/dev/editors.nix` with vim, neovim
  - Create `modules/dev/git.nix` with git, gh
  - Create `modules/dev/cli-tools.nix` with ripgrep, fd, etc.
  - Extract from darwin-common.nix and gnarbox.nix

  **Must NOT do**:
  - Do not change package lists
  - Do not add new packages

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Code extraction and restructuring
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 4, 6)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 2, 3

  **References**:

  **Pattern References**:
  - `darwin-common.nix:13-40` - environment.systemPackages
  - `gnarbox.nix:210-277` - environment.systemPackages

  **Package Mapping**:
  - editors.nix: vim, neovim
  - git.nix: git, gh
  - cli-tools.nix: alacritty, ripgrep, fd, wget, tree, htop, bat, eza, fzf, etc.

  **Acceptance Criteria**:
  - [ ] `modules/dev/editors.nix` exists
  - [ ] `modules/dev/git.nix` exists
  - [ ] `modules/dev/cli-tools.nix` exists
  - [ ] All packages from original configs are accounted for

  **Commit**: YES
  - Message: `feat(modules): add dev features (editors, git, cli-tools)`
  - Files: `modules/dev/*.nix`
  - Pre-commit: Syntax validation

---

- [x] 6. Migrate homebrew configuration (Darwin only)

  **What to do**:
  - Create `modules/base/homebrew.nix` with darwin aspect only
  - Include common brews/casks from darwin-common.nix
  - Preserve exact onActivation settings

  **Must NOT do**:
  - Do not change homebrew.onActivation settings
  - Do not change any brew or cask lists

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Darwin-specific code extraction
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 4, 5)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 2, 3

  **References**:

  **Pattern References**:
  - `darwin-common.nix:81-134` - Complete homebrew configuration

  **Critical Settings to Preserve**:
  ```nix
  homebrew.onActivation = {
    autoUpdate = true;
    cleanup = "zap";  # MUST preserve - removes unmanaged packages
    upgrade = true;
  };
  ```

  **Acceptance Criteria**:
  - [ ] `modules/base/homebrew.nix` exists with darwin aspect
  - [ ] onActivation settings match exactly
  - [ ] All brews and casks from darwin-common.nix included

  **Commit**: YES
  - Message: `feat(modules): add homebrew configuration module`
  - Files: `modules/base/homebrew.nix`
  - Pre-commit: Syntax validation

---

- [x] 7. Migrate darwin services (ollama, open-webui, monitoring, smb-mount)

  **What to do**:
  - Move `modules/darwin/services/*.nix` to `modules/services/*.nix`
  - Wrap existing module code in flake-parts darwin aspect
  - Keep NixOS aspects empty or as stubs for future

  **Must NOT do**:
  - Do not change any service configuration options
  - Do not add NixOS implementations

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Module restructuring
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Task 8)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 2, 3

  **References**:

  **Source Files**:
  - `modules/darwin/services/ollama.nix` (72 lines)
  - `modules/darwin/services/open-webui.nix` (183 lines)
  - `modules/darwin/services/monitoring.nix` (98 lines)
  - `modules/darwin/services/smb-mount.nix` (147 lines)

  **Target Structure**:
  ```nix
  # modules/services/ollama.nix
  { inputs, ... }:
  {
    flake.modules.darwin.ollama = { pkgs, config, lib, ... }: {
      # ... existing ollama.nix content ...
    };
    
    # NixOS stub for future
    flake.modules.nixos.ollama = { ... }: {
      # TODO: Implement NixOS equivalent
    };
  }
  ```

  **Acceptance Criteria**:
  - [ ] `modules/services/ollama.nix` exists with darwin aspect
  - [ ] `modules/services/open-webui.nix` exists with darwin aspect
  - [ ] `modules/services/monitoring.nix` exists with darwin aspect
  - [ ] `modules/services/smb-mount.nix` exists with darwin aspect
  - [ ] All options and configurations preserved exactly

  **Commit**: YES
  - Message: `feat(modules): migrate darwin services to dendritic structure`
  - Files: `modules/services/*.nix`
  - Pre-commit: Syntax validation

---

- [x] 8. Migrate desktop features (gnome, gaming)

  **What to do**:
  - Create `modules/desktop/gnome.nix` with NixOS aspect (from gnarbox.nix)
  - Create `modules/desktop/gaming.nix` with NixOS aspect (steam, proton, gamemode)
  - Create `modules/desktop/audio.nix` with NixOS aspect (pipewire)

  **Must NOT do**:
  - Do not add Darwin aspects (these are NixOS-only)
  - Do not change any settings

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Code extraction and restructuring
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Task 7)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 2, 3

  **References**:

  **Pattern References**:
  - `gnarbox.nix:81-116` - X11, GDM, GNOME configuration
  - `gnarbox.nix:121-128` - PipeWire audio
  - `gnarbox.nix:131-134` - Graphics
  - `gnarbox.nix:161-174` - Steam configuration

  **Acceptance Criteria**:
  - [ ] `modules/desktop/gnome.nix` exists with nixos aspect
  - [ ] `modules/desktop/gaming.nix` exists with nixos aspect
  - [ ] `modules/desktop/audio.nix` exists with nixos aspect
  - [ ] All settings from gnarbox.nix preserved

  **Commit**: YES
  - Message: `feat(modules): add desktop features (gnome, gaming, audio)`
  - Files: `modules/desktop/*.nix`
  - Pre-commit: Syntax validation

---

### Phase 3: Host and Dev-env Integration

- [x] 9. Migrate host configurations to dendritic structure

  **What to do**:
  - Create `modules/hosts/mbp.nix` that imports base, dev features
  - Create `modules/hosts/a6mbp.nix` with work-specific additions
  - Create `modules/hosts/studio.nix` with service imports
  - Create `modules/hosts/gnarbox.nix` with desktop imports
  - Each host imports relevant feature modules

  **Must NOT do**:
  - Do not delete original hosts/ files yet
  - Do not change any host-specific settings

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Complex integration of multiple features
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Task 10)
  - **Blocks**: Task 11
  - **Blocked By**: Tasks 4, 5, 6, 7, 8

  **References**:

  **Source Files**:
  - `hosts/darwin-common.nix` - Base for all Darwin
  - `hosts/mbp.nix` - Personal MacBook
  - `hosts/a6mbp.nix` - Work MacBook
  - `hosts/studio.nix` - Media server
  - `hosts/gnarbox.nix` - NixOS desktop

  **Import Pattern**:
  ```nix
  # modules/hosts/mbp.nix
  { inputs, ... }:
  {
    flake.modules.darwin.mbp = { ... }: {
      imports = with inputs.self.modules.darwin; [
        fonts
        nix-settings
        zsh
        homebrew
        editors
        git
        cli-tools
      ];
      
      # Host-specific additions
      homebrew.casks = [ "bambu-studio" "steam" /* etc */ ];
    };
  }
  ```

  **Acceptance Criteria**:
  - [ ] `modules/hosts/mbp.nix` exists and imports relevant features
  - [ ] `modules/hosts/a6mbp.nix` exists and imports relevant features
  - [ ] `modules/hosts/studio.nix` exists and imports services
  - [ ] `modules/hosts/gnarbox.nix` exists and imports desktop features
  - [ ] No duplicate code between host modules

  **Commit**: YES
  - Message: `feat(modules): migrate host configurations to dendritic structure`
  - Files: `modules/hosts/*.nix`
  - Pre-commit: Syntax validation

---

- [x] 10. Integrate dev-envs into modules/

  **What to do**:
  - Move dev-envs/*.nix to modules/dev-envs/*.nix
  - Keep dev-envs/lib.nix as modules/dev-envs/lib.nix
  - Wrap each in flake-parts perSystem structure

  **Must NOT do**:
  - Do not change any dev environment configurations
  - Do not add new dev environments

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: File movement and wrapper addition
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Task 9)
  - **Blocks**: Task 11
  - **Blocked By**: Tasks 2, 3

  **References**:

  **Source Files**:
  - `dev-envs/lib.nix` - Shared utilities
  - `dev-envs/vets-website.nix`
  - `dev-envs/vets-api.nix`
  - `dev-envs/next-build.nix`
  - `dev-envs/component-library.nix`
  - `dev-envs/content-build.nix`

  **perSystem Pattern**:
  ```nix
  # modules/dev-envs/vets-website.nix
  { inputs, ... }:
  {
    perSystem = { pkgs, ... }: {
      devShells.vets-website = import ./vets-website-shell.nix { inherit pkgs; };
    };
  }
  ```

  **Acceptance Criteria**:
  - [ ] `modules/dev-envs/lib.nix` exists
  - [ ] `modules/dev-envs/vets-website.nix` exists
  - [ ] `modules/dev-envs/vets-api.nix` exists
  - [ ] `modules/dev-envs/next-build.nix` exists
  - [ ] `modules/dev-envs/component-library.nix` exists
  - [ ] `modules/dev-envs/content-build.nix` exists

  **Commit**: YES
  - Message: `feat(modules): integrate dev-envs into dendritic structure`
  - Files: `modules/dev-envs/*.nix`
  - Pre-commit: Syntax validation

---

### Phase 4: Final Integration

- [ ] 11. Update flake.nix to use new module structure

  **What to do**:
  - Replace flake.nix outputs with flake-parts mkFlake
  - Use import-tree to auto-import modules/
  - Wire up darwinConfigurations, nixosConfigurations, devShells
  - Preserve specialArgs for gnarbox (inputs, outputs, meta)
  - Keep overlays export

  **Must NOT do**:
  - Do not change any outputs behavior
  - Do not remove backwards compatibility

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: Complex flake restructuring with many moving parts
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (critical path)
  - **Parallel Group**: Wave 6 (solo)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 9, 10

  **References**:

  **flake-parts Pattern**:
  ```nix
  {
    inputs = { /* ... */ };
    
    outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = inputs.import-tree ./modules;
      
      systems = [ "aarch64-darwin" "x86_64-linux" ];
      
      flake = {
        overlays = import ./overlays { inherit inputs; };
        
        darwinConfigurations.mbp = inputs.nix-darwin.lib.darwinSystem {
          modules = [ inputs.self.modules.darwin.mbp ];
        };
        # ... etc
      };
    };
  }
  ```

  **Critical: specialArgs for gnarbox**:
  ```nix
  nixosConfigurations.gnarbox = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      outputs = inputs.self;
      meta = { hostname = "gnarbox"; };
    };
    modules = [ inputs.self.modules.nixos.gnarbox ];
  };
  ```

  **Acceptance Criteria**:
  - [ ] `nix flake check` passes
  - [ ] `nix flake show` displays same outputs as before
  - [ ] `darwin-rebuild build --flake '.#mbp'` succeeds
  - [ ] `darwin-rebuild build --flake '.#a6mbp'` succeeds
  - [ ] `darwin-rebuild build --flake '.#studio'` succeeds
  - [ ] `nix build '.#nixosConfigurations.gnarbox.config.system.build.toplevel'` succeeds
  - [ ] All dev shells work on both platforms

  **Commit**: YES
  - Message: `feat: migrate flake.nix to flake-parts with dendritic modules`
  - Files: `flake.nix`
  - Pre-commit: Full verification suite

---

- [ ] 12. Cleanup old files and update README

  **What to do**:
  - Delete old `hosts/` directory (after verifying new structure works)
  - Delete old `dev-envs/` directory
  - Delete old `modules/darwin/` directory
  - Update README.md with new structure documentation
  - Create git tag: `v2.0.0-dendritic`

  **Must NOT do**:
  - Do not delete until ALL builds verified
  - Do not delete hardware-configs/gnarbox.nix (still needed)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Cleanup and documentation
  - **Skills**: [`git-master`]
    - `git-master`: Tag creation and clean commit

  **Parallelization**:
  - **Can Run In Parallel**: NO (final task)
  - **Parallel Group**: Wave 6 (after Task 11)
  - **Blocks**: None
  - **Blocked By**: Task 11

  **References**:

  **Files to Delete**:
  - `hosts/darwin-common.nix`
  - `hosts/mbp.nix`
  - `hosts/a6mbp.nix`
  - `hosts/studio.nix`
  - `hosts/gnarbox.nix`
  - `dev-envs/` entire directory
  - `modules/darwin/` entire directory

  **Files to Keep**:
  - `hosts/hardware-configs/gnarbox.nix` - Hardware-specific, still referenced

  **Acceptance Criteria**:
  - [ ] Old directories deleted
  - [ ] `hosts/hardware-configs/gnarbox.nix` still exists
  - [ ] README.md updated with new structure
  - [ ] Git tag `v2.0.0-dendritic` created
  - [ ] All builds still pass after cleanup

  **Commit**: YES
  - Message: `chore: cleanup old structure after dendritic migration`
  - Files: Deleted files, README.md
  - Pre-commit: Full verification suite

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `chore: remove cursor package references` | flake.nix, a6mbp.nix, README.md, pkgs/cursor/ | All hosts build |
| 2 | `feat: add flake-parts and import-tree inputs` | flake.nix, flake.lock | nix flake check |
| 3 | `feat: create dendritic modules directory structure` | modules/ dirs | None |
| 4 | `feat(modules): add base features` | modules/base/*.nix | Syntax valid |
| 5 | `feat(modules): add dev features` | modules/dev/*.nix | Syntax valid |
| 6 | `feat(modules): add homebrew configuration` | modules/base/homebrew.nix | Syntax valid |
| 7 | `feat(modules): migrate darwin services` | modules/services/*.nix | Syntax valid |
| 8 | `feat(modules): add desktop features` | modules/desktop/*.nix | Syntax valid |
| 9 | `feat(modules): migrate host configurations` | modules/hosts/*.nix | Syntax valid |
| 10 | `feat(modules): integrate dev-envs` | modules/dev-envs/*.nix | Syntax valid |
| 11 | `feat: migrate flake.nix to flake-parts` | flake.nix | FULL SUITE |
| 12 | `chore: cleanup old structure` | hosts/, dev-envs/, modules/darwin/ | FULL SUITE |

---

## Success Criteria

### Verification Commands
```bash
# After Task 1 (cursor cleanup)
nix flake check
darwin-rebuild build --flake '.#mbp'

# After Task 11 (full migration)
nix flake check
nix flake show
darwin-rebuild build --flake '.#mbp'
darwin-rebuild build --flake '.#a6mbp'
darwin-rebuild build --flake '.#studio'
nix build '.#nixosConfigurations.gnarbox.config.system.build.toplevel'
nix build '.#devShells.aarch64-darwin.vets-website' --dry-run
nix build '.#devShells.x86_64-linux.vets-website' --dry-run
```

### Final Checklist
- [ ] All cursor references removed
- [ ] flake.nix uses flake-parts
- [ ] All modules in modules/ directory
- [ ] All 4 hosts build successfully
- [ ] All 5 dev-envs work on both platforms
- [ ] Git tagged v2.0.0-dendritic
- [ ] README.md updated
