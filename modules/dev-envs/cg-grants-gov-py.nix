{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.cg-grants-gov-py = pkgs.mkShell {
      buildInputs = [
        pkgs.python311
        pkgs.poetry
        pkgs.ruff
        pkgs.black
        pkgs.mypy
        pkgs.git
      ];

      shellHook = ''
        echo "cg-grants-gov (Python) development environment"
        echo "Python: $(python3 --version 2>&1 | cut -d' ' -f2) | Poetry: $(poetry --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"

        export POETRY_VIRTUALENVS_IN_PROJECT=true

        if [[ ! -d .venv ]]; then
          echo ""
          echo "Run: make install"
        fi
      '';
    };
  };
}
