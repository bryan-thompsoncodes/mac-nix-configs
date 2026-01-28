# Base module: Zsh shell configuration
# Enables Zsh as the system shell for both darwin and nixos
{ inputs, ... }:
{
  flake.modules.darwin.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
  };
  
  flake.modules.nixos.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
  };
}
