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
    /opt/homebrew/bin/pip3.11 install --user --upgrade --root-user-action=ignore open-webui
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
  # AI server packages
  environment.systemPackages = [
    upgrade-open-webui
  ];

  # Homebrew packages for AI services
  homebrew.brews = [
    "node"  # Includes npm and npx for MCP extensions
    "ollama"
    "python@3.11"  # For Open WebUI
  ];

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

  # === Activation Scripts ===

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
      /opt/homebrew/bin/pip3.11 install --user --upgrade --root-user-action=ignore open-webui

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

  # Firewall setup for AI services
  system.activationScripts.firewall.text = ''
    # Open port 11434 for Ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/ollama
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/ollama
    # Open port 8080 for Open WebUI
    /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/python3.11
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/python3.11
  '';
}

