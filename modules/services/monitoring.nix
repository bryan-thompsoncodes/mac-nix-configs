# Monitoring stack service (Prometheus + Grafana + node_exporter + Loki + Promtail + blackbox_exporter)
#
# Provides metrics collection, log aggregation, and visualization. Grafana, node_exporter,
# Loki, and Promtail use Homebrew. Prometheus and blackbox_exporter use nixpkgs derivations
# (Homebrew Prometheus builds with netgo which breaks multi-interface routing on macOS).
# All services bind to 0.0.0.0 for network access.
# Configuration is fully declarative: prometheus.yml, Loki config, and Grafana provisioning
# are generated from Nix attrsets.
{ inputs, ... }:
{
  # Darwin aspect - full configuration from modules/darwin/services/monitoring.nix
  flake.modules.darwin.monitoring = { pkgs, config, lib, ... }:
  let
    cfg = config.services.monitoring;
    homeDir = "/Users/${config.system.primaryUser}";

    # Grafana custom config — overrides Homebrew defaults.ini
    # Only contains settings not handled by GF_* environment variables
    grafanaCustomIni = pkgs.writeText "grafana-custom.ini" ''
      [smtp]
      user = snowboardtechie.com
      password = $__file{${homeDir}/.secrets/grafana-smtp-password}
    '';

    # Prometheus alerting rules
    alertRulesFile = pkgs.writeText "alert-rules.yml" (builtins.toJSON {
      groups = [{
        name = "service-health";
        rules = [
          {
            alert = "ServiceDown";
            expr = "probe_success == 0";
            "for" = "5m";
            labels = { severity = "critical"; };
            annotations = {
              summary = "Service {{ $labels.instance }} is down";
              description = "{{ $labels.instance }} has been unreachable for more than 5 minutes.";
            };
          }
          {
            alert = "HighCpuUsage";
            expr = "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 85";
            "for" = "10m";
            labels = { severity = "warning"; };
            annotations = {
              summary = "High CPU usage on {{ $labels.instance }}";
              description = "CPU usage has been above 85% for more than 10 minutes.";
            };
          }
          {
            alert = "HighMemoryUsage";
            expr = "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 90";
            "for" = "10m";
            labels = { severity = "warning"; };
            annotations = {
              summary = "High memory usage on {{ $labels.instance }}";
              description = "Memory usage has been above 90% for more than 10 minutes.";
            };
          }
          {
            alert = "HighDiskUsage";
            expr = "(1 - node_filesystem_avail_bytes{fstype!~\"tmpfs|devtmpfs|overlay\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|devtmpfs|overlay\"}) * 100 > 85";
            "for" = "15m";
            labels = { severity = "warning"; };
            annotations = {
              summary = "Disk usage above 85% on {{ $labels.instance }}";
              description = "{{ $labels.mountpoint }} is {{ $value | printf \"%.1f\" }}% full.";
            };
          }
          {
            alert = "PrometheusTargetDown";
            expr = "up == 0";
            "for" = "5m";
            labels = { severity = "critical"; };
            annotations = {
              summary = "Prometheus target {{ $labels.job }} is down";
              description = "{{ $labels.instance }} (job {{ $labels.job }}) has been down for 5 minutes.";
            };
          }
        ];
      }];
    });

    # Declarative prometheus.yml generated from Nix attrset
    prometheusConfigFile = pkgs.writeText "prometheus.yml" (builtins.toJSON {
      global = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };
      rule_files = [ "${alertRulesFile}" ];
      scrape_configs = [
        {
          job_name = "prometheus";
          static_configs = [{ targets = [ "localhost:${toString cfg.prometheus.port}" ]; }];
        }
        {
          job_name = "grafana";
          static_configs = [{ targets = [ "localhost:${toString cfg.grafana.port}" ]; }];
        }
        {
          job_name = "node_exporter";
          static_configs = [{ targets = [ "localhost:${toString cfg.nodeExporter.port}" ]; }];
        }
        {
          job_name = "loki";
          static_configs = [{ targets = [ "localhost:${toString cfg.loki.port}" ]; }];
        }
        {
          job_name = "blackbox";
          metrics_path = "/probe";
          params = { module = ["http_2xx"]; };
          static_configs = [{ targets = cfg.blackbox.targets; }];
          relabel_configs = [
            {
              source_labels = ["__address__"];
              target_label = "__param_target";
            }
            {
              source_labels = ["__param_target"];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:${toString cfg.blackbox.port}";
            }
          ];
        }
        {
          job_name = "blackbox_exporter";
          static_configs = [{ targets = [ "127.0.0.1:${toString cfg.blackbox.port}" ]; }];
        }
      ] ++ cfg.extraScrapeConfigs;
    });

    # Grafana dashboard JSON directory (separate to avoid circular ref)
    dashboardJsonDir = pkgs.runCommand "grafana-dashboards" {} ''
      mkdir -p $out
      cp ${./grafana/dashboards/node-exporter-macos.json} $out/node-exporter-macos.json
      cp ${./grafana/dashboards/service-health.json} $out/service-health.json
      cp ${./grafana/dashboards/unraid.json} $out/unraid.json
      cp ${./grafana/dashboards/studio-logs.json} $out/studio-logs.json
    '';

    # Grafana datasource config (Prometheus + Loki)
    datasourceConfig = pkgs.writeText "datasources.yml" (builtins.toJSON {
      apiVersion = 1;
      deleteDatasources = [
        { name = "Prometheus"; orgId = 1; }
        { name = "Loki"; orgId = 1; }
      ];
      datasources = [
        {
          name = "Prometheus";
          uid = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString cfg.prometheus.port}";
          isDefault = true;
          editable = false;
        }
        {
          name = "Loki";
          uid = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:${toString cfg.loki.port}";
          editable = false;
        }
      ];
    });

    # Grafana dashboard provider config
    dashboardProviderConfig = pkgs.writeText "dashboard-provider.yml" (builtins.toJSON {
      apiVersion = 1;
      providers = [{
        name = "default";
        orgId = 1;
        folder = "";
        type = "file";
        disableDeletion = true;
        editable = false;
        options = {
          path = "${dashboardJsonDir}";
          foldersFromFilesStructure = false;
        };
      }];
    });

    # Loki configuration
    lokiConfigFile = pkgs.writeText "loki-local-config.yaml" (builtins.toJSON {
      auth_enabled = false;
      server = {
        http_listen_port = cfg.loki.port;
      };
      common = {
        path_prefix = cfg.loki.storagePath;
        storage = {
          filesystem = {
            chunks_directory = "${cfg.loki.storagePath}/chunks";
            rules_directory = "${cfg.loki.storagePath}/rules";
          };
        };
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
      };
      schema_config = {
        configs = [{
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };
      limits_config = {
        retention_period = "720h";
      };
      compactor = {
        working_directory = "${cfg.loki.storagePath}/compactor";
        delete_request_store = "filesystem";
        retention_enabled = true;
      };
    });

    # Promtail configuration
    promtailConfigFile = pkgs.writeText "promtail-config.yaml" (builtins.toJSON {
      server = {
        http_listen_port = cfg.promtail.port;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "${homeDir}/.promtail/positions.yaml";
      };
      clients = [{
        url = "http://localhost:${toString cfg.loki.port}/loki/api/v1/push";
      }];
      scrape_configs = [
        {
          job_name = "service-logs";
          static_configs = [{
            targets = ["localhost"];
            labels = {
              host = "studio";
              __path__ = "/tmp/*.log";
            };
          }];
        }
        {
          job_name = "syslog";
          syslog = {
            listen_address = "0.0.0.0:1514";
            listen_protocol = "udp";
            syslog_format = "rfc3164";
            labels = {
              host = "unraid";
            };
          };
          relabel_configs = [{
            source_labels = ["__syslog_message_hostname"];
            target_label = "hostname";
          }];
        }
      ];
    });

    # Blackbox exporter configuration
    blackboxConfigFile = pkgs.writeText "blackbox.yml" (builtins.toJSON {
      modules = {
        http_2xx = {
          prober = "http";
          timeout = "5s";
          http = {
            preferred_ip_protocol = "ip4";
            valid_status_codes = [];
          };
        };
      };
    });

    # Grafana provisioning directory (assembled from configs above)
    grafanaProvisioning = pkgs.runCommand "grafana-provisioning" {} ''
      mkdir -p $out/datasources $out/dashboards
      cp ${datasourceConfig} $out/datasources/prometheus.yml
      cp ${dashboardProviderConfig} $out/dashboards/default.yml
    '';
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

        storagePath = lib.mkOption {
          type = lib.types.str;
          default = "${homeDir}/.prometheus/data";
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

        dataPath = lib.mkOption {
          type = lib.types.str;
          default = "${homeDir}/.grafana/data";
          description = "Path for Grafana data (DB, plugins). Kept outside Homebrew Cellar to survive brew upgrades.";
        };
      };

      nodeExporter = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 9100;
          description = "Port for node_exporter metrics endpoint";
        };
      };

      loki = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 3100;
          description = "Port for Loki HTTP API";
        };
        storagePath = lib.mkOption {
          type = lib.types.str;
          default = "${homeDir}/.loki/data";
          description = "Path for Loki data storage";
        };
      };

      promtail = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 9080;
          description = "Port for Promtail HTTP server";
        };
      };

      blackbox = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 9115;
          description = "Port for blackbox_exporter";
        };
        targets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "http://localhost:11434/api/tags"   # Ollama
            "http://localhost:8080/health"       # Open-WebUI
            "http://localhost:32400/web/index.html"  # Plex
          ];
          description = "HTTP endpoints to probe for service health";
        };
      };

      extraScrapeConfigs = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [];
        description = "Additional Prometheus scrape configurations for remote targets";
      };
    };

    config = lib.mkIf cfg.enable {
      # Ensure storage directories exist
      system.activationScripts.monitoring-setup.text = ''
        mkdir -p "${cfg.prometheus.storagePath}"
        mkdir -p "${cfg.grafana.dataPath}"
        mkdir -p "${cfg.loki.storagePath}"
        mkdir -p "${homeDir}/.promtail"
      '';

      # Prometheus service configuration
      launchd.user.agents.prometheus = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.prometheus}/bin/prometheus"
            "--config.file=${prometheusConfigFile}"
            "--web.listen-address=0.0.0.0:${toString cfg.prometheus.port}"
            "--storage.tsdb.path=${cfg.prometheus.storagePath}"
            "--storage.tsdb.retention.time=30d"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/prometheus.log";
          StandardErrorPath = "/tmp/prometheus.error.log";
        };
      };

      # Grafana service configuration
      # SMTP password: read via $__file{} in grafanaCustomIni from ~/.secrets/grafana-smtp-password
      # Create the secrets file: echo '<password>' > ~/.secrets/grafana-smtp-password && chmod 600 ~/.secrets/grafana-smtp-password
      launchd.user.agents.grafana = {
        serviceConfig = {
          ProgramArguments = [
            "/opt/homebrew/opt/grafana/bin/grafana"
            "server"
            "--homepath=/opt/homebrew/opt/grafana/share/grafana"
            "--config=${grafanaCustomIni}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/grafana.log";
          StandardErrorPath = "/tmp/grafana.error.log";
          EnvironmentVariables = {
            GF_SERVER_HTTP_ADDR = "0.0.0.0";
            GF_SERVER_HTTP_PORT = toString cfg.grafana.port;
            GF_PATHS_PROVISIONING = "${grafanaProvisioning}";
            GF_PATHS_DATA = cfg.grafana.dataPath;
            GF_SMTP_ENABLED = "true";
            GF_SMTP_HOST = "mail.smtp2go.com:2525";
            GF_SMTP_FROM_ADDRESS = "grafana@snowboardtechie.com";
            GF_SMTP_FROM_NAME = "Studio Grafana";
          };
        };
      };

      # node_exporter service configuration
      launchd.user.agents.node-exporter = {
        serviceConfig = {
          ProgramArguments = [
            "/opt/homebrew/opt/node_exporter/bin/node_exporter"
            "--web.listen-address=0.0.0.0:${toString cfg.nodeExporter.port}"
            "--no-collector.thermal"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/node_exporter.log";
          StandardErrorPath = "/tmp/node_exporter.error.log";
        };
      };

      # Loki service configuration
      launchd.user.agents.loki = {
        serviceConfig = {
          ProgramArguments = [
            "/opt/homebrew/opt/loki/bin/loki"
            "-config.file=${lokiConfigFile}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/loki.log";
          StandardErrorPath = "/tmp/loki.error.log";
        };
      };

      # Promtail service configuration
      launchd.user.agents.promtail = {
        serviceConfig = {
          ProgramArguments = [
            "/bin/sh" "-c"
            "mkdir -p ${homeDir}/.promtail && exec /opt/homebrew/opt/promtail/bin/promtail -config.file=${promtailConfigFile}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/promtail.log";
          StandardErrorPath = "/tmp/promtail.error.log";
        };
      };

      # blackbox_exporter service configuration
      launchd.user.agents.blackbox-exporter = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.prometheus-blackbox-exporter}/bin/blackbox_exporter"
            "--config.file=${blackboxConfigFile}"
            "--web.listen-address=0.0.0.0:${toString cfg.blackbox.port}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/blackbox_exporter.log";
          StandardErrorPath = "/tmp/blackbox_exporter.error.log";
        };
      };

      # Firewall rules for monitoring services
      system.activationScripts.monitoring-firewall.text = ''
        # Prometheus
        /usr/libexec/ApplicationFirewall/socketfilterfw --add ${pkgs.prometheus}/bin/prometheus >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock ${pkgs.prometheus}/bin/prometheus >/dev/null 2>&1 || true
        # Grafana
        /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/grafana/bin/grafana >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/grafana/bin/grafana >/dev/null 2>&1 || true
        # Node Exporter
        /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/node_exporter/bin/node_exporter >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/node_exporter/bin/node_exporter >/dev/null 2>&1 || true
        # Loki
        /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/loki/bin/loki >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/loki/bin/loki >/dev/null 2>&1 || true
        # Promtail
        /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/opt/promtail/bin/promtail >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/opt/promtail/bin/promtail >/dev/null 2>&1 || true
        # Blackbox Exporter
        /usr/libexec/ApplicationFirewall/socketfilterfw --add ${pkgs.prometheus-blackbox-exporter}/bin/blackbox_exporter >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock ${pkgs.prometheus-blackbox-exporter}/bin/blackbox_exporter >/dev/null 2>&1 || true
      '';
    };
  };

  # NixOS aspect - stub for future implementation
  flake.modules.nixos.monitoring = { config, lib, ... }: {
    # TODO: Implement NixOS equivalent using systemd services
    # NixOS has native prometheus and grafana service modules
  };
}
