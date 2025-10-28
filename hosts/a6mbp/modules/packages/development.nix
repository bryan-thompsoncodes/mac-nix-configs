{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Version Control
    git
    gh  # GitHub CLI

    # Development - Python
    python312  # Use python312 only to avoid conflicts

    # Development - Java
    jdk11
  ];
}
