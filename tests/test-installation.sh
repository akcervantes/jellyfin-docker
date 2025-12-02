#!/bin/bash

# Media Automation Stack - Installation Test Suite
# This script validates the installation and health of all services

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source the helper library
# shellcheck source=test-helpers.sh
source "${SCRIPT_DIR}/test-helpers.sh"

# Configuration
MEDIA_PATH="${MEDIA_PATH:-/tmp/media-test}"
TEST_MODE="${TEST_MODE:-false}"

# Service definitions
declare -A SERVICES=(
    ["jellyseerr"]="5055"
    ["jellyfin"]="8096"
    ["sonarr"]="8989"
    ["radarr"]="7878"
    ["prowlarr"]="9696"
    ["qbittorrent"]="8888"
    ["flaresolverr"]="8191"
)

NETWORK_NAME="media-network"

# Banner
echo -e "${BLUE}"
echo "========================================"
echo "  Media Automation Stack Test Suite"
echo "========================================"
echo -e "${NC}\n"

# Phase 1: Pre-Installation Tests
test_prerequisites() {
    log_step "Phase 1: Testing Prerequisites"

    check_docker_installed || exit 1
    check_docker_running || exit 1
    check_docker_compose || exit 1

    log_info "Checking curl availability"
    if ! command_exists curl; then
        log_error "curl is not installed (required for HTTP checks)"
        exit 1
    fi

    log_success "All prerequisites met"
}

# Phase 2: Port Availability Tests
test_port_availability() {
    log_step "Phase 2: Testing Port Availability"

    local all_ports_available=true

    for service in "${!SERVICES[@]}"; do
        local port="${SERVICES[$service]}"
        if ! check_port_available "$port" "$service"; then
            all_ports_available=false
        fi
    done

    if [ "$all_ports_available" = false ]; then
        log_error "Some required ports are in use. Please free them before continuing."
        return 1
    fi

    log_success "All required ports are available"
}

# Phase 3: Environment Configuration Tests
test_environment_configuration() {
    log_step "Phase 3: Testing Environment Configuration"

    # Load .env file if it exists
    if [ -f "${PROJECT_ROOT}/.env" ]; then
        log_info "Loading environment from .env file"
        # Export variables from .env file
        set -a
        # shellcheck source=/dev/null
        source "${PROJECT_ROOT}/.env"
        set +a

        check_file_exists "${PROJECT_ROOT}/.env" "Environment configuration file"

        # Check critical environment variables
        check_env_var "MEDIA_PATH" "Media storage path"
        check_env_var "PUID" "User ID"
        check_env_var "PGID" "Group ID"
        check_env_var "TZ" "Timezone"

        # Check if media path exists
        if [ -n "$MEDIA_PATH" ]; then
            check_disk_space "$MEDIA_PATH" 5
        fi
    else
        log_warning ".env file not found - assuming test mode with defaults"
    fi
}

# Phase 4: Directory Structure Tests
test_directory_structure() {
    log_step "Phase 4: Testing Directory Structure"

    if [ -n "$MEDIA_PATH" ] && [ -d "$MEDIA_PATH" ]; then
        check_directory_exists "$MEDIA_PATH" "Media root directory"
        check_directory_exists "${MEDIA_PATH}/movies" "Movies directory"
        check_directory_exists "${MEDIA_PATH}/tvshows" "TV shows directory"
        check_directory_exists "${MEDIA_PATH}/downloads" "Downloads directory"
        check_directory_exists "${MEDIA_PATH}/downloads/movies" "Movie downloads directory"
        check_directory_exists "${MEDIA_PATH}/downloads/tvshows" "TV show downloads directory"
    else
        log_warning "MEDIA_PATH not set or doesn't exist, skipping directory structure tests"
    fi
}

# Phase 5: Docker Compose Configuration Tests
test_docker_compose_config() {
    log_step "Phase 5: Testing Docker Compose Configuration"

    check_file_exists "${PROJECT_ROOT}/docker-compose.yml" "Docker Compose configuration"

    count_test
    log_info "Validating Docker Compose configuration"
    if docker compose -f "${PROJECT_ROOT}/docker-compose.yml" config >/dev/null 2>&1; then
        log_success "Docker Compose configuration is valid"
    else
        log_error "Docker Compose configuration is invalid"
        docker compose -f "${PROJECT_ROOT}/docker-compose.yml" config
        return 1
    fi
}

