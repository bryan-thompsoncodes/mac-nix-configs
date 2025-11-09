{ pkgs, config, ... }:

{
  # Homebrew packages for monitoring services
  homebrew.brews = [
    "prometheus"
    "grafana"
  ];

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

  # Firewall setup for monitoring services
  system.activationScripts.firewall.text = ''
    # Open port 9090 for Prometheus
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/prometheus/bin/prometheus
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/prometheus/bin/prometheus
    # Open port 3000 for Grafana
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/grafana/bin/grafana
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/grafana/bin/grafana
  '';
}

