# Development module: CLI tools
# Provides common CLI utilities for both darwin and nixos systems
{ inputs, ... }:
let
  # Shared package list for both platforms
  cliPackages = pkgs: with pkgs; [
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
    ncurses

    # Nix development
    nixd  # Nix language server

    # Language servers (for Neovim)
    pyright                      # Python
    lua-language-server          # Lua
    typescript-language-server   # TypeScript/JavaScript/React
    typescript                   # Required by ts language server
    solargraph                   # Ruby/Rails
    yaml-language-server         # YAML
    vacuum-go                    # OpenAPI/Swagger linter
    nodePackages.graphql-language-service-cli  # GraphQL

    # JavaScript toolchain
    bun

    # Additional tools
    delta       # better git diffs
    jq          # JSON processor
    zoxide      # smarter cd
    shellcheck  # shell script linter
    tea         # Gitea/Forgejo CLI (gh alternative)
  ];
in
{
  flake.modules.darwin.cli-tools = { pkgs, ... }: {
    environment.systemPackages = cliPackages pkgs;
  };

  flake.modules.nixos.cli-tools = { pkgs, ... }: {
    environment.systemPackages = cliPackages pkgs;
  };
}
