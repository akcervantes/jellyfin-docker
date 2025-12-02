#!/bin/bash

# Test Helper Library for Media Automation Stack
# Provides reusable functions for testing and validation

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# Increment test counter
count_test() {
    ((TESTS_RUN++))
}

# Print test summary
print_test_summary() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total Tests: ${TESTS_RUN}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    if [ ${TESTS_FAILED} -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker is installed
check_docker_installed() {
    count_test
    log_step "Checking Docker installation"
    if command_exists docker; then
        local docker_version=$(docker --version 2>/dev/null)
        log_success "Docker is installed: ${docker_version}"
        return 0
    else
        log_error "Docker is not installed"
        return 1
    fi
}

# Check if Docker daemon is running
check_docker_running() {
    count_test
    log_step "Checking Docker daemon status"
    if docker info >/dev/null 2>&1; then
        log_success "Docker daemon is running"
        return 0
    else
        log_error "Docker daemon is not running"
        return 1
    fi
}

# Check if Docker Compose is available
check_docker_compose() {
    count_test
    log_step "Checking Docker Compose availability"
    if docker compose version >/dev/null 2>&1; then
        local compose_version=$(docker compose version 2>/dev/null)
        log_success "Docker Compose is available: ${compose_version}"
        return 0
    else
        log_error "Docker Compose is not available"
        return 1
    fi
}

# Check if port is available
check_port_available() {
    local port=$1
    local service_name=$2

    count_test
    if command_exists netstat; then
        if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            log_error "Port ${port} (${service_name}) is already in use"
            return 1
        else
            log_success "Port ${port} (${service_name}) is available"
            return 0
        fi
    elif command_exists ss; then
        if ss -tuln 2>/dev/null | grep -q ":${port} "; then
            log_error "Port ${port} (${service_name}) is already in use"
            return 1
        else
            log_success "Port ${port} (${service_name}) is available"
            return 0
        fi
    elif command_exists lsof; then
        if lsof -i ":${port}" >/dev/null 2>&1; then
            log_error "Port ${port} (${service_name}) is already in use"
            return 1
        else
            log_success "Port ${port} (${service_name}) is available"
            return 0
        fi
    else
        log_warning "Cannot check port ${port} availability - no suitable tool found (netstat/ss/lsof)"
        return 0
    fi
}

# Check disk space
check_disk_space() {
    local path=$1
    local min_space_gb=${2:-10}

    count_test
    log_step "Checking disk space at ${path}"

    if [ ! -d "$path" ]; then
        log_warning "Path ${path} does not exist, skipping disk space check"
        return 0
    fi

    local available_space=$(df -BG "$path" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ -z "$available_space" ]; then
        log_warning "Cannot determine disk space at ${path}"
        return 0
    fi

    if [ "$available_space" -ge "$min_space_gb" ]; then
        log_success "Sufficient disk space: ${available_space}GB available (minimum: ${min_space_gb}GB)"
        return 0
    else
        log_error "Insufficient disk space: ${available_space}GB available (minimum: ${min_space_gb}GB)"
        return 1
    fi
}

# Wait for container to be running
wait_for_container() {
    local container_name=$1
    local timeout=${2:-60}
    local elapsed=0

    log_info "Waiting for container '${container_name}' to start (timeout: ${timeout}s)"

    while [ $elapsed -lt $timeout ]; do
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            local status=$(docker inspect --format='{{.State.Status}}' "${container_name}" 2>/dev/null)
            if [ "$status" = "running" ]; then
                log_success "Container '${container_name}' is running"
                return 0
            fi
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done

    log_error "Container '${container_name}' failed to start within ${timeout}s"
    return 1
}

# Wait for HTTP service to respond
wait_for_http_service() {
    local service_name=$1
    local port=$2
    local timeout=${3:-120}
    local elapsed=0
    local host=${4:-localhost}

    log_info "Waiting for ${service_name} on http://${host}:${port} (timeout: ${timeout}s)"

    while [ $elapsed -lt $timeout ]; do
        if curl -s -o /dev/null -w "%{http_code}" "http://${host}:${port}" >/dev/null 2>&1; then
            local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://${host}:${port}" 2>/dev/null)
            # Accept any response (200-499) as the service is responding
            if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 500 ]; then
                log_success "${service_name} is responding (HTTP ${http_code})"
                return 0
            fi
        fi
        sleep 3
        elapsed=$((elapsed + 3))
    done

    log_error "${service_name} failed to respond within ${timeout}s"
    return 1
}

