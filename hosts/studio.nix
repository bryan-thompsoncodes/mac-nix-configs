{ ... }:

{
  imports = [
    ./darwin-common.nix
    ../modules/darwin/services/ollama.nix
    ../modules/darwin/services/open-webui.nix
    ../modules/darwin/services/monitoring.nix
    ../modules/darwin/services/smb-mount.nix
  ];

  # === Enable Services ===

  services.ollama.enable = true;
  services.open-webui.enable = true;
  services.monitoring.enable = true;
  services.smb-mount.enable = true;

  # === Host-specific Homebrew ===

  homebrew = {
    brews = [
      "cloudflared"
      "node" # Includes npm and npx for MCP extensions
      "ollama"
      "prometheus"
      "grafana"
      "python@3.11" # For Open WebUI
    ];
    casks = [
      "zen"
    ];
  };
}
