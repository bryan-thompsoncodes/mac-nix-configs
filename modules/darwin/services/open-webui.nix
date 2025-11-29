# Open WebUI service for macOS (pip-based installation)
#
# Provides a web interface for LLM interaction. Uses pip3.11 for installation
# to track upstream releases immediately (Homebrew lags behind).
#
# Includes:
# - Main service runner (auto-installs if missing)
# - Daily update checker
# - Manual upgrade script in PATH
{ pkgs, config, lib, ... }:

let
  cfg = config.services.open-webui;
  homeDir = "/Users/${config.system.primaryUser}";
  pip3Path = "/opt/homebrew/bin/pip3.11";
  openWebUIBinary = "${homeDir}/Library/Python/3.11/bin/open-webui";

  # Manual upgrade script for Open WebUI
  upgrade-open-webui = pkgs.writeShellScriptBin "upgrade-open-webui" ''
    #!/bin/bash
    set -e

    echo "=== Open WebUI Manual Upgrade ==="
    echo ""

    # Check if Python 3.11 is available
    if [ ! -f ${pip3Path} ]; then
      echo "ERROR: Python 3.11 not found at ${pip3Path}"
      echo "Please install it with: brew install python@3.11"
      exit 1
    fi

    # Get current version
    CURRENT_VERSION=$(${pip3Path} show open-webui 2>/dev/null | grep Version | cut -d' ' -f2 || echo "not installed")
    echo "Current version: $CURRENT_VERSION"
    echo ""

    # Upgrade
    echo "Upgrading Open WebUI..."
    ${pip3Path} install --user --upgrade open-webui
    echo ""

    # Get new version
    NEW_VERSION=$(${pip3Path} show open-webui 2>/dev/null | grep Version | cut -d' ' -f2 || echo "unknown")
    echo "New version: $NEW_VERSION"
    echo ""

    if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
      echo "✓ Upgraded from $CURRENT_VERSION to $NEW_VERSION"
      echo ""
      echo "Restarting Open WebUI service..."
      launchctl kickstart -k "gui/$(id -u)/org.nixos.open-webui"
      echo "✓ Service restarted"
    else
      echo "Already at latest version ($NEW_VERSION)"
    fi

    echo ""
    echo "=== Upgrade Complete ==="
    echo "Open WebUI should now be running version $NEW_VERSION"
    echo "Access it at: http://localhost:${toString cfg.port}"
  '';

  # Runner script that auto-installs Open WebUI if missing
  openWebUIRunner = pkgs.writeShellScriptBin "run-open-webui" ''
    #!/bin/bash
    set -euo pipefail

    export HOME="${homeDir}"
    export PATH="/opt/homebrew/bin:$PATH"

    if [ ! -x "${pip3Path}" ]; then
      echo "ERROR: pip3.11 not found at ${pip3Path}"
      exit 1
    fi

    if [ ! -x "${openWebUIBinary}" ]; then
      echo "Installing Open WebUI into $HOME/Library/Python/3.11"
      "${pip3Path}" install --user --upgrade pip setuptools wheel
      "${pip3Path}" install --user --upgrade open-webui
    fi

    mkdir -p "${cfg.dataDir}"

    exec "${openWebUIBinary}" serve
  '';

  # Updater script for daily automatic updates
  openWebUIUpdater = pkgs.writeShellScriptBin "update-open-webui" ''
    #!/bin/bash
    set -euo pipefail

    export HOME="${homeDir}"
    export PATH="/opt/homebrew/bin:$PATH"

    if [ ! -x "${pip3Path}" ]; then
      echo "ERROR: pip3.11 not found at ${pip3Path}"
      exit 1
    fi

    echo "Checking for Open WebUI updates..."
    "${pip3Path}" install --user --upgrade open-webui
    launchctl kickstart -k "gui/$(id -u)/org.nixos.open-webui" >/dev/null 2>&1 || true
  '';
in
{
  options.services.open-webui = {
    enable = lib.mkEnableOption "Open WebUI LLM interface";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for Open WebUI to listen on";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "URL of the Ollama server";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/.open-webui/data";
      description = "Directory for Open WebUI data storage";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable daily automatic updates";
    };

    updateInterval = lib.mkOption {
      type = lib.types.int;
      default = 86400;
      description = "Update check interval in seconds (default: 24 hours)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add upgrade script to system packages
    environment.systemPackages = [ upgrade-open-webui ];

    # Main Open WebUI service
    launchd.user.agents.open-webui = {
      serviceConfig = {
        ProgramArguments = [ "${openWebUIRunner}/bin/run-open-webui" ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/open-webui.log";
        StandardErrorPath = "/tmp/open-webui.error.log";
        WorkingDirectory = "${homeDir}/.open-webui";
        EnvironmentVariables = {
          PORT = toString cfg.port;
          OLLAMA_BASE_URL = cfg.ollamaUrl;
          WEBUI_AUTH = "true";
          DATA_DIR = cfg.dataDir;
          HOME = homeDir;
        };
      };
    };

    # Auto-updater service (runs daily by default)
    launchd.user.agents.open-webui-updater = lib.mkIf cfg.autoUpdate {
      serviceConfig = {
        ProgramArguments = [ "${openWebUIUpdater}/bin/update-open-webui" ];
        RunAtLoad = true;
        StartInterval = cfg.updateInterval;
        StandardOutPath = "/tmp/open-webui.updater.log";
        StandardErrorPath = "/tmp/open-webui.updater.error.log";
      };
    };

    # Firewall rules for Open WebUI (python process)
    system.activationScripts.open-webui-firewall.text = ''
      /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/python3.11 >/dev/null 2>&1 || true
      /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/python3.11 >/dev/null 2>&1 || true
    '';
  };
}

