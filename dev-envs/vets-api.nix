{ pkgs }:

let
  # Ruby 3.3.6 for vets-api
  ruby = pkgs.ruby_3_3;

in
pkgs.mkShell {
  buildInputs = [
    ruby
    pkgs.git

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

    echo ""
    echo "📦 Next steps:"
    echo "  1. Run 'redis-start' to start Redis"
    echo "  2. Run 'bundle install' to install Ruby gems"
    echo "  3. Run 'foreman start -m all=1,clamd=0,freshclam=0' to start the API server"
    echo ""
    echo "💡 Helper commands: redis-start, redis-stop"
    echo ""
  '';
}
