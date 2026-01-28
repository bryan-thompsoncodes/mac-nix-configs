# Declare flake output options for module merging
# This allows multiple modules to contribute to flake.modules.darwin.* and flake.modules.nixos.*
{ lib, ... }:
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
    default = {};
    description = "System modules organized by platform (darwin, nixos)";
  };
}
