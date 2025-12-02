#!/bin/bash

# Media Automation Stack - Test Runner (Linux/macOS)
# Entry point for running tests on Unix-based systems

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
TEST_MODE="false"
CLEANUP="false"
SKIP_SETUP="false"

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --test-mode     Run in test mode (cleanup after tests)"
    echo "  -c, --cleanup       Cleanup existing containers before testing"
    echo "  -s, --skip-setup    Skip environment setup (use existing .env)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  Run tests with existing setup"
    echo "  $0 --test-mode      Run tests in clean environment with cleanup"
    echo "  $0 --cleanup        Cleanup existing containers and run tests"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--test-mode)
            TEST_MODE="true"
            shift
            ;;
        -c|--cleanup)
            CLEANUP="true"
            shift
            ;;
        -s|--skip-setup)
            SKIP_SETUP="true"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Banner
echo -e "${BLUE}"
echo "=========================================="
echo "  Media Automation Stack - Test Runner"
echo "=========================================="
echo -e "${NC}"
echo "Platform: $(uname -s)"
echo "Test Mode: ${TEST_MODE}"
echo "Cleanup: ${CLEANUP}"
echo "Skip Setup: ${SKIP_SETUP}"
echo ""

# Navigate to project root
cd "${PROJECT_ROOT}"

# Cleanup existing containers if requested
if [ "$CLEANUP" = "true" ]; then
    echo -e "${YELLOW}Cleaning up existing containers...${NC}"
    if [ -f "docker-compose.yml" ]; then
        docker compose down -v 2>/dev/null || true
        echo -e "${GREEN}✓ Cleanup completed${NC}\n"
    fi
fi

# Setup test environment if not skipping
if [ "$SKIP_SETUP" = "false" ] && [ "$TEST_MODE" = "true" ]; then
    echo -e "${BLUE}Setting up test environment...${NC}"

    # Create temporary media directory
    TEMP_MEDIA="/tmp/media-automation-test-$$"
    mkdir -p "$TEMP_MEDIA"/{movies,tvshows,downloads/{movies,tvshows}}

    # Create test .env file
    cat > .env <<EOF
MEDIA_PATH=${TEMP_MEDIA}
PUID=$(id -u)
PGID=$(id -g)
TZ=UTC
JELLYFIN_PORT=8096
QBITTORRENT_PORT=8888
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
JELLYSEERR_PORT=5055
FLARESOLVERR_PORT=8191
EOF

    echo -e "${GREEN}✓ Test environment configured${NC}\n"
    export MEDIA_PATH="$TEMP_MEDIA"
fi

# Export test mode for the test script
export TEST_MODE

# Run the test suite
echo -e "${BLUE}Running test suite...${NC}\n"

if bash "${SCRIPT_DIR}/test-installation.sh"; then
    exit_code=0
    echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ All tests passed successfully!    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"
else
    exit_code=$?
    echo -e "\n${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ✗ Some tests failed!                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}\n"
fi

# Cleanup test environment if in test mode
if [ "$TEST_MODE" = "true" ]; then
    echo -e "${BLUE}Cleaning up test environment...${NC}"

    # Stop and remove containers
    docker compose down -v 2>/dev/null || true

    # Remove test .env file
    rm -f .env

    # Remove temporary media directory
    if [ -n "$TEMP_MEDIA" ] && [ -d "$TEMP_MEDIA" ]; then
        rm -rf "$TEMP_MEDIA"
    fi

    echo -e "${GREEN}✓ Test environment cleaned up${NC}\n"
fi

# Summary
if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}Test run completed successfully!${NC}"
else
    echo -e "${RED}Test run completed with failures (exit code: ${exit_code})${NC}"
fi

exit $exit_code
