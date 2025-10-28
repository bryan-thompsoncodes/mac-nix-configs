{
  description = "Bryan's macOS System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager }:
  let
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations.a6mbp = nix-darwin.lib.darwinSystem {
      inherit system;

      modules = [
        ./darwin.nix

        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.bryan = import ./hosts/a6mbp/home.nix;
          };

          users.users.bryan = {
            name = "bryan";
            home = "/Users/bryan";
          };
        }
      ];
    };
  };
}
