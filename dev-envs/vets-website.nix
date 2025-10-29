{ pkgs }:

let
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
          sha256 = "E4n1DS+fSZNzbQQIMAUTQ012MMKFNjT7E/K2nMnmnLk=";
        }
      else if pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64 then
        # Linux x64
        pkgs.fetchurl {
          url = "https://nodejs.org/dist/v${version}/node-v${version}-linux-x64.tar.xz";
          sha256 = "1awjvhqvw9g4mb9a5pwa8gfgwvxj7wvfjm35pkvfqxcdr9ihvqxk";
        }
      else
        throw "Unsupported platform: ${pkgs.stdenv.system}. This flake supports macOS and Linux x64 only.";

    buildInputs = [ pkgs.makeWrapper ];

    dontStrip = true;
    dontPatchELF = true;

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

  # Yarn 1.x
  yarn = pkgs.yarn.override { inherit nodejs; };

  # System dependencies for Cypress (Linux-specific packages filtered out on Darwin)
  cypressSystemDeps = with pkgs; lib.optionals stdenv.isLinux [
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

  # Build tools for native modules (node-sass, etc.)
  buildTools = with pkgs; [
    python3
    gcc
    gnumake
    pkg-config
    vips
  ];

in
pkgs.mkShell {
  buildInputs = [
    nodejs
    yarn
    pkgs.git
  ] ++ buildTools ++ cypressSystemDeps;

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

    # Set up environment variables
    export NODE_OPTIONS="--max-old-space-size=4096"
    export CYPRESS_INSTALL_BINARY=0

    # Ensure yarn uses the correct node version
    export PATH="$PWD/node_modules/.bin:$PATH"

    # Work around Nix store read-only issues with stylelint
    export STYLELINT_CACHE_LOCATION="''${TMPDIR:-/tmp}/stylelint-cache"
    mkdir -p "$STYLELINT_CACHE_LOCATION"

    # Remove nix-direnv's symlinks to Nix store source copies
    # These symlinks cause webpack/stylelint to resolve to read-only store paths
    rm -rf .direnv/flake-inputs/*-source 2>/dev/null || true
  '';

  # Set library path for Cypress and other native bindings
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath cypressSystemDeps;
}
