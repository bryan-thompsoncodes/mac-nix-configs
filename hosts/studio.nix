{ pkgs, ... }:

{
  imports = [
    ./darwin-common.nix
  ];

  # Allow broken and unfree packages for open-webui
  nixpkgs.config = {
    allowBroken = true;
    allowUnfree = true;
  };

  # Add ollama and open-webui to system packages
  environment.systemPackages = with pkgs; [
    ollama
    open-webui
  ];

  # LaunchAgent for ollama service (macOS equivalent of systemd service)
  launchd.user.agents.ollama = {
    serviceConfig = {
      ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.error.log";
      EnvironmentVariables = {
        OLLAMA_HOST = "0.0.0.0";
        OLLAMA_PORT = "11434";
        OLLAMA_GPU = "1";  # Enable GPU acceleration (Metal on Apple Silicon)
      };
    };
  };

  # LaunchAgent for open-webui service with proper data directory
  launchd.user.agents.open-webui = {
    serviceConfig = {
      ProgramArguments = [ "${pkgs.open-webui}/bin/open-webui" "serve" "--host" "0.0.0.0" "--port" "8080" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/open-webui.log";
      StandardErrorPath = "/tmp/open-webui.error.log";
      EnvironmentVariables = {
        DATA_DIR = "/Users/bryan/.open-webui";
        STATIC_DIR = "/Users/bryan/.open-webui/static";
        WEBUI_SECRET_KEY = "nix-configs-open-webui-secret-key-change-me";
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      };
    };
  };

  

  # Host-specific Homebrew configuration
  homebrew = {
    # Additional brews
    brews = [
      "block-goose-cli"
      "node"  # Includes npm and npx for MCP extensions
    ];
    # Additional casks for this host
    casks = [
      "block-goose"
      "zen"
    ];
  };
}