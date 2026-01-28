{ inputs, ... }:
{
  flake.modules.darwin.cli-tools = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Terminal
      alacritty

      # CLI utilities - modern replacements
      ripgrep  # better grep
      fd       # better find

      # CLI utilities - general
      wget
      tree
      htop
      bat
      eza
      fzf
      direnv
      nix-direnv  # Fast, persistent Nix shell caching for direnv
      stow
      tmux
      ncurses

      # Nix development
      nixd  # Nix language server

      # JavaScript toolchain
      bun

      # Additional tools
      delta       # better git diffs
      jq          # JSON processor
      zoxide      # smarter cd
      shellcheck  # shell script linter
    ];
  };

  flake.modules.nixos.cli-tools = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      # Terminal
      alacritty

      # CLI utilities - modern replacements
      ripgrep  # better grep
      fd       # better find

      # CLI utilities - general
      wget
      tree
      htop
      bat
      eza
      fzf
      direnv
      nix-direnv  # Fast, persistent Nix shell caching for direnv
      stow
      tmux
      ncurses

      # Nix development
      nixd  # Nix language server

      # JavaScript toolchain
      bun

      # Additional tools
      delta       # better git diffs
      jq          # JSON processor
      zoxide      # smarter cd
      shellcheck  # shell script linter
    ];
  };
}
