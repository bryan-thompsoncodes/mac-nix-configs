# Ollama LLM server service for macOS
#
# Provides local LLM inference via Ollama. Requires homebrew `ollama` package.
# Default: serves on 127.0.0.1:11434 with flash attention and q8_0 KV cache.
{ config, lib, ... }:

let
  cfg = config.services.ollama;
in
{
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
      default = "-1";
      description = "How long to keep models loaded (0 = unload immediately, -1 = forever)";
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}

