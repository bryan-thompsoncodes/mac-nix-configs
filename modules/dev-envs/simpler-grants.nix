{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.simpler-grants = let
      nodeLib = import ./_nodeLib.nix { inherit pkgs; };

      # Node.js 20 for simpler-grants-protocol (matches CI: node-version "20.x")
      nodejs = pkgs.nodejs_20;

    in
    pkgs.mkShell {
      buildInputs = [
        nodejs
        pkgs.nodePackages.pnpm
        pkgs.python311
        # poetry is NOT included due to aarch64-darwin build issues with rapidfuzz
        # Install poetry via Homebrew: brew install poetry
        # Or via pipx: pipx install poetry
        pkgs.ruff
        pkgs.black
        pkgs.pyright
        pkgs.git
      ] ++ nodeLib.commonBuildTools;

      shellHook = ''
        echo "🚀 simpler-grants-protocol development environment"
        echo ""
        echo "Node version: $(node --version)"
        echo "Python version: $(python3 --version)"
        if command -v poetry &> /dev/null; then
          echo "Poetry version: $(poetry --version 2>&1 | head -1)"
        else
          echo "⚠️  Poetry not found! Install via: brew install poetry"
        fi
        echo ""
        echo "📦 Next steps:"
        echo "  1. Run 'corepack pnpm install' to install Node dependencies"
        echo "  2. Run 'cd lib/python-sdk && poetry install' for Python SDK"
        echo "  3. Run 'pnpm build' to build packages"
        echo ""
        echo "💡 Useful commands:"
        echo "  - pnpm build              # Build all packages"
        echo "  - pnpm test               # Run tests"
        echo "  - pnpm lint               # Lint all packages"
        echo "  - cd templates/fast-api && make test   # Run FastAPI template tests"
        echo "  - cd lib/python-sdk && poetry run pytest  # Run Python SDK tests"
        echo ""

        ${nodeLib.nodeEnvSetup}

        # Override: this project uses ESLint 9 flat config
        unset ESLINT_USE_FLAT_CONFIG

        # Corepack for pnpm version management (reads packageManager from package.json)
        # NOTE: corepack enable cannot run in shellHook (nix store is read-only)
        # Users should run: corepack prepare pnpm@10.18.3 --activate
        # Then use: corepack pnpm install (or just pnpm if shims are in PATH)
        export COREPACK_HOME="''${HOME}/.cache/corepack"

        # Ensure Poetry uses the nix-provided Python and creates .venv in-project
        export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true
        export POETRY_VIRTUALENVS_IN_PROJECT=true
      '';
    };
  };
}
