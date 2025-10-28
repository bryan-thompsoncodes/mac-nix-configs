{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # GIS/Geospatial
    gdal
    geos
    proj
    libspatialite
  ];
}
