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
         default = "5m";
         description = "How long to keep models loaded (0 = unload immediately, -1 = forever)";
       };

       models = lib.mkOption {
         type = lib.types.listOf lib.types.str;
         default = [];
         description = "Models to pull automatically on system activation";
         example = [ "deepseek-r1:70b" "qwen3-coder:30b" ];
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
          };
        };
      };

       # Firewall rules for Ollama
       system.activationScripts.ollama-firewall.text = ''
         /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/ollama >/dev/null 2>&1 || true
         /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /opt/homebrew/bin/ollama >/dev/null 2>&1 || true
       '';

       # Pull models on activation
       system.activationScripts.ollama-models.text = lib.mkIf (cfg.models != []) ''
         echo "Pulling Ollama models..."
         for model in ${lib.concatStringsSep " " cfg.models}; do
           if ! /opt/homebrew/bin/ollama list 2>/dev/null | grep -q "^$model"; then
             echo "Pulling $model..."
             /opt/homebrew/bin/ollama pull "$model" || echo "Warning: Failed to pull $model"
           else
             echo "$model already available"
           fi
         done
       '';
     };
  };

  # NixOS aspect - stub for future implementation
  flake.modules.nixos.ollama = { config, lib, ... }: {
    # TODO: Implement NixOS equivalent using systemd service
    # NixOS has native ollama package and service module
  };
}
