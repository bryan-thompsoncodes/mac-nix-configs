#!/usr/bin/env bash

# Direnv Setup Script for VA Repositories
# Creates .envrc files to automatically load nix development environments
# when entering VA repo directories

set -e

# Color codes for output (using tput for system colors)
if command -v tput &> /dev/null && [ -t 1 ]; then
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    NC=$(tput sgr0) # No Color
else
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    BOLD='\033[1m'
fi

# Configuration
BASE_DIR="$HOME/code/department-of-veterans-affairs"
FLAKE_PATH="$HOME/code/nix-configs"

# Repositories and their matching dev shells (indexed arrays for Bash 3.2)
REPOS=("vets-website" "next-build" "vets-api" "component-library")
REPO_ENVS=("vets-website" "next-build" "vets-api" "component-library")

# Arrays to track status
declare -a REPOS_WITH_ENVRC=()
declare -a REPOS_MISSING=()
declare -a REPOS_TO_CREATE=()

echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Direnv Setup for VA Repositories${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""

# Check prerequisites
if ! command -v direnv &> /dev/null; then
    echo -e "${RED}Error: direnv is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install direnv first:${NC}"
    echo -e "  brew install direnv"
    echo -e "  # Then add to your shell config (already in .zshrc if using dotfiles)"
    exit 1
fi

echo -e "${BLUE}Checking repositories and .envrc files...${NC}"
echo ""

# Check each repository
for idx in "${!REPOS[@]}"; do
    repo="${REPOS[$idx]}"
    env_name="${REPO_ENVS[$idx]}"
    repo_path="$BASE_DIR/$repo"
    envrc_path="$repo_path/.envrc"

    if [ ! -d "$repo_path" ]; then
        echo -e "  ${RED}✗${NC} $repo (repository not found)"
        REPOS_MISSING+=("$repo")
    elif [ -f "$envrc_path" ]; then
        echo -e "  ${GREEN}✓${NC} $repo (.envrc already exists)"
        REPOS_WITH_ENVRC+=("$repo")
    else
        echo -e "  ${YELLOW}○${NC} $repo (.envrc missing)"
        REPOS_TO_CREATE+=("$repo::$env_name")
    fi
done

echo ""

# If repos are missing, show warning
if [ ${#REPOS_MISSING[@]} -gt 0 ]; then
    echo -e "${YELLOW}Warning: The following repositories were not found:${NC}"
    for repo in "${REPOS_MISSING[@]}"; do
        echo -e "  - $repo"
    done
    echo ""
    echo -e "${YELLOW}Run the setup-va-repos.sh script first to clone repositories.${NC}"
    echo ""
fi

# If no repos need .envrc creation, exit
if [ ${#REPOS_TO_CREATE[@]} -eq 0 ]; then
    echo -e "${GREEN}All repositories already have .envrc files!${NC}"
    echo -e "${GREEN}Nothing to do.${NC}"
    exit 0
fi

# Display summary and ask for confirmation
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""
echo -e "  ${GREEN}Already configured:${NC} ${#REPOS_WITH_ENVRC[@]}"
echo -e "  ${RED}Repositories not found:${NC} ${#REPOS_MISSING[@]}"
echo -e "  ${YELLOW}.envrc files to create:${NC} ${#REPOS_TO_CREATE[@]}"
echo ""

if [ ${#REPOS_TO_CREATE[@]} -gt 0 ]; then
    echo -e "${YELLOW}The following .envrc files will be created:${NC}"
    for entry in "${REPOS_TO_CREATE[@]}"; do
        repo="${entry%%::*}"
        env_name="${entry##*::}"
        echo -e "  - $repo → use flake $FLAKE_PATH#$env_name"
    done
    echo ""
fi

# Ask for confirmation
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cancelled by user.${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Creating .envrc Files${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""

# Create .envrc files
CREATED_COUNT=0
declare -a CREATED_REPOS=()

for entry in "${REPOS_TO_CREATE[@]}"; do
    repo="${entry%%::*}"
    env_name="${entry##*::}"
    repo_path="$BASE_DIR/$repo"
    envrc_path="$repo_path/.envrc"
    flake_ref="$FLAKE_PATH#$env_name"

    echo -e "${BLUE}Creating .envrc for ${repo}...${NC}"

    # Create .envrc file
    cat > "$envrc_path" << EOF
# Automatically load nix development environment
use flake $flake_ref

# Watch for flake changes to trigger reload
watch_file $FLAKE_PATH/dev-envs/${repo}.nix

# Add any repo-specific environment variables below
EOF

    if [ -f "$envrc_path" ]; then
        echo -e "${GREEN}✓ Created .envrc for ${repo}${NC}"
        CREATED_COUNT=$((CREATED_COUNT + 1))
        CREATED_REPOS+=("$repo::$env_name")
    else
        echo -e "${RED}✗ Failed to create .envrc for ${repo}${NC}"
    fi
    echo ""
done

# Display final summary
echo -e "${BOLD}${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete${NC}"
echo -e "${BOLD}${BLUE}========================================${NC}"
echo ""
echo -e "  ${GREEN}Created .envrc files:${NC} $CREATED_COUNT"
echo -e "  ${YELLOW}Already configured:${NC} ${#REPOS_WITH_ENVRC[@]}"

if [ ${#REPOS_MISSING[@]} -gt 0 ]; then
    echo -e "  ${RED}Repositories not found:${NC} ${#REPOS_MISSING[@]}"
fi

echo ""

if [ $CREATED_COUNT -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Important Next Step:${NC}"
    echo ""
    echo -e "For each repository, direnv needs to be allowed to load the environment."
    echo ""

    # Ask if user wants to automatically run direnv allow
    read -p "Would you like to automatically run 'direnv allow' for all new .envrc files? (y/n) " -n 1 -r
    echo ""
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BOLD}${BLUE}========================================${NC}"
        echo -e "${BLUE}Allowing Direnv Environments${NC}"
        echo -e "${BOLD}${BLUE}========================================${NC}"
        echo ""

        ALLOWED_COUNT=0

        for entry in "${CREATED_REPOS[@]}"; do
            repo="${entry%%::*}"
            repo_path="$BASE_DIR/$repo"
            echo -e "${BLUE}Allowing direnv for ${repo}...${NC}"

            if (cd "$repo_path" && direnv allow); then
                echo -e "${GREEN}✓ Direnv allowed for ${repo}${NC}"
                ALLOWED_COUNT=$((ALLOWED_COUNT + 1))
            else
                echo -e "${RED}✗ Failed to allow direnv for ${repo}${NC}"
            fi
            echo ""
        done

        echo -e "${GREEN}Successfully allowed direnv for ${ALLOWED_COUNT}/${CREATED_COUNT} repositories.${NC}"
        echo ""
    else
        echo -e "${YELLOW}Skipped automatic direnv allow.${NC}"
        echo ""
        echo -e "You can manually allow direnv for each repository:"
        echo ""
        for entry in "${CREATED_REPOS[@]}"; do
            repo="${entry%%::*}"
            echo -e "  ${BLUE}cd $BASE_DIR/$repo && direnv allow${NC}"
        done
        echo ""
        echo -e "${YELLOW}Or simply cd into each directory and run 'direnv allow' when prompted.${NC}"
        echo ""
    fi
fi

echo -e "${GREEN}All .envrc files are ready!${NC}"
echo -e "${GREEN}The nix development environment will now load automatically when you cd into each repo.${NC}"
