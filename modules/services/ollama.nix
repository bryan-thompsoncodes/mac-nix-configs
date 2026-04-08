# Ollama LLM server service
#
# Provides local LLM inference via Ollama. Requires homebrew `ollama` package.
# Default: serves on 127.0.0.1:11434 with flash attention and q8_0 KV cache.
{ inputs, ... }:
{
  # Darwin aspect - full configuration from modules/darwin/services/ollama.nix
  flake.modules.darwin.ollama = { config, lib, ... }: {
    options.services.ollama = {
      enable = lib.mkEnableOption "Ollama LLM server";

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for Ollama to bind to";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Port for Ollama to listen on";
      };

      flashAttention = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable flash attention for faster inference";
      };

      kvCacheType = lib.mkOption {
        type = lib.types.str;
        default = "q8_0";
        description = "KV cache quantization type";
      };

      keepAlive = lib.mkOption {
        type = lib.types.str;
        default = "45m";
        description = "How long to keep models loaded (0 = unload immediately, -1 = forever)";
      };

      maxLoadedModels = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Maximum number of models loaded concurrently";
      };

      numParallel = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Maximum number of parallel requests per model";
      };
    };

    config = let
      cfg = config.services.ollama;
    in lib.mkIf cfg.enable {
      # Ollama service configuration
      launchd.user.agents.ollama = {
        serviceConfig = {
          ProgramArguments = [ "/opt/homebrew/bin/ollama" "serve" ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/ollama.log";
          StandardErrorPath = "/tmp/ollama.error.log";
          EnvironmentVariables = {
            OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
            OLLAMA_ORIGINS = "*";
            OLLAMA_FLASH_ATTENTION = if cfg.flashAttention then "1" else "0";
            OLLAMA_KV_CACHE_TYPE = cfg.kvCacheType;
            OLLAMA_KEEP_ALIVE = cfg.keepAlive;
            OLLAMA_MAX_LOADED_MODELS = toString cfg.maxLoadedModels;
            OLLAMA_NUM_PARALLEL = toString cfg.numParallel;
          };
        };
      };

      # Firewall rules for Ollama
      system.activationScripts.ollama-firewall.text = ''
        /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/ollama >/dev/null 2>&1 || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/ollama >/dev/null 2>&1 || true
      '';

      # Restart Ollama after rebuild to pick up any Homebrew binary upgrades.
      # The launchd plist doesn't change when brew upgrades the binary, so
      # nix-darwin won't restart the agent on its own.
      system.activationScripts.ollama-restart.text = ''
        uid=$(/usr/bin/id -u ${config.system.primaryUser})
        if /bin/launchctl print "gui/$uid/org.nixos.ollama" &>/dev/null; then
          echo "Restarting Ollama to pick up any binary updates..."
          /bin/launchctl kickstart -k "gui/$uid/org.nixos.ollama"
        fi
      '';
    };
  };

  # NixOS aspect - stub for future implementation
  flake.modules.nixos.ollama = { config, lib, ... }: {
    # TODO: Implement NixOS equivalent using systemd service
    # NixOS has native ollama package and service module
  };
}
