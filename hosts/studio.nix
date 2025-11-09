{ pkgs, config, ... }:

let
  # Manual upgrade script for Open WebUI
  upgrade-open-webui = pkgs.writeShellScriptBin "upgrade-open-webui" ''
    #!/bin/bash
    set -e

    echo "=== Open WebUI Manual Upgrade ==="
    echo ""

    # Check if Python 3.11 is available
    if [ ! -f /opt/homebrew/bin/pip3.11 ]; then
      echo "ERROR: Python 3.11 not found at /opt/homebrew/bin/pip3.11"
      echo "Please install it with: brew install python@3.11"
      exit 1
    fi

    # Get current version
    CURRENT_VERSION=$(/opt/homebrew/bin/pip3.11 show open-webui 2>/dev/null | grep Version | cut -d' ' -f2 || echo "not installed")
    echo "Current version: $CURRENT_VERSION"
    echo ""

    # Upgrade
    echo "Upgrading Open WebUI..."
    /opt/homebrew/bin/pip3.11 install --user --upgrade open-webui
    echo ""

    # Get new version
    NEW_VERSION=$(/opt/homebrew/bin/pip3.11 show open-webui 2>/dev/null | grep Version | cut -d' ' -f2 || echo "unknown")
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
    echo "Access it at: http://localhost:8080"
  '';
