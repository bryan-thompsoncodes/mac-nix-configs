{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.vets-website = let
      nodeLib = import ./_nodeLib.nix { inherit pkgs; };

      # Node.js 14.15.0 from shared nodeLib
      nodejs = nodeLib.nodejs14;

      # Yarn 1.x
      yarn = pkgs.yarn.override { inherit nodejs; };

      # Additional build tools for vets-website
      extraBuildTools = with pkgs; [
        vips
        nodePackages.typescript-language-server
        nodePackages.typescript
      ];

    in
    pkgs.mkShell {
      buildInputs = [
        nodejs
        yarn
        pkgs.git
      ] ++ nodeLib.commonBuildTools ++ extraBuildTools ++ nodeLib.browserTestingDeps;

      shellHook = ''
        echo "🚀 vets-website development environment"
        echo ""
        echo "Node version: $(node --version)"
        echo "Yarn version: $(yarn --version)"
        echo "Python version: $(python3 --version)"
        echo ""
        echo "📦 Next steps:"
        echo "  1. Run 'yarn install' to install dependencies"
        echo "  2. Run 'yarn watch' to start the dev server"
        echo "  3. Run 'yarn test:unit' for unit tests"
        echo "  4. Run 'yarn cy:open' for Cypress tests"
        echo ""

        ${nodeLib.nodeEnvSetup}
        ${nodeLib.yarnClassicSetup}

        # Run postinstall scripts for packages that need them (lifecycle scripts are disabled for security)
        # Uses the shared run-postinstall.sh script, runs once after yarn install
        POSTINSTALL_MARKER="node_modules/.postinstall-complete"
        if [ -d "node_modules" ] && [ -f "script/run-postinstall.sh" ] && [ ! -f "''$POSTINSTALL_MARKER" ]; then
          bash script/run-postinstall.sh && touch "''$POSTINSTALL_MARKER" || true
        fi

        # Disable Cypress binary installation (handled separately)
        export CYPRESS_INSTALL_BINARY=0

        # Work around Nix store read-only issues with stylelint
        export STYLELINT_CACHE_LOCATION="''${TMPDIR:-/tmp}/stylelint-cache"
        mkdir -p "$STYLELINT_CACHE_LOCATION"
      '';

      # Set library path for Cypress and other native bindings
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nodeLib.browserTestingDeps;
    };
  };
}
