{ config, pkgs, ... }:

{
  # SSH config is NOT managed by nix
  #
  # Reason: We use `vtk socks` for VA work, which writes to ~/.ssh/config
  # Managing SSH with nix creates conflicts with vtk's dynamic configuration.
  #
  # Manage ~/.ssh/config manually instead.

  programs.ssh.enable = false;
}
