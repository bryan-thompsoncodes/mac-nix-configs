{ inputs, ... }:
{
  flake.modules.darwin.git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh  # GitHub CLI
    ];
  };

  flake.modules.nixos.git = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      gh  # GitHub CLI
    ];
  };
}