# Check container health
check_container_health() {
    local container_name=$1

    count_test
    log_step "Checking health of container '${container_name}'"

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log_error "Container '${container_name}' is not running"
        return 1
    fi

    local status=$(docker inspect --format='{{.State.Status}}' "${container_name}" 2>/dev/null)
    local restart_count=$(docker inspect --format='{{.RestartCount}}' "${container_name}" 2>/dev/null)

    if [ "$status" = "running" ] && [ "$restart_count" -eq 0 ]; then
        log_success "Container '${container_name}' is healthy (running, no restarts)"
        return 0
    elif [ "$status" = "running" ]; then
        log_warning "Container '${container_name}' is running but has restarted ${restart_count} time(s)"
        return 0
    else
        log_error "Container '${container_name}' is not healthy (status: ${status})"
        return 1
    fi
}

# Check Docker network exists
check_docker_network() {
    local network_name=$1

    count_test
    log_step "Checking Docker network '${network_name}'"

    if docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"; then
        log_success "Docker network '${network_name}' exists"
        return 0
    else
        log_error "Docker network '${network_name}' does not exist"
        return 1
    fi
}

# Check container is connected to network
check_container_network() {
    local container_name=$1
    local network_name=$2

    count_test
    log_step "Checking if '${container_name}' is connected to '${network_name}'"

    local networks=$(docker inspect --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "${container_name}" 2>/dev/null)

    if echo "$networks" | grep -q "$network_name"; then
        log_success "Container '${container_name}' is connected to '${network_name}'"
        return 0
    else
        log_error "Container '${container_name}' is not connected to '${network_name}'"
        return 1
    fi
}

# Check if file exists
check_file_exists() {
    local file_path=$1
    local description=$2

    count_test
    log_step "Checking if ${description} exists"

    if [ -f "$file_path" ]; then
        log_success "${description} exists at ${file_path}"
        return 0
    else
        log_error "${description} not found at ${file_path}"
        return 1
    fi
}

# Check if directory exists
check_directory_exists() {
    local dir_path=$1
    local description=$2

    count_test
    log_step "Checking if ${description} exists"

    if [ -d "$dir_path" ]; then
        log_success "${description} exists at ${dir_path}"
        return 0
    else
        log_error "${description} not found at ${dir_path}"
        return 1
    fi
}

# Check environment variable
check_env_var() {
    local var_name=$1
    local description=$2

    count_test

    if [ -n "${!var_name}" ]; then
        log_success "${description} is set (${var_name}=${!var_name})"
        return 0
    else
        log_error "${description} is not set (${var_name})"
        return 1
    fi
}

# Get container logs
get_container_logs() {
    local container_name=$1
    local lines=${2:-50}

    log_info "Last ${lines} lines of logs for '${container_name}':"
    echo "----------------------------------------"
    docker logs --tail ${lines} "${container_name}" 2>&1 || echo "Failed to retrieve logs"
    echo "----------------------------------------"
}

# Cleanup test environment
cleanup_test_environment() {
    log_step "Cleaning up test environment"

    if [ -f "docker-compose.yml" ]; then
        log_info "Stopping and removing containers..."
        docker compose down -v >/dev/null 2>&1 || true
        log_success "Cleanup completed"
    else
        log_warning "docker-compose.yml not found, skipping cleanup"
    fi
}

# Test HTTP endpoint
test_http_endpoint() {
    local service_name=$1
    local url=$2

    count_test

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 500 ]; then
        log_success "${service_name} is accessible at ${url} (HTTP ${http_code})"
        return 0
    else
        log_error "${service_name} is not accessible at ${url} (HTTP ${http_code})"
        return 1
    fi
}

# Export functions for use in other scripts
export -f log_info log_success log_error log_warning log_step
export -f count_test print_test_summary
export -f command_exists check_docker_installed check_docker_running check_docker_compose
export -f check_port_available check_disk_space
export -f wait_for_container wait_for_http_service
export -f check_container_health check_docker_network check_container_network
export -f check_file_exists check_directory_exists check_env_var
export -f get_container_logs cleanup_test_environment test_http_endpoint