# Phase 6: Container Startup Tests
test_container_startup() {
    log_step "Phase 6: Testing Container Startup"

    count_test
    log_info "Starting containers..."
    cd "${PROJECT_ROOT}"

    if docker compose up -d; then
        log_success "Containers started successfully"
    else
        log_error "Failed to start containers"
        return 1
    fi

    # Wait for all containers to be running
    local all_started=true
    for service in "${!SERVICES[@]}"; do
        if ! wait_for_container "$service" 90; then
            all_started=false
            get_container_logs "$service" 30
        fi
    done

    if [ "$all_started" = false ]; then
        log_error "Not all containers started successfully"
        return 1
    fi
}

# Phase 7: Container Health Tests
test_container_health() {
    log_step "Phase 7: Testing Container Health"

    local all_healthy=true

    for service in "${!SERVICES[@]}"; do
        if ! check_container_health "$service"; then
            all_healthy=false
            get_container_logs "$service" 30
        fi
    done

    if [ "$all_healthy" = false ]; then
        log_error "Not all containers are healthy"
        return 1
    fi

    log_success "All containers are healthy"
}

# Phase 8: Network Connectivity Tests
test_network_connectivity() {
    log_step "Phase 8: Testing Network Connectivity"

    check_docker_network "$NETWORK_NAME"

    local all_connected=true
    for service in "${!SERVICES[@]}"; do
        if ! check_container_network "$service" "$NETWORK_NAME"; then
            all_connected=false
        fi
    done

    if [ "$all_connected" = false ]; then
        log_error "Not all containers are connected to the network"
        return 1
    fi

    log_success "All containers are connected to the network"
}

# Phase 9: Service Accessibility Tests
test_service_accessibility() {
    log_step "Phase 9: Testing Service Accessibility"

    local all_accessible=true

    for service in "${!SERVICES[@]}"; do
        local port="${SERVICES[$service]}"
        if ! wait_for_http_service "$service" "$port" 120; then
            all_accessible=false
            get_container_logs "$service" 30
        fi
    done

    if [ "$all_accessible" = false ]; then
        log_error "Not all services are accessible"
        return 1
    fi

    log_success "All services are accessible"
}

# Phase 10: HTTP Endpoint Tests
test_http_endpoints() {
    log_step "Phase 10: Testing HTTP Endpoints"

    local all_responding=true

    for service in "${!SERVICES[@]}"; do
        local port="${SERVICES[$service]}"
        if ! test_http_endpoint "$service" "http://localhost:${port}"; then
            all_responding=false
        fi
    done

    if [ "$all_responding" = false ]; then
        log_error "Not all HTTP endpoints are responding correctly"
        return 1
    fi

    log_success "All HTTP endpoints are responding correctly"
}

# Phase 11: Volume Mount Tests
test_volume_mounts() {
    log_step "Phase 11: Testing Volume Mounts"

    count_test
    log_info "Checking volume mounts for Jellyfin"

    # Check if Jellyfin can see the media directories
    if docker exec jellyfin ls /media/movies >/dev/null 2>&1 && \
       docker exec jellyfin ls /media/tvshows >/dev/null 2>&1; then
        log_success "Jellyfin volume mounts are accessible"
    else
        log_error "Jellyfin cannot access media directories"
        return 1
    fi

    count_test
    log_info "Checking volume mounts for qBittorrent"

    # Check if qBittorrent can see the downloads directory
    if docker exec qbittorrent ls /downloads >/dev/null 2>&1; then
        log_success "qBittorrent volume mounts are accessible"
    else
        log_error "qBittorrent cannot access downloads directory"
        return 1
    fi
}

# Main test execution
main() {
    local exit_code=0

    # Run all test phases
    test_prerequisites || exit_code=$?
    [ $exit_code -ne 0 ] && exit $exit_code

    test_port_availability || exit_code=$?
    test_environment_configuration || exit_code=$?
    test_directory_structure || exit_code=$?
    test_docker_compose_config || exit_code=$?

    [ $exit_code -ne 0 ] && exit $exit_code

    test_container_startup || exit_code=$?
    [ $exit_code -ne 0 ] && {
        cleanup_test_environment
        exit $exit_code
    }

    # Give containers a moment to stabilize
    log_info "Waiting for services to stabilize..."
    sleep 10

    test_container_health || exit_code=$?
    test_network_connectivity || exit_code=$?
    test_service_accessibility || exit_code=$?
    test_http_endpoints || exit_code=$?
    test_volume_mounts || exit_code=$?

    # Print summary
    print_test_summary

    # Cleanup if in test mode
    if [ "$TEST_MODE" = "true" ]; then
        cleanup_test_environment
    fi

    exit $exit_code
}

# Handle script interruption
trap 'echo -e "\n${RED}Test interrupted${NC}"; cleanup_test_environment; exit 130' INT TERM

# Run main function
main
