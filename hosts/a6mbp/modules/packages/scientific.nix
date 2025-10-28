{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Scientific/Data
    hdf5
    netcdf
  ];
}
