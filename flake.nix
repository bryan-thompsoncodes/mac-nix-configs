{
  description = "Bryan's System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin }:
  let
    # Helper function to create pkgs for a given system
    mkPkgs = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # macOS system
    darwinSystem = "aarch64-darwin";
    darwinPkgs = mkPkgs darwinSystem;

    # Helper to create dev shells for multiple systems
    mkDevShells = system:
      let
        pkgs = mkPkgs system;
      in
      {
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
  in
  {
    # macOS configurations using nix-darwin
    darwinConfigurations.a6mbp = nix-darwin.lib.darwinSystem {
      system = darwinSystem;

      modules = [
        ./hosts/a6mbp.nix
      ];
    };

    darwinConfigurations.mbp = nix-darwin.lib.darwinSystem {
      system = darwinSystem;

      modules = [
        ./hosts/mbp.nix
      ];
    };

    # NixOS configurations (placeholder for future hosts like gnarbox)
    nixosConfigurations = {
      # Example: gnarbox = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     ./hosts/gnarbox.nix
      #   ];
      # };
    };

    # Development shells for multiple systems
    devShells = {
      # macOS (Apple Silicon)
      ${darwinSystem} = mkDevShells darwinSystem;

      # Linux (x86_64) - for NixOS systems like gnarbox
      "x86_64-linux" = mkDevShells "x86_64-linux";

      # Additional architectures can be added as needed
      # "aarch64-linux" = mkDevShells "aarch64-linux";
    };
  };
}
