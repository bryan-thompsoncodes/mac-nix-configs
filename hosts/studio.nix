{ pkgs, ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "cloudflared"
      "node"  # Includes npm and npx for MCP extensions
      "ollama"
    ];
    # Additional casks for this host
    casks = [
      "zen"
    ];
  };

  # Ollama service configuration
  launchd.user.agents.ollama = {
    serviceConfig = {
      ProgramArguments = [ "/opt/homebrew/bin/ollama" "serve" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.error.log";
      EnvironmentVariables = {
        OLLAMA_HOST = "0.0.0.0:11434";
        OLLAMA_ORIGINS = "*";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };
    };
  };

  # Open firewall port for Ollama
  system.activationScripts.postActivation.text = ''
    # Open port 11434 for Ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/ollama
  '';
}
