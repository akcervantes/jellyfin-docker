# Testing Documentation

This document describes the testing suite for the Media Automation Stack and how to run tests locally and in CI/CD.

## Table of Contents

- [Overview](#overview)
- [Test Architecture](#test-architecture)
- [Running Tests Locally](#running-tests-locally)
  - [Linux/macOS](#linuxmacos)
  - [Windows](#windows)
- [Test Phases](#test-phases)
- [CI/CD Testing](#cicd-testing)
- [Test Configuration](#test-configuration)
- [Adding New Tests](#adding-new-tests)
- [Troubleshooting](#troubleshooting)

## Overview

The testing suite validates the complete installation and operation of the Media Automation Stack across multiple platforms (Linux, macOS, and Windows). It ensures that:

- All prerequisites are met
- Docker and Docker Compose are properly configured
- All services start successfully
- Services are accessible and responding
- Network connectivity between services works
- Volume mounts have correct permissions
- The stack is ready for production use

## Test Architecture

The testing suite consists of several components:

```
tests/
├── test-helpers.sh          # Reusable test functions and utilities
├── test-installation.sh     # Main test script with all test phases
├── test-runner.sh           # Linux/macOS test runner
├── test-runner.ps1          # Windows PowerShell test runner
└── test-config.yml          # Test configuration and parameters
```

### Components

1. **test-helpers.sh**: Library of reusable functions for:
   - Color-coded output (pass/fail/info)
   - Docker status validation
   - HTTP health checks
   - Port availability checking
   - Container health monitoring
   - Test result tracking

2. **test-installation.sh**: Main test script that runs 11 test phases:
   - Prerequisites
   - Port availability
   - Environment configuration
   - Directory structure
   - Docker Compose configuration
   - Container startup
   - Container health
   - Network connectivity
   - Service accessibility
   - HTTP endpoints
   - Volume mounts

3. **test-runner.sh**: Bash wrapper for Linux/macOS that:
   - Parses command-line arguments
   - Sets up test environment
   - Runs the test suite
   - Handles cleanup

4. **test-runner.ps1**: PowerShell wrapper for Windows that:
   - Provides Windows-compatible testing
   - Handles path conversion for Docker
   - Locates and uses bash (Git Bash/WSL)
   - Manages test lifecycle

5. **test-config.yml**: Configuration file defining:
   - Service definitions and ports
   - Timeout values
   - Expected HTTP status codes
   - Directory structure
   - CI/CD platform settings

## Running Tests Locally

### Prerequisites

Before running tests, ensure you have:

- Docker installed and running
- Docker Compose available
- `curl` installed (for HTTP checks)
- Sufficient disk space (minimum 5GB)

### Linux/macOS

#### Quick Start

Run tests with the existing setup:

```bash
bash tests/test-runner.sh
```

#### Test Mode (Recommended for CI)

Run tests in an isolated environment with automatic cleanup:

```bash
bash tests/test-runner.sh --test-mode
```

This will:
- Create a temporary media directory
- Generate a test `.env` file
- Run all tests
- Clean up containers and test files

#### With Cleanup

Clean up existing containers before testing:

```bash
bash tests/test-runner.sh --cleanup
```

#### Options

```bash
bash tests/test-runner.sh [OPTIONS]

Options:
  -t, --test-mode     Run in test mode (cleanup after tests)
  -c, --cleanup       Cleanup existing containers before testing
  -s, --skip-setup    Skip environment setup (use existing .env)
  -h, --help          Show help message
```

#### Examples

```bash
# Run tests with existing setup
bash tests/test-runner.sh

# Run tests in clean environment
bash tests/test-runner.sh --test-mode

# Cleanup and test
bash tests/test-runner.sh --cleanup

# Use existing .env but cleanup containers
bash tests/test-runner.sh --cleanup --skip-setup
```

### Windows

#### Prerequisites

- Docker Desktop for Windows (installed and running)
- Git Bash (comes with Git for Windows) or WSL

#### Quick Start

Run tests with PowerShell:

```powershell
.\tests\test-runner.ps1
```

#### Test Mode

Run tests in isolated environment:

```powershell
.\tests\test-runner.ps1 -TestMode
```

#### With Cleanup

```powershell
.\tests\test-runner.ps1 -Cleanup
```

#### Options

```powershell
.\tests\test-runner.ps1 [OPTIONS]

Options:
  -TestMode      Run in test mode (cleanup after tests)
  -Cleanup       Cleanup existing containers before testing
  -SkipSetup     Skip environment setup (use existing .env)
  -Help          Show help message
```

#### Examples

```powershell
# Run tests with existing setup
.\tests\test-runner.ps1

# Run tests in clean environment
.\tests\test-runner.ps1 -TestMode

# Cleanup and test
.\tests\test-runner.ps1 -Cleanup
```

## Test Phases

The test suite runs through 11 phases:

### Phase 1: Prerequisites
- Checks Docker installation
- Verifies Docker daemon is running
- Validates Docker Compose availability
- Ensures curl is available

### Phase 2: Port Availability
Tests that all required ports are available:
- 5055 (Jellyseerr)
- 8096 (Jellyfin)
- 8989 (Sonarr)
- 7878 (Radarr)
- 9696 (Prowlarr)
- 8888 (qBittorrent)
- 8191 (FlareSolverr)

### Phase 3: Environment Configuration
- Validates `.env` file exists
- Checks required environment variables
- Verifies MEDIA_PATH exists
- Checks disk space

### Phase 4: Directory Structure
Verifies media directory structure:
- `movies/`
- `tvshows/`
- `downloads/`
- `downloads/movies/`
- `downloads/tvshows/`

### Phase 5: Docker Compose Configuration
- Validates `docker-compose.yml` syntax
- Checks service definitions
- Verifies configuration is parseable

### Phase 6: Container Startup
- Starts all containers with `docker compose up -d`
- Waits for containers to reach running state
- Monitors for startup failures

### Phase 7: Container Health
- Checks all containers are running
- Verifies no unexpected restarts
- Monitors container status

### Phase 8: Network Connectivity
- Validates Docker network exists
- Checks all containers are connected
- Verifies network isolation

### Phase 9: Service Accessibility
- Waits for services to respond on their ports
- Tests HTTP connectivity
- Validates services are ready

### Phase 10: HTTP Endpoints
- Tests each service's web interface
- Validates HTTP status codes
- Ensures proper responses

### Phase 11: Volume Mounts
- Verifies Jellyfin can access media directories
- Checks qBittorrent can access downloads
- Validates file permissions

## CI/CD Testing

### GitHub Actions

The repository includes a GitHub Actions workflow that automatically runs tests on:
- Ubuntu (latest)
- macOS (latest)
- Windows (latest)

The workflow is triggered on:
- Push to `master`, `main`, `develop`, or `feat/**` branches
- Pull requests to `master`, `main`, or `develop`
- Manual workflow dispatch

### Viewing Results

1. Navigate to the **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. View results for each platform
4. Download test artifacts if tests fail

### CI Configuration

The workflow configuration is located at:
```
.github/workflows/ci-test.yml
```

Key features:
- Matrix strategy for multi-platform testing
- Automatic Docker image caching
- Log collection on failure
- Artifact upload for debugging
- Automatic cleanup after tests

## Test Configuration

Test parameters can be customized in `tests/test-config.yml`:

### Timeouts

```yaml
timeouts:
  container_startup: 90      # Container startup timeout
  http_service: 120         # HTTP service response timeout
  service_stabilization: 10  # Wait time after startup
```

### Service Definitions

```yaml
services:
  jellyfin:
    port: 8096
    container_name: jellyfin
    health_endpoint: /
    expected_status: [200, 302]
```

### Resource Requirements

```yaml
resources:
  disk_space:
    minimum_gb: 5
    recommended_gb: 100
```

## Adding New Tests

To add new tests to the suite:

### 1. Add Helper Functions

If you need new utilities, add them to `tests/test-helpers.sh`:

```bash
# Example: Check if a service has an API key
check_service_api_key() {
    local service_name=$1
    local port=$2

    count_test
    log_step "Checking API key for ${service_name}"

    # Your test logic here
    if [ condition ]; then
        log_success "API key found for ${service_name}"
        return 0
    else
        log_error "No API key found for ${service_name}"
        return 1
    fi
}
```

### 2. Add Test Phase

Add a new test phase to `tests/test-installation.sh`:

```bash
# Phase 12: API Configuration Tests
test_api_configuration() {
    log_step "Phase 12: Testing API Configuration"

    check_service_api_key "sonarr" "8989"
    check_service_api_key "radarr" "7878"

    log_success "API configuration validated"
}
```

### 3. Call Test Phase

Add your test phase to the `main()` function:

```bash
main() {
    # ... existing phases ...

    test_api_configuration || exit_code=$?

    # ... rest of main function ...
}
```

### 4. Update Configuration

Add any new configuration to `tests/test-config.yml`:

```yaml
test_phases:
  - name: api_configuration
    description: "Validate API keys and configuration"
    required: true
```

### 5. Update Documentation

Document your new test phase in this file under [Test Phases](#test-phases).

## Troubleshooting

### Common Issues

#### Tests Fail: "Docker daemon is not running"

**Solution**: Start Docker Desktop or the Docker service:
- **Linux**: `sudo systemctl start docker`
- **macOS**: Start Docker Desktop from Applications
- **Windows**: Start Docker Desktop

#### Tests Fail: "Port already in use"

**Solution**: Stop services using the required ports or run with `--cleanup`:
```bash
bash tests/test-runner.sh --cleanup
```

To find what's using a port:
- **Linux/macOS**: `lsof -i :PORT` or `netstat -tuln | grep PORT`
- **Windows**: `netstat -ano | findstr PORT`

#### Tests Timeout: "Container failed to start"

**Solution**: Check container logs:
```bash
docker compose logs SERVICE_NAME
```

Common causes:
- Insufficient resources (memory/CPU)
- Port conflicts
- Volume mount issues
- Docker image pull failures

#### Windows: "bash not found"

**Solution**: Install Git for Windows (includes Git Bash):
- Download from: https://git-scm.com/download/win
- Or install WSL: https://docs.microsoft.com/en-us/windows/wsl/install

#### Slow Tests on macOS

**Solution**: This is expected on some Macs due to Docker performance. Tests may take longer but should still pass. Consider increasing timeouts in `test-config.yml` if needed.

### Debug Mode

For verbose output, run the test script directly:

```bash
# Linux/macOS
bash -x tests/test-installation.sh

# Windows (Git Bash)
bash -x tests/test-installation.sh
```

### Manual Testing

To manually inspect the environment after tests:

1. Run tests with `--skip-setup` to keep containers running
2. Inspect containers: `docker compose ps`
3. Check logs: `docker compose logs`
4. Test services manually in browser
5. Cleanup when done: `docker compose down -v`

### Getting Help

If tests continue to fail:

1. Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide
2. Review container logs: `docker compose logs`
3. Check system resources: `docker stats`
4. Open an issue with:
   - Platform (OS and version)
   - Docker version: `docker --version`
   - Test output and error messages
   - Container logs

## Test Results Interpretation

### Success

```
╔════════════════════════════════════════╗
║   ✓ All tests passed successfully!    ║
╚════════════════════════════════════════╝
```

All services are installed correctly and ready for use.

### Failure

```
╔════════════════════════════════════════╗
║   ✗ Some tests failed!                 ║
╚════════════════════════════════════════╝
```

Review the output to see which phase failed and follow troubleshooting steps above.

### Partial Success

Some tests may show warnings but still pass. This is acceptable but review warnings to ensure optimal configuration.

## Continuous Integration

### Local CI Testing

To simulate CI environment locally:

```bash
# Linux/macOS
bash tests/test-runner.sh --test-mode

# Windows
.\tests\test-runner.ps1 -TestMode
```

This creates an isolated environment similar to CI runners.

### CI Best Practices

1. Always run tests in test mode for CI
2. Use cleanup to ensure fresh environment
3. Set appropriate timeouts for slower runners
4. Collect logs on failure for debugging
5. Cache Docker images to speed up tests

## Performance

Typical test execution times:

- **Ubuntu**: 5-8 minutes
- **macOS**: 8-12 minutes
- **Windows**: 10-15 minutes

Times include:
- Docker image pulls
- Container startup
- Service initialization
- All test phases
- Cleanup

## License

This testing suite is part of the Media Automation Stack project. See the main README for license information.
