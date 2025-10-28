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
  ];

  shellHook = ''
    echo "🚀 vets-api development environment"
    echo ""
    echo "Ruby version: $(ruby --version)"
    echo "Bundler version: $(bundle --version)"
    echo ""
    echo "📦 Next steps:"
    echo "  1. Run 'bundle install' to install Ruby gems"
    echo "  2. Run 'bundle exec rails server' to start the API server"
    echo ""

    # Set up environment variables
    # Ruby gem environment
    export GEM_HOME="$PWD/.gem"
    export PATH="$GEM_HOME/bin:$PATH"

    # PostgreSQL and Redis settings (safe defaults)
    export PGHOST="localhost"
    export REDIS_HOST="localhost"
  '';
}
