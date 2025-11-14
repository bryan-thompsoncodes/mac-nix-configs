#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq common-updater-scripts

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_FILE="$SCRIPT_DIR/default.nix"

# Query API for latest version and URLs
echo "Fetching latest Cursor version..."
LINUX_X64=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/linux-x64/cursor")
LINUX_ARM64=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/linux-arm64/cursor")
DARWIN_X64=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/darwin-x64/cursor")
DARWIN_ARM64=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/darwin-arm64/cursor")

# Extract version (should be same for all platforms)
VERSION=$(echo "$LINUX_X64" | jq -r '.version')
echo "Found version: $VERSION"

# Check current version (extract directly from the file)
CURRENT_VERSION=$(grep -m 1 'version = "' "$PACKAGE_FILE" | sed 's/.*version = "\([^"]*\)";/\1/' || echo "")
echo "Current version: ${CURRENT_VERSION:-(not found)}"
if [ -n "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" = "$VERSION" ]; then
  echo "Already at latest version $VERSION"
  exit 0
fi

# Extract URLs
URL_LINUX_X64=$(echo "$LINUX_X64" | jq -r '.downloadUrl')
URL_LINUX_ARM64=$(echo "$LINUX_ARM64" | jq -r '.downloadUrl')
URL_DARWIN_X64=$(echo "$DARWIN_X64" | jq -r '.downloadUrl')
URL_DARWIN_ARM64=$(echo "$DARWIN_ARM64" | jq -r '.downloadUrl')

echo "Fetching hashes..."
HASH_LINUX_X64=$(nix-prefetch-url "$URL_LINUX_X64" 2>&1 | tail -1 | xargs nix-hash --to-sri --type sha256)
HASH_LINUX_ARM64=$(nix-prefetch-url "$URL_LINUX_ARM64" 2>&1 | tail -1 | xargs nix-hash --to-sri --type sha256)
HASH_DARWIN_X64=$(nix-prefetch-url "$URL_DARWIN_X64" 2>&1 | tail -1 | xargs nix-hash --to-sri --type sha256)
HASH_DARWIN_ARM64=$(nix-prefetch-url "$URL_DARWIN_ARM64" 2>&1 | tail -1 | xargs nix-hash --to-sri --type sha256)

echo "Updating $PACKAGE_FILE..."

# Update version
sed -i "s/version = \"[^\"]*\";/version = \"$VERSION\";/" "$PACKAGE_FILE"

# Update x86_64-linux
sed -i "/x86_64-linux = fetchurl {/,/};/{
  s|url = \"[^\"]*\";|url = \"$URL_LINUX_X64\";|
  s|hash = \"[^\"]*\";|hash = \"$HASH_LINUX_X64\";|
}" "$PACKAGE_FILE"

# Update aarch64-linux
sed -i "/aarch64-linux = fetchurl {/,/};/{
  s|url = \"[^\"]*\";|url = \"$URL_LINUX_ARM64\";|
  s|hash = \"[^\"]*\";|hash = \"$HASH_LINUX_ARM64\";|
}" "$PACKAGE_FILE"

# Update x86_64-darwin
sed -i "/x86_64-darwin = fetchurl {/,/};/{
  s|url = \"[^\"]*\";|url = \"$URL_DARWIN_X64\";|
  s|hash = \"[^\"]*\";|hash = \"$HASH_DARWIN_X64\";|
}" "$PACKAGE_FILE"

# Update aarch64-darwin
sed -i "/aarch64-darwin = fetchurl {/,/};/{
  s|url = \"[^\"]*\";|url = \"$URL_DARWIN_ARM64\";|
  s|hash = \"[^\"]*\";|hash = \"$HASH_DARWIN_ARM64\";|
}" "$PACKAGE_FILE"

echo "Done! Updated to version $VERSION"
