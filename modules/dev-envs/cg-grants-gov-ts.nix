{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.cg-grants-gov-ts = pkgs.mkShell {
      buildInputs = [
        pkgs.nodejs_22
        pkgs.pnpm
        pkgs.git
      ];

      shellHook = ''
        echo "cg-grants-gov (TypeScript) development environment"
        echo "Node: $(node --version) | pnpm: $(pnpm --version)"

        export PATH="$PWD/node_modules/.bin:$PATH"

        if [[ ! -d node_modules ]]; then
          echo ""
          echo "Run: pnpm install"
        fi
      '';
    };
  };
}
