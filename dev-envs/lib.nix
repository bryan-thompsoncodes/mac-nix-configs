{ pkgs }:

{
  # Common build tools needed for native Node.js modules
  commonBuildTools = with pkgs; [
    python3
    gcc
    gnumake
    pkg-config
    bun
  ];

  # Common system dependencies for browser automation tools (Cypress, Playwright, Puppeteer)
  # These are only needed on Linux; filtered out on Darwin
  browserTestingDeps = with pkgs; lib.optionals stdenv.isLinux [
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

  # Common Node.js environment setup
  nodeEnvSetup = ''
    # Increase Node.js memory limit
    export NODE_OPTIONS="--max-old-space-size=4096"

    # Ensure local node_modules/.bin is in PATH
    export PATH="$PWD/node_modules/.bin:$PATH"

    # Work around Nix store read-only issues
    export ESLINT_USE_FLAT_CONFIG=false

    # npm/Yarn supply chain hardening - disable lifecycle scripts by default
    # Re-enable selectively with: npm rebuild <package> or yarn rebuild
    export npm_config_ignore_scripts=true

    # Yarn Classic (1.x) - used by vets-website
    export YARN_IGNORE_SCRIPTS=true

    # Yarn Berry (2+) - used by next-build and component-library
    export YARN_ENABLE_SCRIPTS=false
  '';
}
