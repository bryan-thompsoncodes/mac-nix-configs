# REAPER digital audio workstation
#
# Cross-platform DAW for music production. On macOS, installs via Homebrew cask.
# On NixOS, installs via nixpkgs binary package and configures audio plugin paths
# for NixOS's non-FHS filesystem layout.
{ inputs, ... }:
{
  # Darwin aspect - Homebrew cask
  flake.modules.darwin.reaper = { ... }: {
    homebrew.casks = [
      "reaper"
    ];
  };

  # NixOS aspect - nix package + plugin path configuration
  flake.modules.nixos.reaper = { pkgs, lib, ... }: {
    environment.systemPackages = [
      pkgs.reaper
    ];

    # Set audio plugin search paths for NixOS non-FHS filesystem
    # Without these, REAPER (and other DAWs) can't discover Nix-installed plugins
    environment.variables = let
      makePluginPath = format:
        (lib.makeSearchPath format [
          "$HOME/.nix-profile/lib"
          "/run/current-system/sw/lib"
          "/etc/profiles/per-user/$USER/lib"
        ])
        + ":$HOME/.${format}";
    in {
      DSSI_PATH = makePluginPath "dssi";
      LADSPA_PATH = makePluginPath "ladspa";
      LV2_PATH = makePluginPath "lv2";
      LXVST_PATH = makePluginPath "lxvst";
      VST_PATH = makePluginPath "vst";
      VST3_PATH = makePluginPath "vst3";
    };
  };
}
