{
  description = "Bryan's macOS System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin }:
  let
    system = "aarch64-darwin";

    # Create pkgs instance once and reuse across all environments
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      inherit system;

      modules = [
        ./darwin.nix
      ];
    };

    devShells.${system} = {
      vets-website = import ./dev-envs/vets-website.nix {
        inherit pkgs;
      };

      vets-api = import ./dev-envs/vets-api.nix {
        inherit pkgs;
      };

      next-build = import ./dev-envs/next-build.nix {
        inherit pkgs;
      };

      component-library = import ./dev-envs/component-library.nix {
        inherit pkgs;
      };
    };
  };
}
