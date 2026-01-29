{ pkgs }:

{
  # Node.js 14.15.0 as specified in .nvmrc and package.json engines
  # Cross-platform build supporting macOS (Intel/Apple Silicon) and Linux x64
  # Note: Node.js 14.15.0 has no native darwin-arm64 build (ARM64 support started in v16)
  # On Apple Silicon, the x64 binary runs via Rosetta 2 translation
  nodejs14 = pkgs.stdenv.mkDerivation rec {
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

  # Common build tools needed for native Node.js modules
  commonBuildTools = with pkgs; [
    python3
    gcc
    gnumake
    pkg-config
    bun
    curl.dev  # For node-libcurl native module
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

    # npm supply chain hardening - disable lifecycle scripts by default
    # Re-enable selectively with: npm rebuild <package>
    export npm_config_ignore_scripts=true
  '';

  # Yarn Classic (1.x) environment setup - used by vets-website
  yarnClassicSetup = ''
    export YARN_IGNORE_SCRIPTS=true
  '';

  # Yarn Berry (2+) environment setup - used by next-build and component-library
  yarnBerrySetup = ''
    export YARN_ENABLE_SCRIPTS=false
  '';

  # Install wrapper for Yarn Berry - enables scripts only during install
  yarnInstallWithScripts = pkgs.writeShellScriptBin "yarn-install-with-scripts" ''
    set -euo pipefail
    echo "🔓 Temporarily enabling scripts for install..."
    YARN_ENABLE_SCRIPTS=true yarn install "$@"
    exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
      echo "✅ Install complete. Scripts remain disabled for other yarn commands."
    else
      echo "❌ Install failed with exit code $exit_code"
    fi
    exit $exit_code
  '';
}
