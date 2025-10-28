{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Oh-My-Zsh configuration
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "macos"
        "docker"
        "kubectl"
        "npm"
        "yarn"
        "node"
        "python"
        "aws"
      ];
    };

    # Powerlevel10k theme and other plugins
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

    # Source p10k config and custom configuration
    initContent = ''
      # Source p10k configuration
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # Common aliases
      alias -- ..='cd ..'
      alias -- ...='cd ../..'
      alias -- ....='cd ../../..'
      alias -- cat=bat
      alias -- clr="clear"
      alias -- la='eza -a --icons'
      alias -- ll='eza -lah --icons'
      alias -- lla='eza -la'
      alias -- ls='eza --icons'
      alias -- lt='eza --tree --icons'
      alias -- vim="nvim"
      alias -- vi="nvim"
      alias -- fman="compgen -c | fzf | xargs man"
      alias -- va-tmux="cd ~/code/department-of-veterans-affairs && tmux new-session -A -s va.gov"

      # Git aliases
      alias -- gcob="git checkout -b"
      alias -- gbd="git branch -d"
      alias -- gbD="git branch -D"
      alias -- gpl="git pull"
      alias -- gl="git log"
      alias -- gpF="git push --force"

      # Server aliases
      alias -- content-build-server="vtk socks on && cd ~/code/department-of-veterans-affairs/content-build && yarn build --pull-drupal && yarn serve"
      alias -- vets-api-server="cd ~/code/department-of-veterans-affairs/vets-api && foreman start -m all=1,clamd=0,freshclam=0"
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
      function vets-website-server {
        local env=''${1:-static-pages}
        cd ~/code/department-of-veterans-affairs/vets-website
        yarn watch --env=''$env
      }

      # Git rebase function - overrides oh-my-zsh grb alias
      # Defaults to 3 commits back, otherwise use argument passed as:
      # - Count if integer: interactive rebase last N commits
      # - Commit hash or branch name if string: rebase onto that ref
      # Example usage:
      #   grb           # interactive rebase last 3 commits
      #   grb 6         # interactive rebase last 6 commits
      #   grb feature   # rebase onto branch 'feature'
      #   grb abc1234   # rebase onto commit abc1234
      unalias grb 2>/dev/null || true
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

      # Git shortcuts
      gs = "git status";
      gp = "git push";
      gl = "git log --oneline --graph";
      gco = "git checkout";
      gaa = "git add --all";
      gcm = "git commit -m";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Modern replacements (if installed)
      cat = "bat";
      ls = "eza --icons";
      ll = "eza -lah --icons";
      la = "eza -a --icons";
      lt = "eza --tree --icons";
    };

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";

      # Node
      NODE_OPTIONS = "--max-old-space-size=4096";
    };
  };
}
