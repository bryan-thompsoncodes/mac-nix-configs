# Base module: Zsh shell configuration
# Enables Zsh as the system shell for both darwin and nixos
{ inputs, ... }:
{
  flake.modules.darwin.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
    programs.zsh.interactiveShellInit = ''
      ulimit -n 10240
    '';
  };
  
  flake.modules.nixos.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
  };
}
