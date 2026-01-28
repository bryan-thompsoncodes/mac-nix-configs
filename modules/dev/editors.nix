{ inputs, ... }:
{
  flake.modules.darwin.editors = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      vim
      neovim
    ];
  };

  flake.modules.nixos.editors = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      vim
      neovim
      sublime4
    ];
  };
}
