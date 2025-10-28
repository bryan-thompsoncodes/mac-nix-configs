{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Zsh plugins managed by Home Manager
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];

    # Zsh initialization
    initContent = ''
      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Source p10k configuration from ~/.local
      [[ ! -f ~/.local/share/p10k/p10k.zsh ]] || source ~/.local/share/p10k/p10k.zsh

      # Enhanced completion settings
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}" # Colored completion

      # Set terminal title to show current command
      autoload -Uz add-zsh-hook

      function set_title_precmd {
        print -Pn "\e]0;%~\a"  # Set title to current directory
      }

      function set_title_preexec {
        # Get the first word of the command (handles aliases, functions, etc.)
        local cmd="''${1%% *}"
        print -Pn "\e]0;$cmd\a"  # Set title to running command
      }

      add-zsh-hook precmd set_title_precmd
      add-zsh-hook preexec set_title_preexec

      # VA Server Scripts
      function cl-storybook {
        cd ~/code/department-of-veterans-affairs/component-library/packages/web-components/
        yarn install
        yarn build
        yarn build-bindings
        cd ../react-components/
        yarn install
        yarn build
        cd ../core/
        yarn install
        yarn build
        cd ../storybook/
        yarn install
        yarn storybook
      }
      function vets-api-server {
        cd ~/code/department-of-veterans-affairs/vets-api
        redis-start
        foreman start -m all=1,clamd=0,freshclam=0
      }
      function vets-website-server {
        local env=''${1:-static-pages,facilities}
        cd ~/code/department-of-veterans-affairs/vets-website
        yarn watch --env=''$env
      }

      # Git rebase function
      # Defaults to 3 commits back, otherwise use argument passed as:
      # - Count if integer: interactive rebase last N commits
      # - Commit hash or branch name if string: rebase onto that ref
      # Example usage:
      #   grb           # interactive rebase last 3 commits
      #   grb 6         # interactive rebase last 6 commits
      #   grb feature   # rebase onto branch 'feature'
      #   grb abc1234   # rebase onto commit abc1234
      grb() {
        local commits=''${1:-3}
        if [[ ''$commits =~ ^[0-9]+''$ ]]; then
          git rebase -i HEAD~''$commits
        else
          git rebase ''$commits
        fi
      }
    '';

    # Aliases
    shellAliases = {
      # Nix management
      rebuild = "sudo darwin-rebuild switch --flake ~/code/mac-nix-configs#a6mbp";
      update = "cd ~/code/mac-nix-configs && nix flake update && sudo darwin-rebuild switch --flake ~/code/mac-nix-configs#a6mbp";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Modern tool replacements
      cat = "bat";
      ls = "eza --icons";
      ll = "eza -lah --icons";
      la = "eza -a --icons";
      lla = "eza -la";
      lsa = "eza -lah";
      lt = "eza --tree --icons";
      vim = "nvim";
      vi = "nvim";

      # Utility aliases
      clr = "clear";
      fman = "compgen -c | fzf | xargs man";
      va-tmux = "cd ~/code/department-of-veterans-affairs && tmux new-session -A -s va.gov";

      # Git aliases
      ga = "git add";
      gd = "git diff";
      gs = "git status";
      gst = "git status";
      gp = "git push";
      gl = "git log --oneline --graph";
      gco = "git checkout";
      gcob = "git checkout -b";
      gaa = "git add --all";
      gcm = "git commit -m";
      gbd = "git branch -d";
      gbD = "git branch -D";
      gpl = "git pull";
      gpF = "git push --force";

      # Server aliases
      content-build-server = "vtk socks on && cd ~/code/department-of-veterans-affairs/content-build && yarn build --pull-drupal && yarn serve";
    };

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";

      # Node
      NODE_OPTIONS = "--max-old-space-size=4096";

      # Zsh completion dump location
      ZSH_COMPDUMP = "$HOME/.local/zcompdump/.zcompdump";
    };
  };
}
