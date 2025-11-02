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
      "prometheus"
      "grafana"
      "python@3.11"  # For Open WebUI
    ];
    # Additional casks for this host
    casks = [
      "zen"
    ];
  };

  # === AI/LLM Services ===

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
        OLLAMA_KEEP_ALIVE = "0";
      };
    };
  };

  # Open WebUI service configuration (pip-based)
  launchd.user.agents.open-webui = {
    path = [ "/Users/bryan/Library/Python/3.11/bin" ];
    serviceConfig = {
      ProgramArguments = [
        "/Users/bryan/Library/Python/3.11/bin/open-webui"
        "serve"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/open-webui.log";
      StandardErrorPath = "/tmp/open-webui.error.log";
      WorkingDirectory = "/Users/bryan/.open-webui";
      EnvironmentVariables = {
        PORT = "8080";
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "false";
        DATA_DIR = "/Users/bryan/.open-webui/data";
        HOME = "/Users/bryan";
      };
    };
  };

  # === Monitoring Services ===

  # Prometheus service configuration
  launchd.user.agents.prometheus = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/opt/prometheus/bin/prometheus"
        "--config.file=/opt/homebrew/etc/prometheus.yml"
        "--web.listen-address=0.0.0.0:9090"
        "--storage.tsdb.path=/tmp/prometheus"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/prometheus.log";
      StandardErrorPath = "/tmp/prometheus.error.log";
    };
  };

  # Grafana service configuration
  launchd.user.agents.grafana = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/opt/grafana/bin/grafana"
        "server"
        "--homepath=/opt/homebrew/opt/grafana/share/grafana"
        "--config=/opt/homebrew/etc/grafana/grafana.ini"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/grafana.log";
      StandardErrorPath = "/tmp/grafana.error.log";
      EnvironmentVariables = {
        GF_SERVER_HTTP_ADDR = "0.0.0.0";
        GF_SERVER_HTTP_PORT = "3000";
      };
    };
  };

  # === Activation Scripts ===

  # Install Open WebUI via pip
  system.activationScripts.install-open-webui.text = ''
    # Check if Python 3.11 is available
    if [ -f /opt/homebrew/bin/pip3.11 ]; then
      echo "Installing/updating Open WebUI via pip..."
      /opt/homebrew/bin/pip3.11 install --user --upgrade open-webui
      echo "Open WebUI installed/updated successfully"

      # Create data directory for Open WebUI
      mkdir -p /Users/bryan/.open-webui/data
      chown bryan:staff /Users/bryan/.open-webui/data
      echo "Open WebUI data directory created"
    else
      echo "Python 3.11 not yet installed, skipping Open WebUI setup"
    fi
  '';

  # Firewall setup for services
  system.activationScripts.firewall.text = ''
    # Open port 11434 for Ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/ollama
    # Open port 9090 for Prometheus
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/prometheus/bin/prometheus
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/prometheus/bin/prometheus
    # Open port 3000 for Grafana
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/grafana/bin/grafana
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/grafana/bin/grafana
    # Open port 8080 for Open WebUI
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/python3.11
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/python3.11
  '';
}
