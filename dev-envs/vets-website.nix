{ pkgs }:

let
  lib = import ./lib.nix { inherit pkgs; };

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

  # Yarn 1.x
  yarn = pkgs.yarn.override { inherit nodejs; };

  # Additional build tool for vets-website (vips for image processing)
  extraBuildTools = with pkgs; [
    vips
  ];

in
pkgs.mkShell {
  buildInputs = [
    nodejs
    yarn
    pkgs.git
  ] ++ lib.commonBuildTools ++ extraBuildTools ++ lib.browserTestingDeps;

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

    ${lib.nodeEnvSetup}
    ${lib.yarnClassicSetup}

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
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath lib.browserTestingDeps;
}
