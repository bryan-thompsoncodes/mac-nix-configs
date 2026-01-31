# OpenClaw AI service (containerized via Podman)
#
# Provides a self-hosted AI assistant running in a Podman container for security isolation.
# Uses Podman (FOSS, rootless) instead of Docker Desktop.
#
# Requires:
# - Homebrew `podman` package
# - At least one AI provider API key (Anthropic or OpenAI)
#
# First run: `podman machine init && podman machine start` (handled by service)
# Access: http://localhost:18789
{ inputs, ... }:
{
  flake.modules.darwin.openclaw = { pkgs, config, lib, ... }:
  let
    cfg = config.services.openclaw;
    homeDir = "/Users/${config.system.primaryUser}";
    podmanPath = "/opt/homebrew/bin/podman";
    configDir = "${homeDir}/.openclaw";
    workspaceDir = "${configDir}/workspace";

    # Script to ensure Podman machine is running
    podmanMachineScript = pkgs.writeShellScript "podman-machine-ensure" ''
      exec 1>/tmp/podman-machine.log 2>/tmp/podman-machine.error.log

      export PATH="/opt/homebrew/bin:$PATH"

      echo "=== Podman Machine Check at $(date) ==="

      # Check if podman is available
      if [ ! -x "${podmanPath}" ]; then
        echo "ERROR: Podman not found at ${podmanPath}"
        echo "Please install it with: brew install podman"
        exit 1
      fi

      # Check if machine exists
      if ! ${podmanPath} machine list --format "{{.Name}}" 2>/dev/null | grep -q "podman-machine-default"; then
        echo "Initializing Podman machine..."
        ${podmanPath} machine init --cpus ${toString cfg.machineCpus} --memory ${toString cfg.machineMemory} --disk-size ${toString cfg.machineDisk}
      fi

      # Check if machine is running
      MACHINE_STATUS=$(${podmanPath} machine list --format "{{.LastUp}}" 2>/dev/null | head -1)
      if [ "$MACHINE_STATUS" != "Currently running" ]; then
        echo "Starting Podman machine..."
        ${podmanPath} machine start
      else
        echo "Podman machine already running"
      fi

      echo "=== Podman Machine Ready ==="
    '';

    # Script to run OpenClaw container
    openclawRunnerScript = pkgs.writeShellScript "run-openclaw" ''
      exec 1>/tmp/openclaw.log 2>/tmp/openclaw.error.log

      export PATH="/opt/homebrew/bin:$PATH"
      export HOME="${homeDir}"

      echo "=== OpenClaw Container Start at $(date) ==="

      # Wait for podman machine
      MAX_RETRIES=30
      RETRY_COUNT=0
      while ! ${podmanPath} machine list --format "{{.LastUp}}" 2>/dev/null | grep -q "Currently running"; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
          echo "ERROR: Podman machine not running after $MAX_RETRIES attempts"
          exit 1
        fi
        echo "Waiting for Podman machine... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
      done

      # Create config directories
      mkdir -p "${configDir}"
      mkdir -p "${workspaceDir}"

      # Check if image exists
      if ! ${podmanPath} image exists ${cfg.image} 2>/dev/null; then
        echo "ERROR: OpenClaw image '${cfg.image}' not found."
        echo "Please build it first with: openclaw-manage build"
        exit 1
      fi

      # Check if onboarding was completed
      if [ ! -f "${configDir}/openclaw.json" ]; then
        echo "ERROR: OpenClaw not configured."
        echo "Please run: openclaw-manage onboard"
        exit 1
      fi

      # Stop existing container if running
      ${podmanPath} stop openclaw-gateway 2>/dev/null || true
      ${podmanPath} rm openclaw-gateway 2>/dev/null || true

      # Build environment variables (token comes from config file, not env)
      ENV_ARGS="-e HOME=/home/node"
      ENV_ARGS="$ENV_ARGS -e TERM=xterm-256color"

      # Add API keys from env file if exists
      ENV_FILE="${configDir}/.env"
      if [ -f "$ENV_FILE" ]; then
        ENV_ARGS="$ENV_ARGS --env-file=$ENV_FILE"
      fi

      echo "Starting OpenClaw container..."
      exec ${podmanPath} run \
        --name openclaw-gateway \
        --init \
        --rm \
        -p ${toString cfg.port}:18789 \
        -v "${configDir}:/home/node/.openclaw:Z" \
        -v "${workspaceDir}:/home/node/.openclaw/workspace:Z" \
        $ENV_ARGS \
        ${cfg.image} \
        node dist/index.js gateway --bind lan --port 18789
    '';

    # Upgrade/management script
    openclawManageScript = pkgs.writeShellScriptBin "openclaw-manage" ''
      #!/bin/bash
      set -e

      export PATH="/opt/homebrew/bin:$PATH"

      case "$1" in
        status)
          echo "=== OpenClaw Status ==="
          echo ""
          echo "Podman Machine:"
          ${podmanPath} machine list
          echo ""
          echo "OpenClaw Container:"
          ${podmanPath} ps -a --filter name=openclaw-gateway
          echo ""
          echo "Gateway Token:"
          if [ -f "${configDir}/.gateway-token" ]; then
            cat "${configDir}/.gateway-token"
          else
            echo "(not generated yet)"
          fi
          echo ""
          echo "Access URL: http://localhost:${toString cfg.port}"
          ;;

        logs)
          ${podmanPath} logs -f openclaw-gateway
          ;;

        restart)
          echo "Restarting OpenClaw..."
          launchctl kickstart -k "gui/$(id -u)/org.nixos.openclaw"
          ;;

        stop)
          echo "Stopping OpenClaw..."
          ${podmanPath} stop openclaw-gateway 2>/dev/null || true
          ;;

        pull|update)
          echo "Updating OpenClaw..."
          # Re-run build to pull latest source and rebuild
          "$0" build
          echo ""
          echo "Update complete. Restart with: openclaw-manage restart"
          ;;

        token)
          # First try config file (set by onboard wizard), then fallback to generated token
          CONFIG_TOKEN=$(grep -o '"token": *"[^"]*"' "${configDir}/openclaw.json" 2>/dev/null | grep -o '"[^"]*"$' | tr -d '"' | head -1)
          if [ -n "$CONFIG_TOKEN" ]; then
            echo "$CONFIG_TOKEN"
          elif [ -f "${configDir}/.gateway-token" ]; then
            cat "${configDir}/.gateway-token"
          else
            echo "Token not found. Run 'openclaw-manage onboard' first."
            exit 1
          fi
          ;;

        build)
          echo "=== Building OpenClaw Image ==="
          echo ""
          echo "This will clone the OpenClaw repo and build the container image."
          echo "This may take 5-10 minutes on first run."
          echo ""
          
          # Ensure podman machine exists and is running
          if ! ${podmanPath} machine list --format "{{.Name}}" 2>/dev/null | grep -q "podman-machine-default"; then
            echo "Initializing Podman machine (first time setup)..."
            ${podmanPath} machine init --cpus ${toString cfg.machineCpus} --memory ${toString cfg.machineMemory} --disk-size ${toString cfg.machineDisk}
          fi
          
          if ! ${podmanPath} machine list --format "{{.LastUp}}" 2>/dev/null | grep -q "Currently running"; then
            echo "Starting Podman machine..."
            ${podmanPath} machine start
          fi
          
          BUILD_DIR="${configDir}/build"
          mkdir -p "$BUILD_DIR"
          
          if [ ! -d "$BUILD_DIR/openclaw/.git" ]; then
            echo "Cloning OpenClaw repository..."
            rm -rf "$BUILD_DIR/openclaw"
            git clone --depth 1 https://github.com/openclaw/openclaw.git "$BUILD_DIR/openclaw"
          else
            echo "Updating OpenClaw repository..."
            cd "$BUILD_DIR/openclaw" && git pull
          fi
          
          cd "$BUILD_DIR/openclaw"
          
          echo ""
          echo "Building container image (this takes a few minutes)..."
          ${podmanPath} build -t openclaw:local -f Dockerfile .
          
          echo ""
          echo "=== Build Complete ==="
          echo "Image 'openclaw:local' is ready."
          echo ""
          echo "Next steps:"
          echo "  1. Run onboarding: openclaw-manage onboard"
          echo "  2. Start service:  openclaw-manage restart"
          ;;

        onboard)
          echo "=== OpenClaw Onboarding Wizard ==="
          echo ""
          echo "This will set up OAuth login for Claude Pro/Max or ChatGPT subscriptions."
          echo "You can also configure API keys if preferred."
          echo ""
          
          # Check if image exists
          if ! ${podmanPath} image exists openclaw:local 2>/dev/null; then
            echo "ERROR: OpenClaw image not found."
            echo "Please build it first with: openclaw-manage build"
            exit 1
          fi
          
          # Ensure podman machine exists and is running
          if ! ${podmanPath} machine list --format "{{.Name}}" 2>/dev/null | grep -q "podman-machine-default"; then
            echo "Initializing Podman machine (first time setup)..."
            ${podmanPath} machine init --cpus ${toString cfg.machineCpus} --memory ${toString cfg.machineMemory} --disk-size ${toString cfg.machineDisk}
          fi
          
          if ! ${podmanPath} machine list --format "{{.LastUp}}" 2>/dev/null | grep -q "Currently running"; then
            echo "Starting Podman machine..."
            ${podmanPath} machine start
          fi
          
          # Create config directories
          mkdir -p "${configDir}"
          mkdir -p "${workspaceDir}"
          
          # Stop gateway if running (onboard needs exclusive access)
          ${podmanPath} stop openclaw-gateway 2>/dev/null || true
          ${podmanPath} rm openclaw-gateway 2>/dev/null || true
          
          # Run interactive onboarding
          ${podmanPath} run -it --rm \
            -v "${configDir}:/home/node/.openclaw:Z" \
            -v "${workspaceDir}:/home/node/.openclaw/workspace:Z" \
            -e HOME=/home/node \
            -e TERM=xterm-256color \
            openclaw:local \
            node dist/index.js onboard
          
          echo ""
          echo "Onboarding complete! Start the service with: openclaw-manage restart"
          ;;

        configure)
          echo "=== OpenClaw Configuration ==="
          echo ""
          
          # Ensure podman machine exists and is running
          if ! ${podmanPath} machine list --format "{{.Name}}" 2>/dev/null | grep -q "podman-machine-default"; then
            echo "Initializing Podman machine..."
            ${podmanPath} machine init --cpus ${toString cfg.machineCpus} --memory ${toString cfg.machineMemory} --disk-size ${toString cfg.machineDisk}
          fi
          
          if ! ${podmanPath} machine list --format "{{.LastUp}}" 2>/dev/null | grep -q "Currently running"; then
            echo "Starting Podman machine..."
            ${podmanPath} machine start
          fi
          
          # Run configure command
          ${podmanPath} run -it --rm \
            -v "${configDir}:/home/node/.openclaw:Z" \
            -v "${workspaceDir}:/home/node/.openclaw/workspace:Z" \
            -e HOME=/home/node \
            -e TERM=xterm-256color \
            ${cfg.image} \
            node dist/index.js configure "$2"
          ;;

        cli)
          # Run any openclaw CLI command
          shift
          
          # Ensure podman machine exists and is running
          if ! ${podmanPath} machine list --format "{{.Name}}" 2>/dev/null | grep -q "podman-machine-default"; then
            echo "Initializing Podman machine..."
            ${podmanPath} machine init --cpus ${toString cfg.machineCpus} --memory ${toString cfg.machineMemory} --disk-size ${toString cfg.machineDisk}
          fi
          
          if ! ${podmanPath} machine list --format "{{.LastUp}}" 2>/dev/null | grep -q "Currently running"; then
            echo "Starting Podman machine..."
            ${podmanPath} machine start
          fi
          
          ${podmanPath} run -it --rm \
            -v "${configDir}:/home/node/.openclaw:Z" \
            -v "${workspaceDir}:/home/node/.openclaw/workspace:Z" \
            -e HOME=/home/node \
            -e TERM=xterm-256color \
            ${cfg.image} \
            node dist/index.js "$@"
          ;;

        env)
          echo "Opening env file for editing..."
          echo "(Note: For OAuth login, use 'openclaw-manage onboard' instead)"
          echo ""
          mkdir -p "${configDir}"
          if [ ! -f "${configDir}/.env" ]; then
            cat > "${configDir}/.env" <<'ENVEOF'
