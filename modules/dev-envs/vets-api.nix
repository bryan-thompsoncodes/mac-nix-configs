{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    devShells.vets-api = let
      # Override Ruby 3.3 to build version 3.3.6 specifically
      # Add libyaml and openssl to buildInputs to ensure psych and openssl compile correctly
      ruby = pkgs.ruby_3_3.overrideAttrs (oldAttrs: rec {
        version = "3.3.6";
        src = pkgs.fetchurl {
          url = "https://cache.ruby-lang.org/pub/ruby/${pkgs.lib.versions.majorMinor version}/ruby-${version}.tar.gz";
          hash = "sha256-jcSP/68nD4bxAZBT8o5R5NpMzjKjZ2CgYDqa7mfX/Y0=";
        };
        # Ensure libyaml and openssl are available during Ruby compilation
        buildInputs = (oldAttrs.buildInputs or []) ++ [ pkgs.libyaml pkgs.openssl ];
      });

      # Track Ruby store path to detect when gems need rebuilding
      rubyStorePath = builtins.unsafeDiscardStringContext (builtins.toString ruby);

    in
    pkgs.mkShell {
      buildInputs = [
        ruby
        pkgs.git

        # NOTE: bundler comes with Ruby 3.3, don't use pkgs.bundler (wrong Ruby)
        # NOTE: foreman installed via `gem install foreman` to use correct Ruby

        # Ruby development dependencies
        pkgs.libyaml
        pkgs.openssl
        pkgs.readline
        pkgs.zlib
        pkgs.libffi
        pkgs.libxml2  # nokogiri
        pkgs.libxslt  # nokogiri

        # Build tools for native extensions
        pkgs.pkg-config
        pkgs.gnumake
        # Use LLVM 18 - clang 21 has warnings that break Ruby 3.3 header compilation
        pkgs.llvmPackages_18.clang

        # PostgreSQL client for vets-api
        pkgs.postgresql

        # Redis for vets-api
        pkgs.redis

        # Kafka for rdkafka gem
        pkgs.rdkafka

        # PDF manipulation tool (required by pdf-forms gem)
        pkgs.pdftk
      ];

      shellHook = ''
        # Set up environment variables FIRST (before any Ruby commands)
        # Ruby gem environment - store gems outside repo to avoid git tracking
        export GEM_HOME="$HOME/.local/share/gems/vets-api"
        export PATH="$GEM_HOME/bin:$PATH"

        # Track Ruby store path to detect native extension incompatibility
        RUBY_MARKER="$GEM_HOME/.ruby-store-path"
        CURRENT_RUBY="${rubyStorePath}"

        # Check if gems were compiled against a different Ruby
        if [ -f "$RUBY_MARKER" ]; then
          PREV_RUBY=$(cat "$RUBY_MARKER")
          if [ "$PREV_RUBY" != "$CURRENT_RUBY" ]; then
            echo "⚠️  Ruby derivation changed!"
            echo "   Previous: $PREV_RUBY"
            echo "   Current:  $CURRENT_RUBY"
            echo ""
            echo "   Native gem extensions are incompatible. Run:"
            echo "   rm -rf ~/.local/share/gems/vets-api && bundle install"
            echo ""
          fi
        fi

        # Save current Ruby path for future checks
        mkdir -p "$GEM_HOME"
        echo "$CURRENT_RUBY" > "$RUBY_MARKER"

        echo "🚀 vets-api development environment"
        echo ""
        echo "Ruby version: $(ruby --version)"
        echo "Bundler version: $(bundle --version)"
        echo ""

        # Force using clang 18 instead of system clang 21
        # Ruby 3.3 headers trigger -Wdefault-const-init-field-unsafe in clang 19+
        export CC="${pkgs.llvmPackages_18.clang}/bin/clang"
        export CXX="${pkgs.llvmPackages_18.clang}/bin/clang++"

        # PostgreSQL and Redis settings (safe defaults)
        export PGHOST="localhost"
        export REDIS_HOST="localhost"
        export REDIS_PORT="6379"

        # Redis data directory
        export REDIS_DIR="$PWD/tmp/redis"
        mkdir -p "$REDIS_DIR"

        # Helper aliases for common tasks
        alias start-redis='redis-server --daemonize yes --dir "$REDIS_DIR"'
        alias stop-redis='redis-cli shutdown'
        alias start-vets-api='bundle exec foreman start -m all=1,clamd=0,freshclam=0'
        alias setup-vets-api='bundle install && bundle exec rake db:setup'

        echo ""
        echo "📦 Quick start:"
        echo "  1. start-redis          # Start Redis in background"
        echo "  2. setup-vets-api       # Install gems and setup database (first time)"
        echo "  3. start-vets-api       # Start the API server with foreman"
        echo ""
        echo "💡 Other aliases: stop-redis"
        echo ""
      '';
    };
  };
}
