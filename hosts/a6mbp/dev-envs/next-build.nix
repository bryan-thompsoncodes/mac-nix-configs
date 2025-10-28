{ pkgs }:

let
  # Node.js 24 for next-build (closest to 24.1.0 specified in .nvmrc)
  nodejs = pkgs.nodejs_24;

  # Yarn 3.x (berry)
  yarn = pkgs.yarn-berry.override { inherit nodejs; };

  # System dependencies for Playwright (Linux-specific packages filtered out on Darwin)
  playwrightSystemDeps = with pkgs; lib.optionals stdenv.isLinux [
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

  # Tools required by vtk socks setup
  vtkDependencies = with pkgs; [
    jq
    awscli2
    openssh
  ];

in
pkgs.mkShell {
  buildInputs = [
    nodejs
    yarn
    pkgs.git
    pkgs.docker
  ] ++ buildTools ++ vtkDependencies ++ playwrightSystemDeps;

  shellHook = ''
    echo "🚀 next-build development environment"
    echo ""
    echo "Node version: $(node --version)"
    echo "Yarn version: $(yarn --version)"
    echo "Python version: $(python3 --version)"
    echo "Docker version: $(docker --version)"
    echo ""
    echo "✅ VTK dependencies available (jq, awscli2, openssh)"
    echo "   - You can run 'vtk socks setup' if needed"
    echo ""
    echo "📦 Next steps:"
    echo "  1. Run 'vtk socks on' to enable SOCKS proxy"
    echo "  2. Run 'yarn install' to install dependencies"
    echo "  3. Run 'yarn setup' to pull initial assets from vets-website"
    echo "  4. Run 'yarn redis' to start Redis in Docker"
    echo "  5. Run 'yarn dev' to start the dev server"
    echo ""
    echo "💡 Useful commands:"
    echo "  - yarn dev              # Start Next.js dev server"
    echo "  - yarn build            # Build production site"
    echo "  - yarn export           # Generate static pages"
    echo "  - yarn test             # Run tests"
    echo "  - yarn test:playwright  # Run Playwright E2E tests"
    echo "  - yarn redis            # Start Redis container"
    echo "  - yarn redis:stop       # Stop Redis container"
    echo ""

    # Set up environment variables
    export NODE_OPTIONS="--max-old-space-size=4096"

    # Ensure yarn uses the correct node version
    export PATH="$PWD/node_modules/.bin:$PATH"

    # Playwright cache location (avoid Nix store issues)
    export PLAYWRIGHT_BROWSERS_PATH="''${HOME}/.cache/ms-playwright"

    # Work around Nix store read-only issues
    export ESLINT_USE_FLAT_CONFIG=false

    # Remove nix-direnv's symlinks to Nix store source copies
    # These symlinks cause webpack/build tools to resolve to read-only store paths
    rm -rf .direnv/flake-inputs/*-source 2>/dev/null || true
  '';

  # Set library path for Playwright and other native bindings
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath playwrightSystemDeps;
}