# OpenClaw Environment Variables
# For OAuth login (Claude Pro/Max, ChatGPT), run: openclaw-manage onboard
# Only use API keys if you prefer direct API access

# Anthropic Claude API (optional - use onboard for OAuth)
#ANTHROPIC_API_KEY=sk-ant-your-key-here

# OpenAI API (optional - use onboard for OAuth)
#OPENAI_API_KEY=sk-your-key-here

# Messaging platforms (optional)
#TELEGRAM_BOT_TOKEN=your-token
#DISCORD_BOT_TOKEN=your-token
ENVEOF
          fi
          ''${EDITOR:-vim} "${configDir}/.env"
          echo "Restart the service to apply changes: openclaw-manage restart"
          ;;

        *)
          echo "OpenClaw Management"
          echo ""
          echo "Usage: openclaw-manage <command>"
          echo ""
          echo "FIRST-TIME SETUP (run in order):"
          echo "  1. build          - Clone repo and build container image (~5-10 min)"
          echo "  2. onboard        - Interactive OAuth setup (Claude/ChatGPT login)"
          echo "  3. restart        - Start the gateway service"
          echo ""
          echo "SERVICE:"
          echo "  status            - Show service status and access info"
          echo "  logs              - Follow container logs"
          echo "  restart           - Restart the OpenClaw container"
          echo "  stop              - Stop the OpenClaw container"
          echo "  update            - Pull latest source and rebuild"
          echo "  token             - Display gateway token"
          echo ""
          echo "CONFIGURATION:"
          echo "  configure [section] - Run configuration wizard"
          echo "  env               - Edit environment variables (API keys)"
          echo "  cli <args>        - Run any openclaw CLI command"
          ;;
      esac
    '';
  in
  {
    options.services.openclaw = {
      enable = lib.mkEnableOption "OpenClaw AI assistant (containerized)";

      port = lib.mkOption {
        type = lib.types.port;
        default = 18789;
        description = "Port for OpenClaw gateway to listen on";
      };

      image = lib.mkOption {
        type = lib.types.str;
        default = "openclaw:local";
        description = "OpenClaw container image to use (build with 'openclaw-manage build')";
      };

      machineCpus = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Number of CPUs for Podman machine";
      };

      machineMemory = lib.mkOption {
        type = lib.types.int;
        default = 4096;
        description = "Memory (MB) for Podman machine";
      };

      machineDisk = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "Disk size (GB) for Podman machine";
      };
    };

    config = lib.mkIf cfg.enable {
      # Add management script to PATH
      environment.systemPackages = [ openclawManageScript ];

      # Podman machine service (ensures VM is running)
      launchd.user.agents.podman-machine = {
        serviceConfig = {
          ProgramArguments = [ "${podmanMachineScript}" ];
          RunAtLoad = true;
          KeepAlive = false;
          StandardOutPath = "/tmp/podman-machine.log";
          StandardErrorPath = "/tmp/podman-machine.error.log";
        };
      };

      # OpenClaw container service
      launchd.user.agents.openclaw = {
        serviceConfig = {
          ProgramArguments = [ "${openclawRunnerScript}" ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/openclaw.log";
          StandardErrorPath = "/tmp/openclaw.error.log";
          # Wait for podman-machine to start first
          ThrottleInterval = 10;
        };
      };

      # Setup instructions
      system.activationScripts.openclaw-setup.text = ''
        echo ""
        echo "=== OpenClaw AI Setup ==="
        echo ""
        echo "OpenClaw runs in a Podman container for security isolation."
        echo ""
        echo "FIRST TIME SETUP (run in order):"
        echo "  1. openclaw-manage build     # Build image from source (~5-10 min)"
        echo "  2. openclaw-manage onboard   # OAuth login for Claude/ChatGPT"
        echo "  3. openclaw-manage restart   # Start the gateway"
        echo "  4. openclaw-manage token     # Get access token"
        echo "  5. open http://localhost:${toString cfg.port}"
        echo ""
        echo "Run 'openclaw-manage' to see all commands."
        echo ""
      '';
    };
  };

  # NixOS aspect - stub for future implementation
  flake.modules.nixos.openclaw = { config, lib, ... }: {
    # TODO: Implement NixOS equivalent using podman/systemd
    # NixOS has native podman support via virtualisation.podman
  };
}
