{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.content-build = let
      lib = import ./_lib.nix { inherit pkgs; };

      # Node.js 14.15.0 as specified in .nvmrc and package.json engines
      # Cross-platform build supporting macOS (Intel/Apple Silicon) and Linux x64
      # Note: Node.js 14.15.0 has no native darwin-arm64 build (ARM64 support started in v16)
      # On Apple Silicon, the x64 binary runs via Rosetta 2 translation
      nodejs = pkgs.stdenv.mkDerivation rec {
        pname = "nodejs";
        version = "14.15.0";

        # Determine the correct Node.js binary based on platform
        src =
          if pkgs.stdenv.isDarwin then
            # macOS (both Intel and Apple Silicon use x64 binary)
            pkgs.fetchurl {
              url = "https://nodejs.org/dist/v${version}/node-v${version}-darwin-x64.tar.gz";
              sha256 = "1fcwwv4rrdpj2gxk8dl5q8q7cka32c2k0204dmrr6jcz5w6zb28k";
            }
          else if pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64 then
            # Linux x64
            pkgs.fetchurl {
              url = "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz";
              sha256 = "06qgbldrmkqiv2dav2fs4z1x0b6ykk0gh997hf0frvd3z96bkrck";
            }
          else
            throw "Unsupported platform: ${pkgs.stdenv.system}. This flake supports macOS and Linux x64 only.";

        nativeBuildInputs = if pkgs.stdenv.isLinux then [ pkgs.autoPatchelfHook ] else [];
        buildInputs = [ pkgs.makeWrapper ] ++ (if pkgs.stdenv.isLinux then [ pkgs.gcc.cc.lib ] else []);

        dontStrip = true;
        dontPatchELF = !pkgs.stdenv.isLinux;

        installPhase = ''
          mkdir -p $out
          # Handle both .tar.gz (Darwin) and .tar.xz (Linux) formats
          if [[ "$src" == *.tar.gz ]]; then
            tar -xzf $src -C $out --strip-components=1
          else
            tar -xJf $src -C $out --strip-components=1
          fi
          # Make node_modules writable to avoid permission errors
          chmod -R u+w $out/lib/node_modules || true
        '';
      };

      # Yarn 1.x (Classic)
      yarn = pkgs.yarn.override { inherit nodejs; };

      # Helper script to install with scripts enabled (for native modules like node-libcurl)
      yarnInstallWithScripts = pkgs.writeShellScriptBin "yarn-install-with-scripts" ''
        set -euo pipefail
        echo "🔓 Temporarily enabling scripts for install (required for native modules)..."
        YARN_IGNORE_SCRIPTS=false yarn install "$@"
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
          echo "✅ Install complete. Scripts remain disabled for other yarn commands."
        else
          echo "❌ Install failed with exit code $exit_code"
        fi
        exit $exit_code
      '';

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
        yarnInstallWithScripts
        rebuildNodeLibcurl
      ] ++ lib.commonBuildTools ++ lib.browserTestingDeps;

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

        ${lib.nodeEnvSetup}
        ${lib.yarnClassicSetup}

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
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath lib.browserTestingDeps;
    };
  };
}
