# Monitoring stack service for macOS (Prometheus + Grafana)
#
# Provides metrics collection and visualization via Homebrew-installed
# Prometheus and Grafana. Both services bind to 0.0.0.0 for network access.
{ config, lib, ... }:

let
  cfg = config.services.monitoring;
in
{
  options.services.monitoring = {
    enable = lib.mkEnableOption "Prometheus and Grafana monitoring stack";

    prometheus = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 9090;
        description = "Port for Prometheus web interface";
      };

      configFile = lib.mkOption {
        type = lib.types.str;
        default = "/opt/homebrew/etc/prometheus.yml";
        description = "Path to Prometheus configuration file";
      };

      storagePath = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/prometheus";
        description = "Path for Prometheus TSDB storage";
      };
    };

    grafana = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Port for Grafana web interface";
      };

      configFile = lib.mkOption {
        type = lib.types.str;
        default = "/opt/homebrew/etc/grafana/grafana.ini";
        description = "Path to Grafana configuration file";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Prometheus service configuration
    launchd.user.agents.prometheus = {
      serviceConfig = {
        ProgramArguments = [
          "/opt/homebrew/opt/prometheus/bin/prometheus"
          "--config.file=${cfg.prometheus.configFile}"
          "--web.listen-address=0.0.0.0:${toString cfg.prometheus.port}"
          "--storage.tsdb.path=${cfg.prometheus.storagePath}"
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
          "--config=${cfg.grafana.configFile}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/grafana.log";
        StandardErrorPath = "/tmp/grafana.error.log";
        EnvironmentVariables = {
          GF_SERVER_HTTP_ADDR = "0.0.0.0";
          GF_SERVER_HTTP_PORT = toString cfg.grafana.port;
        };
      };
    };

    # Firewall rules for monitoring services
    system.activationScripts.monitoring-firewall.text = ''
      # Prometheus
      /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/prometheus/bin/prometheus >/dev/null 2>&1 || true
      /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/prometheus/bin/prometheus >/dev/null 2>&1 || true
      # Grafana
      /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/grafana/bin/grafana >/dev/null 2>&1 || true
      /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/grafana/bin/grafana >/dev/null 2>&1 || true
    '';
  };
}

