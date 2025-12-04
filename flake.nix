{
  description = "Bryan's System Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Unstable packages for overlays
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nix-darwin } @ inputs:
  let
    inherit (self) outputs;

    # Overlays
    overlays = import ./overlays {inherit inputs;};

    # Helper function to create pkgs for a given system
    mkPkgs = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        overlays.unstable
        (final: prev: {
          cursor = final.callPackage ./pkgs/cursor {
            vscode-generic = "${final.path}/pkgs/applications/editors/vscode/generic.nix";
          };
        })
      ];
    };

    # macOS system
    darwinSystem = "aarch64-darwin";
    darwinPkgs = mkPkgs darwinSystem;

    # Helper to create Darwin configuration
    mkDarwinConfig = hostname: nix-darwin.lib.darwinSystem {
      system = darwinSystem;
      modules = [ ./hosts/${hostname}.nix ];
    };

    # List of dev environments
    devEnvs = [
      "vets-website"
      "vets-api"
      "next-build"
      "component-library"
      "content-build"
    ];

    # Helper to create dev shells for multiple systems
    mkDevShells = system:
      let
        pkgs = mkPkgs system;
      in
      nixpkgs.lib.genAttrs devEnvs (env:
        import ./dev-envs/${env}.nix { inherit pkgs; }
      );
  in
  {
    # Export overlays for use in NixOS configurations
    overlays = import ./overlays {inherit inputs;};

    # Expose buildable packages
    packages = {
      x86_64-linux = rec {
        cursor = (mkPkgs "x86_64-linux").cursor;
        default = cursor;
      };
    };

    # macOS configurations using nix-darwin
    darwinConfigurations = {
      a6mbp = mkDarwinConfig "a6mbp";
      mbp = mkDarwinConfig "mbp";
      studio = mkDarwinConfig "studio";
    };

    # NixOS configurations
    nixosConfigurations = {
      gnarbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs;
          meta = {
            hostname = "gnarbox";
          };
        };
        modules = [
          ./hosts/gnarbox.nix
          {
            nixpkgs.overlays = [
              overlays.unstable
              (final: prev: {
                cursor = final.callPackage ./pkgs/cursor {
                  vscode-generic = "${final.path}/pkgs/applications/editors/vscode/generic.nix";
                };
              })
            ];
          }
        ];
      };
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
