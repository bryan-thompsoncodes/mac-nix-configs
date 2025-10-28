{ pkgs }:

let
  # Node.js 22 for component-library (closest to 22.17.0 specified in .nvmrc)
  nodejs = pkgs.nodejs_22;

  # Yarn Berry (4.x) - used by component-library
  yarn = pkgs.yarn-berry.override { inherit nodejs; };

  # System dependencies for Puppeteer (Linux-specific packages filtered out on Darwin)
  puppeteerSystemDeps = with pkgs; lib.optionals stdenv.isLinux [
    xorg.libXScrnSaver
    xorg.libXdamage
    xorg.libXtst
    xorg.libXrandr
    xorg.libxkbfile
    gtk3
    gtk2
    atk
    glib
    pango
    gdk-pixbuf
    cairo
    freetype
    fontconfig
    dbus
    nss
    nspr
    alsa-lib
    cups
    expat
    libdrm
    libxkbcommon
    libxshmfence
    mesa
    at-spi2-atk
    at-spi2-core
    xvfb-run
  ];

  # Build tools for native modules
  buildTools = with pkgs; [
    python3
    gcc
    gnumake
    pkg-config
  ];

in
pkgs.mkShell {
  buildInputs = [
    nodejs
    yarn
    pkgs.git
  ] ++ buildTools ++ puppeteerSystemDeps;

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

    # Set up environment variables
    export NODE_OPTIONS="--max-old-space-size=4096"

    # Ensure yarn uses the correct node version
    export PATH="$PWD/node_modules/.bin:$PATH"

    # Puppeteer cache location (avoid Nix store issues)
    export PLAYWRIGHT_BROWSERS_PATH="''${HOME}/.cache/ms-playwright"

    # Work around Nix store read-only issues
    export ESLINT_USE_FLAT_CONFIG=false

    # Remove nix-direnv's symlinks to Nix store source copies
    # These symlinks cause webpack/build tools to resolve to read-only store paths
    rm -rf .direnv/flake-inputs/*-source 2>/dev/null || true
  '';

  # Set library path for Puppeteer and other native bindings
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath puppeteerSystemDeps;
}
