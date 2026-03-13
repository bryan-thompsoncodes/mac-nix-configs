{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.simpler-grants = let
      # Node.js 22 LTS for simpler-grants-protocol
      nodejs = pkgs.nodejs_22;

    in
    pkgs.mkShell {
      buildInputs = [
        nodejs
        # pnpm is managed via corepack (reads packageManager from package.json)
        # Do NOT add pkgs.nodePackages.pnpm — it shadows the corepack shim
        pkgs.python311
        # poetry is NOT included due to aarch64-darwin build issues with rapidfuzz
        # Install poetry via Homebrew: brew install poetry
        # Or via pipx: pipx install poetry
        pkgs.ruff
        pkgs.black
        pkgs.mypy
        pkgs.git
        # Native module build tools (subset of nodeLib.commonBuildTools)
        pkgs.gcc
        pkgs.gnumake
        pkgs.pkg-config
      ];

      shellHook = ''
        echo "🚀 simpler-grants-protocol development environment"
        echo ""
        echo "Node:   $(node --version)"
        echo "Python: $(python3 --version 2>&1 | cut -d' ' -f2)"
        if command -v poetry &> /dev/null; then
          echo "Poetry: $(poetry --version 2>&1 | grep -oP '[\d.]+')"
        else
          echo "⚠️  Poetry not found — install via: brew install poetry"
        fi
        echo ""
        if [[ ! -d node_modules ]]; then
          echo "📦 Run: pnpm install"
        fi
        if [[ ! -d lib/python-sdk/.venv ]]; then
          echo "📦 Run: cd lib/python-sdk && poetry install"
        fi
        echo ""

        # ─── Node.js environment ─────────────────────────────────
        export NODE_OPTIONS="--max-old-space-size=4096"
        export PATH="$PWD/node_modules/.bin:$PATH"

        # This project uses ESLint 9 flat config
        unset ESLINT_USE_FLAT_CONFIG

        # npm supply chain hardening
        export npm_config_ignore_scripts=true

        # ─── Corepack / pnpm ─────────────────────────────────────
        export COREPACK_HOME="''${HOME}/.cache/corepack"
        # Install corepack shims to a writable location (nix store is read-only)
        corepack enable --install-directory "''${HOME}/.local/bin" 2>/dev/null || true
        export PATH="''${HOME}/.local/bin:$PATH"

        # ─── Poetry / Python ─────────────────────────────────────
        export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true
        export POETRY_VIRTUALENVS_IN_PROJECT=true
      '';
    };
  };
}
