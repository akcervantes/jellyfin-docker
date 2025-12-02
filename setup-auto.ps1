# Media Automation Stack - Auto Setup Script for Windows PowerShell
# Run this script in PowerShell: .\setup-auto.ps1

# Check if running as administrator (optional but recommended)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some operations may fail. Consider right-clicking PowerShell and 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (Y/n)"
    if ($continue -eq 'n' -or $continue -eq 'N') {
        exit
    }
}

# Banner
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║     Media Automation Stack - Auto Setup Wizard 🚀            ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "║  This will set up and AUTO-CONFIGURE:                        ║" -ForegroundColor Cyan
Write-Host "║    ✓ Jellyfin (Media Server)                                 ║" -ForegroundColor Cyan
Write-Host "║    ✓ Sonarr (TV Shows) & Radarr (Movies)                     ║" -ForegroundColor Cyan
Write-Host "║    ✓ Prowlarr (6 Torrent Indexers pre-configured!)           ║" -ForegroundColor Cyan
Write-Host "║    ✓ qBittorrent (Download Client)                           ║" -ForegroundColor Cyan
Write-Host "║    ✓ Jellyseerr (Request Management)                         ║" -ForegroundColor Cyan
Write-Host "║    ✓ All service connections pre-configured!                 ║" -ForegroundColor Cyan
Write-Host "║                                                               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
Write-Host "[INFO] Checking if Docker is installed..." -ForegroundColor Blue
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Docker is not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Docker Desktop first:" -ForegroundColor Yellow
    Write-Host "  https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Write-Host "[✓] Docker is installed" -ForegroundColor Green

# Check if Docker Compose is available
Write-Host "[INFO] Checking if Docker Compose is available..." -ForegroundColor Blue
$composeVersion = docker compose version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker Compose is not available!" -ForegroundColor Red
    Write-Host "Please update Docker Desktop" -ForegroundColor Yellow
    exit 1
}
Write-Host "[✓] Docker Compose is available" -ForegroundColor Green

# Check if Docker is running
Write-Host "[INFO] Checking if Docker is running..." -ForegroundColor Blue
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
    exit 1
}
Write-Host "[✓] Docker is running" -ForegroundColor Green

Write-Host ""
Write-Host "All prerequisites met!" -ForegroundColor Green
Write-Host ""

# Security disclaimer
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║                    SECURITY NOTICE                            ║" -ForegroundColor Yellow
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "This setup uses pre-configured API keys for service communication." -ForegroundColor White
Write-Host ""
Write-Host "✓ Safe for local-only deployments" -ForegroundColor Green
Write-Host "✓ All services run on your local network only" -ForegroundColor Green
Write-Host "✓ You will still set your own account passwords" -ForegroundColor Green
Write-Host ""
Write-Host "⚠ Do NOT expose these services to the internet" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to continue"
Write-Host ""

# Check if .env already exists
if (Test-Path ".env") {
    Write-Host "[WARNING] .env file already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -eq 'y' -or $overwrite -eq 'Y') {
        Remove-Item ".env"
    } else {
        Write-Host "[INFO] Keeping existing .env file" -ForegroundColor Blue
    }
}

