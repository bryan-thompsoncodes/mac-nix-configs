{ pkgs }:

let
  lib = import ./lib.nix { inherit pkgs; };

  # Node.js 22 for component-library (closest to 22.17.0 specified in .nvmrc)
  nodejs = pkgs.nodejs_22;

  # Yarn Berry (4.x) - used by component-library
  yarn = pkgs.yarn-berry.override { inherit nodejs; };

in
pkgs.mkShell {
  buildInputs = [
    nodejs
    yarn
    pkgs.git
  ] ++ lib.commonBuildTools ++ lib.browserTestingDeps;

  shellHook = ''
    echo "🚀 component-library development environment"
    echo ""
    echo "Node version: $(node --version)"
    echo "Yarn version: $(yarn --version)"
    echo "Python version: $(python3 --version)"
    echo ""
    echo "📦 Next steps:"
    echo "  1. Run 'yarn workspaces foreach install' to install dependencies"
    echo "  2. Run 'npm run dev' to build all packages and start Storybook"
    echo "     (This builds: web-components → react-components → core → storybook)"
    echo "  3. Run 'yarn test' in packages/web-components/ for unit tests"
    echo ""
    echo "💡 Useful commands:"
    echo "  - npm run dev                    # Build all packages and start Storybook"
    echo "  - cd packages/web-components && yarn test"
    echo "  - cd packages/storybook && yarn storybook"
    echo ""

    ${lib.nodeEnvSetup}

    # Puppeteer cache location (avoid Nix store issues)
    export PUPPETEER_CACHE_DIR="''${HOME}/.cache/puppeteer"
  '';

  # Set library path for Puppeteer and other native bindings
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath lib.browserTestingDeps;
}
