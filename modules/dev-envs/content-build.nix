{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.content-build =
      let
        nodeLib = import ./_nodeLib.nix { inherit pkgs; };

        # Node.js 14.15.0 from shared nodeLib
        nodejs = nodeLib.nodejs14;

        # Yarn 1.x (Classic)
        yarn = pkgs.yarn.override { inherit nodejs; };

        # Helper script to rebuild node-libcurl
        rebuildNodeLibcurl = pkgs.writeShellScriptBin "rebuild-node-libcurl" ''
          set -euo pipefail
          echo "🔧 Rebuilding node-libcurl native module..."
          cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
          if [ -d "node_modules/node-libcurl" ]; then
            echo "Removing existing node-libcurl..."
            rm -rf node_modules/node-libcurl
          fi
          echo "Reinstalling node-libcurl with scripts enabled..."
          YARN_IGNORE_SCRIPTS=false yarn install
          echo "✅ node-libcurl rebuilt successfully"
        '';

      in
      pkgs.mkShell {
        buildInputs = [
          nodejs
          yarn
          pkgs.git
          nodeLib.yarnInstallWithScripts
          rebuildNodeLibcurl
        ] ++ nodeLib.commonBuildTools ++ nodeLib.browserTestingDeps;

        shellHook = ''
          echo "🚀 content-build development environment"
          echo ""
          echo "Node version: $(node --version)"
          echo "Yarn version: $(yarn --version)"
          echo "Python version: $(python3 --version)"
          echo ""
          echo "📦 Next steps:"
          echo "  1. Run 'yarn-install-with-scripts' to install dependencies (enables scripts for native modules)"
          echo "  2. Run 'yarn build' to build the static site"
          echo "  3. Run 'yarn watch' to start the dev server with watch mode"
          echo "  4. Run 'yarn serve' to serve the built site"
          echo "  5. Run 'yarn test:unit' for unit tests"
          echo "  6. Run 'yarn cy:open' for Cypress E2E tests"
          echo ""
          echo "💡 Useful commands:"
          echo "  - yarn build              # Build the static site (uses 12GB memory)"
          echo "  - yarn watch             # Build and watch for changes (port 3002)"
          echo "  - yarn serve             # Serve the built site"
          echo "  - yarn preview           # Preview build"
          echo "  - yarn test              # Run unit tests"
          echo "  - yarn cy:open           # Open Cypress test runner"
          echo "  - yarn cy:run            # Run Cypress tests headless"
          echo ""
          echo "🔧 Troubleshooting:"
          echo "  - yarn-install-with-scripts  # Install with scripts enabled (for native modules)"
          echo "  - rebuild-node-libcurl      # Rebuild node-libcurl if native module is missing"
          echo ""
          echo "🔒 Security: Scripts are disabled by default. Use yarn-install-with-scripts when needed."
          echo ""

          ${nodeLib.nodeEnvSetup}
          ${nodeLib.yarnClassicSetup}

          # Note: Scripts are disabled by default for security (Shai Hulud protection)
          # Use 'yarn-install-with-scripts' to install with scripts enabled when needed
          # (e.g., for native modules like node-libcurl)

          # Increase Node.js memory limit for content-build (uses 12GB in scripts)
          # Note: --expose-gc cannot be set in NODE_OPTIONS (must be passed directly)
          # The package.json scripts already pass --expose-gc directly
          export NODE_OPTIONS="--max-old-space-size=12288"

          # Set PKG_CONFIG_PATH for node-libcurl to find libcurl
          export PKG_CONFIG_PATH="${pkgs.curl.dev}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"

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