# Create .env file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "[INFO] Creating configuration file..." -ForegroundColor Blue
    Write-Host ""

    # Get media path
    Write-Host "Step 1: Media Storage Path" -ForegroundColor Yellow
    Write-Host "Enter the full path where your media will be stored." -ForegroundColor White
    Write-Host "This should be a folder on your external drive or local storage." -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  C:\Media" -ForegroundColor Gray
    Write-Host "  D:\MyMovies" -ForegroundColor Gray
    Write-Host "  E:\ExternalDrive\Media" -ForegroundColor Gray
    Write-Host ""

    while ($true) {
        $mediaPath = Read-Host "Media path"

        if ([string]::IsNullOrWhiteSpace($mediaPath)) {
            Write-Host "[ERROR] Path cannot be empty!" -ForegroundColor Red
            continue
        }

        # Convert Windows path to Docker path (C:\path -> /c/path)
        $dockerPath = $mediaPath -replace '\\', '/' -replace '^([A-Z]):', '/$1'
        $dockerPath = $dockerPath.ToLower()

        # Check if path exists
        if (-not (Test-Path $mediaPath)) {
            Write-Host "[WARNING] Path does not exist: $mediaPath" -ForegroundColor Yellow
            $create = Read-Host "Do you want to create it? (Y/n)"
            if ($create -ne 'n' -and $create -ne 'N') {
                try {
                    New-Item -ItemType Directory -Path $mediaPath -Force | Out-Null
                    Write-Host "[✓] Created directory: $mediaPath" -ForegroundColor Green
                    break
                } catch {
                    Write-Host "[ERROR] Failed to create directory: $_" -ForegroundColor Red
                    continue
                }
            }
        } else {
            Write-Host "[✓] Path exists: $mediaPath" -ForegroundColor Green
            break
        }
    }

    # Create media subdirectories
    Write-Host "[INFO] Creating media subdirectories..." -ForegroundColor Blue
    New-Item -ItemType Directory -Path "$mediaPath\movies" -Force | Out-Null
    New-Item -ItemType Directory -Path "$mediaPath\tvshows" -Force | Out-Null
    New-Item -ItemType Directory -Path "$mediaPath\downloads" -Force | Out-Null
    New-Item -ItemType Directory -Path "$mediaPath\downloads\movies" -Force | Out-Null
    New-Item -ItemType Directory -Path "$mediaPath\downloads\tvshows" -Force | Out-Null
    Write-Host "[✓] Media directories created" -ForegroundColor Green

    Write-Host ""
    Write-Host "Step 2: Timezone" -ForegroundColor Yellow
    Write-Host "Enter your timezone (e.g., America/New_York, Europe/London, Asia/Tokyo)" -ForegroundColor White
    Write-Host "See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones" -ForegroundColor White
    Write-Host ""
    $tz = Read-Host "Timezone [UTC]"
    if ([string]::IsNullOrWhiteSpace($tz)) {
        $tz = "UTC"
    }
    Write-Host "[✓] Timezone set to: $tz" -ForegroundColor Green

    # PUID/PGID not needed on Windows
    $puid = 1000
    $pgid = 1000

    # Write .env file
    Write-Host "[INFO] Writing configuration to .env file..." -ForegroundColor Blue
    $envContent = @"
# Media Automation Stack Configuration
# Generated by PowerShell setup script on $(Get-Date)

# Media Storage Path (Docker format)
MEDIA_PATH=$dockerPath

# System Configuration
PUID=$puid
PGID=$pgid
TZ=$tz

# Service Ports (default)
JELLYFIN_PORT=8096
QBITTORRENT_PORT=8888
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
JELLYSEERR_PORT=5055
FLARESOLVERR_PORT=8191
"@
    Set-Content -Path ".env" -Value $envContent
    Write-Host "[✓] .env file created successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to start services
$start = Read-Host "Do you want to start all services now? (Y/n)"

