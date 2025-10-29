{
  description = "Bryan's macOS System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-2211.url = "github:NixOS/nixpkgs/nixos-22.11";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-2211, nix-darwin }:
  let
    system = "aarch64-darwin";
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
        pkgs = import nixpkgs-2211 {
          inherit system;
          config.allowUnfree = true;
        };
      };

      vets-api = import ./dev-envs/vets-api.nix {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };

      next-build = import ./dev-envs/next-build.nix {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };

      component-library = import ./dev-envs/component-library.nix {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
  };
}
