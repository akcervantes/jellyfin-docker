# Media Automation Stack - Test Runner (Windows PowerShell)
# Entry point for running tests on Windows systems

param(
    [switch]$TestMode,
    [switch]$Cleanup,
    [switch]$SkipSetup,
    [switch]$Help
)

# Function to display usage information
function Show-Usage {
    Write-Host ""
    Write-Host "Media Automation Stack - Test Runner (Windows)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\test-runner.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  -TestMode      Run in test mode (cleanup after tests)" -ForegroundColor Gray
    Write-Host "  -Cleanup       Cleanup existing containers before testing" -ForegroundColor Gray
    Write-Host "  -SkipSetup     Skip environment setup (use existing .env)" -ForegroundColor Gray
    Write-Host "  -Help          Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\test-runner.ps1                Run tests with existing setup" -ForegroundColor Gray
    Write-Host "  .\test-runner.ps1 -TestMode     Run tests in clean environment with cleanup" -ForegroundColor Gray
    Write-Host "  .\test-runner.ps1 -Cleanup      Cleanup existing containers and run tests" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Show help if requested
if ($Help) {
    Show-Usage
}

# Banner
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Media Automation Stack - Test Runner" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Platform: Windows"
Write-Host "Test Mode: $TestMode"
Write-Host "Cleanup: $Cleanup"
Write-Host "Skip Setup: $SkipSetup"
Write-Host ""

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Navigate to project root
Set-Location $ProjectRoot

# Check if Docker is available
Write-Host "Checking Docker installation..." -ForegroundColor Blue
try {
    $dockerVersion = docker --version 2>$null
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Check if Docker daemon is running
Write-Host "Checking Docker daemon..." -ForegroundColor Blue
try {
    docker info > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker daemon is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker daemon is not running" -ForegroundColor Red
        Write-Host "Please start Docker Desktop" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Cannot connect to Docker daemon" -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is available
Write-Host "Checking Docker Compose..." -ForegroundColor Blue
try {
    $composeVersion = docker compose version 2>$null
    Write-Host "✓ Docker Compose found: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose is not available" -ForegroundColor Red
    exit 1
}

# Cleanup existing containers if requested
if ($Cleanup) {
    Write-Host ""
    Write-Host "Cleaning up existing containers..." -ForegroundColor Yellow
    if (Test-Path "docker-compose.yml") {
        docker compose down -v 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Cleanup completed" -ForegroundColor Green
        }
    }
    Write-Host ""
}

# Setup test environment if not skipping
if (-not $SkipSetup -and $TestMode) {
    Write-Host "Setting up test environment..." -ForegroundColor Blue

    # Create temporary media directory
    $TempMedia = Join-Path $env:TEMP "media-automation-test-$PID"
    New-Item -ItemType Directory -Force -Path "$TempMedia\movies" | Out-Null
    New-Item -ItemType Directory -Force -Path "$TempMedia\tvshows" | Out-Null
    New-Item -ItemType Directory -Force -Path "$TempMedia\downloads\movies" | Out-Null
    New-Item -ItemType Directory -Force -Path "$TempMedia\downloads\tvshows" | Out-Null

    # Convert Windows path to Unix-style path for Docker
    $DockerPath = $TempMedia -replace '\\', '/' -replace '^([A-Z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }

    # Create test .env file
    $envContent = @"
MEDIA_PATH=$DockerPath
PUID=1000
PGID=1000
TZ=UTC
JELLYFIN_PORT=8096
QBITTORRENT_PORT=8888
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
JELLYSEERR_PORT=5055
FLARESOLVERR_PORT=8191
"@

    $envContent | Out-File -FilePath ".env" -Encoding ASCII -NoNewline

    Write-Host "✓ Test environment configured" -ForegroundColor Green
    Write-Host ""

    $env:MEDIA_PATH = $DockerPath
}

# Set environment variable for test mode
if ($TestMode) {
    $env:TEST_MODE = "true"
} else {
    $env:TEST_MODE = "false"
}

# Check if bash is available (Git Bash, WSL, or Cygwin)
Write-Host "Checking for bash availability..." -ForegroundColor Blue

$bashPath = $null

# Try to find bash
$bashLocations = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files (x86)\Git\bin\bash.exe",
    "bash.exe"  # In PATH
)

foreach ($location in $bashLocations) {
    if (Get-Command $location -ErrorAction SilentlyContinue) {
        $bashPath = $location
        break
    }
}

if (-not $bashPath) {
    Write-Host "✗ bash not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "This test suite requires bash to run." -ForegroundColor Yellow
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "  1. Git for Windows (includes Git Bash): https://git-scm.com/download/win" -ForegroundColor Gray
    Write-Host "  2. Windows Subsystem for Linux (WSL): https://docs.microsoft.com/en-us/windows/wsl/install" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-Host "✓ bash found at: $bashPath" -ForegroundColor Green
Write-Host ""

# Run the test suite using bash
Write-Host "Running test suite..." -ForegroundColor Blue
Write-Host ""

$testScript = Join-Path $ScriptDir "test-installation.sh"
$testScriptUnix = $testScript -replace '\\', '/'

try {
    & $bashPath -c "cd '$ProjectRoot' && bash '$testScriptUnix'"
    $exitCode = $LASTEXITCODE
} catch {
    Write-Host ""
    Write-Host "✗ Test execution failed: $_" -ForegroundColor Red
    $exitCode = 1
}

# Display results
Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   ✓ All tests passed successfully!    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║   ✗ Some tests failed!                 ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Red
}
Write-Host ""

# Cleanup test environment if in test mode
if ($TestMode) {
    Write-Host "Cleaning up test environment..." -ForegroundColor Blue

    # Stop and remove containers
    docker compose down -v 2>$null | Out-Null

    # Remove test .env file
    if (Test-Path ".env") {
        Remove-Item ".env" -Force
    }

    # Remove temporary media directory
    if ($TempMedia -and (Test-Path $TempMedia)) {
        Remove-Item $TempMedia -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "✓ Test environment cleaned up" -ForegroundColor Green
    Write-Host ""
}

# Summary
if ($exitCode -eq 0) {
    Write-Host "Test run completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Test run completed with failures (exit code: $exitCode)" -ForegroundColor Red
}

exit $exitCode