if ($start -ne 'n' -and $start -ne 'N') {
    Write-Host "[INFO] Starting services with Docker Compose..." -ForegroundColor Blue
    Write-Host ""

    # Copy template configs if they don't exist
    Write-Host "[INFO] Copying template configurations..." -ForegroundColor Blue

    New-Item -ItemType Directory -Path "config\prowlarr" -Force | Out-Null
    New-Item -ItemType Directory -Path "config\sonarr" -Force | Out-Null
    New-Item -ItemType Directory -Path "config\radarr" -Force | Out-Null
    New-Item -ItemType Directory -Path "config\qbittorrent\qBittorrent" -Force | Out-Null

    if (-not (Test-Path "config\prowlarr\config.xml") -and (Test-Path "templates\prowlarr\config.xml")) {
        Copy-Item "templates\prowlarr\config.xml" "config\prowlarr\config.xml"
        Write-Host "[✓] Prowlarr config copied" -ForegroundColor Green
    }

    if (-not (Test-Path "config\sonarr\config.xml") -and (Test-Path "templates\sonarr\config.xml")) {
        Copy-Item "templates\sonarr\config.xml" "config\sonarr\config.xml"
        Write-Host "[✓] Sonarr config copied" -ForegroundColor Green
    }

    if (-not (Test-Path "config\radarr\config.xml") -and (Test-Path "templates\radarr\config.xml")) {
        Copy-Item "templates\radarr\config.xml" "config\radarr\config.xml"
        Write-Host "[✓] Radarr config copied" -ForegroundColor Green
    }

    if (-not (Test-Path "config\qbittorrent\qBittorrent\qBittorrent.conf") -and (Test-Path "templates\qbittorrent\qBittorrent\qBittorrent.conf")) {
        Copy-Item "templates\qbittorrent\qBittorrent\qBittorrent.conf" "config\qbittorrent\qBittorrent\qBittorrent.conf"
        Write-Host "[✓] qBittorrent config copied (no authentication required for local access)" -ForegroundColor Green
    }

    docker compose up -d

    Write-Host ""
    Write-Host "[✓] All services are starting!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] Waiting for services to initialize..." -ForegroundColor Blue

    # Show a progress indicator
    for ($i = 0; $i -lt 30; $i++) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host ""
    Write-Host ""

    Write-Host "[INFO] Running automatic configuration using Docker..." -ForegroundColor Blue
    Write-Host ""

    # Use Docker to run the initialization script (works on all platforms!)
    if (Test-Path "templates\init-databases.sh") {
        Write-Host "[INFO] Using Docker-based initialization (no additional software required!)" -ForegroundColor Blue

        # Run the bash script inside a lightweight Alpine container with sqlite3
        $currentDir = (Get-Location).Path
        docker run --rm -v "${currentDir}\config:/config" -v "${currentDir}\templates:/templates" -w / alpine:latest sh -c "apk add --no-cache bash sqlite && bash /templates/init-databases.sh"

        Write-Host ""
        Write-Host "[INFO] Restarting services to apply configuration..." -ForegroundColor Blue
        docker compose restart

        Write-Host ""
        Write-Host "[✓] Automatic configuration complete!" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Initialization script not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure templates\init-databases.sh exists" -ForegroundColor White
        Write-Host "You may need to configure services manually using docs\CONFIGURATION.md" -ForegroundColor White
        Write-Host ""
    }

    # Auto-start instructions
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "Auto-Start on Boot" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "On Windows:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Docker Desktop has a built-in auto-start feature:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Open Docker Desktop" -ForegroundColor Gray
    Write-Host "2. Click the gear icon (Settings)" -ForegroundColor Gray
    Write-Host "3. Go to 'General'" -ForegroundColor Gray
    Write-Host "4. Enable 'Start Docker Desktop when you log in'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Once Docker Desktop auto-starts, your containers will" -ForegroundColor White
    Write-Host "automatically start if they have 'restart: unless-stopped'" -ForegroundColor White
    Write-Host "in docker-compose.yml (which they do!)." -ForegroundColor White
    Write-Host ""
    Write-Host "[INFO] No additional configuration needed on Windows" -ForegroundColor Blue

    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              🎉  Setup Complete with Auto-Config! 🎉          ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access your services at:" -ForegroundColor White
    Write-Host ""
    Write-Host "  Jellyseerr:    http://localhost:5055  ← Start here!" -ForegroundColor Cyan
    Write-Host "  Jellyfin:      http://localhost:8096" -ForegroundColor White
    Write-Host "  Sonarr:        http://localhost:8989" -ForegroundColor White
    Write-Host "  Radarr:        http://localhost:7878" -ForegroundColor White
    Write-Host "  Prowlarr:      http://localhost:9696" -ForegroundColor White
    Write-Host "  qBittorrent:   http://localhost:8888" -ForegroundColor White
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║          What's Pre-Configured for You:                      ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  ✓ 6 public torrent indexers in Prowlarr" -ForegroundColor Green
    Write-Host "  ✓ Prowlarr connected to Sonarr and Radarr" -ForegroundColor Green
    Write-Host "  ✓ Sonarr and Radarr connected to qBittorrent" -ForegroundColor Green
    Write-Host "  ✓ Root folders configured (/tv and /movies)" -ForegroundColor Green
    Write-Host "  ✓ Download categories set up" -ForegroundColor Green
    Write-Host ""
    Write-Host "Simplified Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Open Jellyseerr at http://localhost:5055" -ForegroundColor White
    Write-Host "  2. Sign in with Jellyfin (follow the setup wizard)" -ForegroundColor White
    Write-Host "  3. Connect Jellyseerr to Sonarr and Radarr" -ForegroundColor White
    Write-Host "  4. Start requesting movies and TV shows!" -ForegroundColor White
    Write-Host ""
    Write-Host "Authentication:" -ForegroundColor Cyan
    Write-Host "  All services: No login required for local network access!" -ForegroundColor Green
    Write-Host "  Note: Authentication is disabled for local addresses only" -ForegroundColor White
    Write-Host ""
    Write-Host "Happy streaming! 🍿" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[INFO] Services not started" -ForegroundColor Blue
    Write-Host "You can start them later with: docker compose up -d" -ForegroundColor White
    Write-Host "Then run: python templates\init-databases.py" -ForegroundColor White
    Write-Host ""
}
