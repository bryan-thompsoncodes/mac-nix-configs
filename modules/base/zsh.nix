# Base module: Zsh shell configuration
# Enables Zsh as the system shell for both darwin and nixos
# Darwin: uses Homebrew for zsh plugins
# NixOS: uses nixpkgs for zsh plugins
{ inputs, ... }:
{
  # Darwin aspect - Zsh with Homebrew plugins
  flake.modules.darwin.zsh = { ... }: {
    programs.zsh.enable = true;
    programs.zsh.interactiveShellInit = ''
      ulimit -n 10240
    '';
    homebrew.brews = [
      "powerlevel10k"
      "zsh-autosuggestions"
      "zsh-syntax-highlighting"
    ];
  };

  # NixOS aspect - Zsh with nixpkgs plugins
  flake.modules.nixos.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
    environment.systemPackages = with pkgs; [
      zsh-powerlevel10k
      zsh-autosuggestions
      zsh-syntax-highlighting
    ];
  };
}
