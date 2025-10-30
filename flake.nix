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
    # macOS configurations using nix-darwin
    darwinConfigurations = {
      a6mbp = mkDarwinConfig "a6mbp";
      mbp = mkDarwinConfig "mbp";
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
