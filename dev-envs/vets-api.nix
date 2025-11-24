{ pkgs }:

let
  # Override Ruby 3.3 to build version 3.3.6 specifically
  # This only rebuilds Ruby, not the entire dependency tree
  ruby = pkgs.ruby_3_3.overrideAttrs (oldAttrs: rec {
    version = "3.3.6";
    src = pkgs.fetchurl {
      url = "https://cache.ruby-lang.org/pub/ruby/${pkgs.lib.versions.majorMinor version}/ruby-${version}.tar.gz";
      hash = "sha256-jcSP/68nD4bxAZBT8o5R5NpMzjKjZ2CgYDqa7mfX/Y0=";
    };
  });

in
pkgs.mkShell {
  buildInputs = [
    ruby
    pkgs.git

    # Ruby tools
    pkgs.bundler
    pkgs.foreman

    # Ruby development dependencies
    pkgs.libyaml
    pkgs.openssl
    pkgs.readline
    pkgs.zlib
    pkgs.libffi

    # Build tools for native extensions
    pkgs.pkg-config
    pkgs.gnumake
    pkgs.gcc

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
    echo "🚀 vets-api development environment"
    echo ""
    echo "Ruby version: $(ruby --version)"
    echo "Bundler version: $(bundle --version)"
    echo ""

    # Set up environment variables
    # Ruby gem environment - store gems outside repo to avoid git tracking
    export GEM_HOME="$HOME/.local/share/gems/vets-api"
    export PATH="$GEM_HOME/bin:$PATH"

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
    alias start-vets-api='foreman start -m all=1,clamd=0,freshclam=0'
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
}
