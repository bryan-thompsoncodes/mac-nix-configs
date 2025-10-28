{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    historyLimit = 10000;
    baseIndex = 1;
    keyMode = "vi";

    extraConfig = ''
      # Source your dotfiles config if it exists
      if-shell "test -f ~/code/dotfiles/dot-tmux.conf" "source-file ~/code/dotfiles/dot-tmux.conf"
    '';
  };
}