in
{
  imports = [
    ./darwin-common.nix
  ];

  # Host-specific packages
  environment.systemPackages = [
    upgrade-open-webui
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
        OLLAMA_HOST = "127.0.0.1:11434";
        OLLAMA_ORIGINS = "*";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        OLLAMA_KEEP_ALIVE = "0";
      };
    };
  };

  # Open WebUI service configuration (pip-based)
  launchd.user.agents.open-webui =
    let
      homeDir = "/Users/${config.system.primaryUser}";
    in {
      path = [ "${homeDir}/Library/Python/3.11/bin" ];
      serviceConfig = {
        ProgramArguments = [
          "${homeDir}/Library/Python/3.11/bin/open-webui"
          "serve"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/open-webui.log";
        StandardErrorPath = "/tmp/open-webui.error.log";
        WorkingDirectory = "${homeDir}/.open-webui";
        EnvironmentVariables = {
          PORT = "8080";
          OLLAMA_BASE_URL = "http://127.0.0.1:11434";
          WEBUI_AUTH = "true";
          DATA_DIR = "${homeDir}/.open-webui/data";
          HOME = homeDir;
        };
      };
    };

  # === Network Storage ===

  # SMB mount service for media
  # Note: Uses explicit credentials from ~/.smb-credentials
  launchd.user.agents.smb-mount = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.writeShellScript "mount-smb-media" ''
          # Log all operations
          exec 1>/tmp/smb-mount.log 2>/tmp/smb-mount.error.log

          MOUNT_POINT="$HOME/Media"
          CREDENTIALS_FILE="$HOME/.smb-credentials"
          MAX_RETRIES=30
          RETRY_DELAY=2

          echo "=== SMB Mount Script Started at $(date) ==="

          # Load credentials
          if [ ! -f "$CREDENTIALS_FILE" ]; then
            echo "ERROR: Credentials file not found at $CREDENTIALS_FILE"
            echo "Please create it with the following format:"
            echo "USERNAME=your_username"
            echo "PASSWORD=your_password"
            echo "SERVER=192.168.1.x"
            echo "SHARE=media"
            exit 1
          fi

          source "$CREDENTIALS_FILE"

          # Validate required variables
          if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$SERVER" ] || [ -z "$SHARE" ]; then
            echo "ERROR: Missing required credentials in $CREDENTIALS_FILE"
            echo "Required: USERNAME, PASSWORD, SERVER, SHARE"
            exit 1
          fi

          # Check if already mounted
          if mount | grep -q "$MOUNT_POINT"; then
            echo "Mount point $MOUNT_POINT is already mounted, checking if it's accessible..."
            if ls "$MOUNT_POINT" >/dev/null 2>&1; then
              echo "Mount is healthy, exiting successfully"
              exit 0
            else
              echo "Mount is stale, unmounting..."
              /sbin/umount -f "$MOUNT_POINT" 2>&1 || true
            fi
          fi

          # Ensure mount point exists
          if [ ! -d "$MOUNT_POINT" ]; then
            echo "Creating mount point $MOUNT_POINT..."
            mkdir -p "$MOUNT_POINT"
          fi

          # Wait for network to be ready
          echo "Checking network connectivity to $SERVER..."
          for attempt in $(seq 1 $MAX_RETRIES); do
            if /sbin/ping -c 1 -t 2 "$SERVER" >/dev/null 2>&1; then
              echo "Network is ready (attempt $attempt)"
              break
            fi

            if [ $attempt -eq $MAX_RETRIES ]; then
              echo "ERROR: Server $SERVER unreachable after $MAX_RETRIES attempts"
              exit 1
            fi

            echo "Network not ready, waiting... (attempt $attempt of $MAX_RETRIES)"
            sleep $RETRY_DELAY
          done

          # Mount with explicit credentials
          echo "Attempting to mount //$USERNAME@$SERVER/$SHARE to $MOUNT_POINT..."
          if /sbin/mount_smbfs "//$USERNAME:$PASSWORD@$SERVER/$SHARE" "$MOUNT_POINT" 2>&1; then
            echo "Mount successful at $(date)"
            exit 0
          else
            echo "Mount failed at $(date)"
            echo "Check credentials in $CREDENTIALS_FILE and network connectivity"
            exit 1
          fi
        ''}"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/smb-mount.log";
      StandardErrorPath = "/tmp/smb-mount.error.log";
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

  # Setup SMB mount directory
  system.activationScripts.setup-smb-mount.text = ''
    echo ""
    echo "=== SMB Mount Setup ==="
    echo "For automatic mounting to work, create ~/.smb-credentials with:"
    echo "  USERNAME=username"
    echo "  PASSWORD=your_password"
    echo "  SERVER=192.168.1.x"
    echo "  SHARE=media"
    echo ""
    echo "Then restart or run: launchctl kickstart -k gui/\$(id -u)/org.nixos.smb-mount"
    echo "Check mount status: cat /tmp/smb-mount.log"
    echo ""
  '';

  # Install Open WebUI via pip
  # Note: This runs during system activation
  system.activationScripts.postActivation.text = ''
    echo ""
    echo "=== Open WebUI Upgrade Check at $(date) ==="

    # Check if Python 3.11 is available
    if [ -f /opt/homebrew/bin/pip3.11 ]; then

      # Get current version if installed
      CURRENT_VERSION=$(/opt/homebrew/bin/pip3.11 show open-webui 2>/dev/null | grep Version | cut -d' ' -f2 || echo "not installed")
      echo "Current version: $CURRENT_VERSION"

      # Upgrade Open WebUI
      echo "Running pip upgrade..."
      /opt/homebrew/bin/pip3.11 install --user --upgrade open-webui

      # Get new version
      NEW_VERSION=$(/opt/homebrew/bin/pip3.11 show open-webui 2>/dev/null | grep Version | cut -d' ' -f2 || echo "unknown")
      echo "New version: $NEW_VERSION"

      if [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
        echo "✓ Open WebUI upgraded from $CURRENT_VERSION to $NEW_VERSION"
        echo "Restarting Open WebUI service..."

        # Restart the service to use the new version
        launchctl kickstart -k "gui/$(id -u)/org.nixos.open-webui" 2>/dev/null || echo "Service will start on next login"
        echo "✓ Service restarted successfully"
      else
        echo "Open WebUI already at latest version ($NEW_VERSION)"
      fi

      # Create data directory for Open WebUI
      mkdir -p $HOME/.open-webui/data
      chown "$(id -un):staff" $HOME/.open-webui/data

      echo "=== Open WebUI setup complete ==="
      echo ""
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
