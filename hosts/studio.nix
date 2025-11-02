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
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };
    };
  };

  # Prometheus service configuration
  launchd.user.agents.prometheus = {
    serviceConfig = {
      ProgramArguments = [ "/opt/homebrew/opt/prometheus/bin/prometheus" "--config.file=/tmp/prometheus.yml" "--web.listen-address=0.0.0.0:9090" "--storage.tsdb.path=/tmp/prometheus" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/prometheus.log";
      StandardErrorPath = "/tmp/prometheus.error.log";
    };
  };

  # Grafana service configuration
  launchd.user.agents.grafana = {
    serviceConfig = {
      ProgramArguments = [ "/opt/homebrew/opt/grafana/bin/grafana" "server" "--homepath=/opt/homebrew/opt/grafana/share/grafana" "--config=/opt/homebrew/etc/grafana/grafana.ini" ];
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

  # Service management and firewall setup
  system.activationScripts.postActivation.text = ''
    # Open port 11434 for Ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/ollama
    # Open port 9090 for Prometheus
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/prometheus/bin/prometheus
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/prometheus/bin/prometheus
    # Open port 3000 for Grafana
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/grafana/bin/grafana
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/grafana/bin/grafana
    # Create Prometheus config file
    cat > /tmp/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
    - targets: ["localhost:9090"]
  - job_name: "grafana"
    static_configs:
    - targets: ["localhost:3000"]
    metrics_path: "/api/metrics"
    scrape_interval: 30s
EOF
    # Ensure services are properly restarted with new configuration
    # Kill any existing Prometheus processes to force reload with new config
    pkill -f "prometheus" 2>/dev/null || true
    sleep 2
  '';
}
