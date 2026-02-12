# Services Module

Darwin launchd services with NixOS stubs. Each service follows a consistent pattern.

## Pattern

Every service module defines **both** platform aspects:

```nix
{ inputs, ... }: {
  flake.modules.darwin.{name} = { config, lib, ... }: {
    options.services.{name} = {
      enable = lib.mkEnableOption "{description}";
      # Additional options with lib.mkOption...
    };
    config = lib.mkIf cfg.enable {
      launchd.user.agents.{name} = {
        serviceConfig = {
          ProgramArguments = [ "/opt/homebrew/bin/{tool}" ... ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/{name}.log";
          StandardErrorPath = "/tmp/{name}.error.log";
        };
      };
      # Firewall rules via activationScripts
      system.activationScripts.{name}-firewall.text = ''...'';
    };
  };
  flake.modules.nixos.{name} = { ... }: {
    # Stub or native NixOS module usage
  };
}
```

## Services

| Service | Port(s) | Binary | Scheduling | Notes |
|---------|---------|--------|------------|-------|
| ollama | 11434 | `/opt/homebrew/bin/ollama` | Always-on | Flash attention, q8_0 KV cache |
| open-webui | 8080 | pip-installed `open-webui` | Always-on + daily updater | 2 agents: main + auto-updater |
| monitoring | 9090, 3000 | prometheus, grafana | Always-on | Binds 0.0.0.0; 2 agents |
| syncthing | 8384, 22000 | `/opt/homebrew/bin/syncthing` | Always-on | NixOS uses native module directly |
| smb-mount | — | mount_smbfs | Event-driven (WatchPaths) | Soft mount, no polling |
| icloud-backup | — | /usr/bin/rsync | Calendar (2:00 AM) | Excludes .stversions/.syncthing* |

## Where Enabled

Services are enabled per-host in `modules/hosts/{host}.nix`:
```nix
imports = [ ... syncthing ... ];
services.syncthing.enable = true;
```

Only **studio** enables the full stack (ollama, open-webui, monitoring, smb-mount, icloud-backup).
All darwin hosts enable **syncthing**.

## Scheduling Patterns

Three launchd scheduling modes used (match existing when adding):

| Mode | Config | Used By |
|------|--------|---------|
| Always-on daemon | `RunAtLoad=true` + `KeepAlive=true` | ollama, open-webui, syncthing, monitoring |
| Event-driven one-shot | `RunAtLoad=true` + `KeepAlive=false` + `WatchPaths` | smb-mount |
| Calendar-scheduled | `StartCalendarInterval` only | icloud-backup |

## Anti-Patterns

- **NEVER** use Nix store paths for ProgramArguments — Homebrew binaries at `/opt/homebrew/bin/`
- **ALWAYS** add firewall rules via `system.activationScripts.{name}-firewall.text`
- **ALWAYS** include both darwin and nixos aspects (even if nixos is a stub)
- **ALWAYS** log to `/tmp/{name}.log` and `/tmp/{name}.error.log`
- NixOS stubs marked `# TODO` are intentional — use native NixOS modules when implementing
- open-webui depends implicitly on ollama via `ollamaUrl` default — no hard dependency declared
