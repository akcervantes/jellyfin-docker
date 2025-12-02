@echo off
REM Media Automation Stack - Auto Setup Script for Windows
REM Run this by double-clicking or: setup-auto.bat

setlocal enabledelayedexpansion

REM Check for admin privileges (optional)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo WARNING: Not running as Administrator
    echo Some operations may fail. Consider right-clicking this file and 'Run as Administrator'
    echo.
    set /p continue="Continue anyway? (Y/n): "
    if /i "!continue!"=="n" exit /b
)

REM Banner
echo.
echo ===============================================================
echo.
echo      Media Automation Stack - Auto Setup Wizard
echo.
echo   This will set up and AUTO-CONFIGURE:
echo     * Jellyfin (Media Server)
echo     * Sonarr (TV Shows) ^& Radarr (Movies)
echo     * Prowlarr (6 Torrent Indexers pre-configured!)
echo     * qBittorrent (Download Client)
echo     * Jellyseerr (Request Management)
echo     * All service connections pre-configured!
echo.
echo ===============================================================
echo.

REM Check if Docker is installed
echo [INFO] Checking if Docker is installed...
docker --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Docker is not installed!
    echo.
    echo Please install Docker Desktop first:
    echo   https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)
echo [OK] Docker is installed

REM Check if Docker Compose is available
echo [INFO] Checking if Docker Compose is available...
docker compose version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Docker Compose is not available!
    echo Please update Docker Desktop
    echo.
    pause
    exit /b 1
)
echo [OK] Docker Compose is available

REM Check if Docker is running
echo [INFO] Checking if Docker is running...
docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Docker is not running!
    echo Please start Docker Desktop and try again
    echo.
    pause
    exit /b 1
)
echo [OK] Docker is running

echo.
echo All prerequisites met!
echo.

REM Security disclaimer
echo ===============================================================
echo                    SECURITY NOTICE
echo ===============================================================
echo.
echo This setup uses pre-configured API keys for service communication.
echo.
echo [OK] Safe for local-only deployments
echo [OK] All services run on your local network only
echo [OK] You will still set your own account passwords
echo.
echo [WARNING] Do NOT expose these services to the internet
echo.
pause

REM Check if .env already exists
if exist .env (
    echo.
    echo [WARNING] .env file already exists!
    set /p overwrite="Do you want to overwrite it? (y/N): "
    if /i "!overwrite!"=="y" (
        del .env
    ) else (
        echo [INFO] Keeping existing .env file
        goto :start_services
    )
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo.
    echo [INFO] Creating configuration file...
    echo.

    REM Get media path
    echo Step 1: Media Storage Path
    echo Enter the full path where your media will be stored.
    echo This should be a folder on your external drive or local storage.
    echo.
    echo Examples:
    echo   C:\Media
    echo   D:\MyMovies
    echo   E:\ExternalDrive\Media
    echo.

    :ask_media_path
    set /p mediaPath="Media path: "

    if "!mediaPath!"=="" (
        echo [ERROR] Path cannot be empty!
        goto :ask_media_path
    )

    REM Convert Windows path to Docker path (C:\path -> /c/path)
    set dockerPath=!mediaPath:\=/!
    set dockerPath=!dockerPath::=!
    set firstChar=!dockerPath:~0,1!
    call :toLower firstChar
    set dockerPath=/!firstChar!!dockerPath:~1!

    REM Check if path exists
    if not exist "!mediaPath!" (
        echo [WARNING] Path does not exist: !mediaPath!
        set /p create="Do you want to create it? (Y/n): "
        if /i not "!create!"=="n" (
            mkdir "!mediaPath!" 2>nul
            if exist "!mediaPath!" (
                echo [OK] Created directory: !mediaPath!
            ) else (
                echo [ERROR] Failed to create directory
                goto :ask_media_path
            )
        ) else (
            goto :ask_media_path
        )
    ) else (
        echo [OK] Path exists: !mediaPath!
    )

    REM Create media subdirectories
    echo [INFO] Creating media subdirectories...
    mkdir "!mediaPath!\movies" 2>nul
    mkdir "!mediaPath!\tvshows" 2>nul
    mkdir "!mediaPath!\downloads" 2>nul
    mkdir "!mediaPath!\downloads\movies" 2>nul
    mkdir "!mediaPath!\downloads\tvshows" 2>nul
    echo [OK] Media directories created

    echo.
    echo Step 2: Timezone
    echo Enter your timezone (e.g., America/New_York, Europe/London, Asia/Tokyo)
    echo See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    echo.
    set /p tz="Timezone [UTC]: "
    if "!tz!"=="" set tz=UTC
    echo [OK] Timezone set to: !tz!

    REM PUID/PGID (default for Windows)
    set puid=1000
    set pgid=1000

    REM Write .env file
    echo [INFO] Writing configuration to .env file...
    (
        echo # Media Automation Stack Configuration
        echo # Generated by batch setup script on %date% %time%
        echo.
        echo # Media Storage Path ^(Docker format^)
        echo MEDIA_PATH=!dockerPath!
        echo.
        echo # System Configuration
        echo PUID=!puid!
        echo PGID=!pgid!
        echo TZ=!tz!
        echo.
        echo # Service Ports ^(default^)
        echo JELLYFIN_PORT=8096
        echo QBITTORRENT_PORT=8888
        echo PROWLARR_PORT=9696
        echo SONARR_PORT=8989
        echo RADARR_PORT=7878
        echo JELLYSEERR_PORT=5055
        echo FLARESOLVERR_PORT=8191
    ) > .env
    echo [OK] .env file created successfully!
)

:start_services
echo.
echo ============================================================
echo Configuration complete!
echo ============================================================
echo.

REM Ask if user wants to start services
set /p start="Do you want to start all services now? (Y/n): "

if /i not "!start!"=="n" (
    echo [INFO] Starting services with Docker Compose...
    echo.

    REM Copy template configs if they don't exist
    echo [INFO] Copying template configurations...

    if not exist "config\prowlarr" mkdir "config\prowlarr"
    if not exist "config\sonarr" mkdir "config\sonarr"
    if not exist "config\radarr" mkdir "config\radarr"
    if not exist "config\qbittorrent\qBittorrent" mkdir "config\qbittorrent\qBittorrent"

    if not exist "config\prowlarr\config.xml" (
        if exist "templates\prowlarr\config.xml" (
            copy "templates\prowlarr\config.xml" "config\prowlarr\config.xml" >nul
            echo [OK] Prowlarr config copied
        )
    )

    if not exist "config\sonarr\config.xml" (
        if exist "templates\sonarr\config.xml" (
            copy "templates\sonarr\config.xml" "config\sonarr\config.xml" >nul
            echo [OK] Sonarr config copied
        )
    )

    if not exist "config\radarr\config.xml" (
        if exist "templates\radarr\config.xml" (
            copy "templates\radarr\config.xml" "config\radarr\config.xml" >nul
            echo [OK] Radarr config copied
        )
    )

    if not exist "config\qbittorrent\qBittorrent\qBittorrent.conf" (
        if exist "templates\qbittorrent\qBittorrent\qBittorrent.conf" (
            copy "templates\qbittorrent\qBittorrent\qBittorrent.conf" "config\qbittorrent\qBittorrent\qBittorrent.conf" >nul
            echo [OK] qBittorrent config copied ^(no authentication required for local access^)
        )
    )

    docker compose up -d

    echo.
    echo [OK] All services are starting!
    echo.
    echo [INFO] Waiting for services to initialize...

    REM Show a progress indicator
    for /l %%i in (1,1,30) do (
        echo|set /p="."
        timeout /t 1 /nobreak >nul
    )
    echo.
    echo.

    echo [INFO] Running automatic configuration using Docker...
    echo.

    REM Use Docker to run the initialization script (works on all platforms!)
    if exist "templates\init-databases.sh" (
        echo [INFO] Using Docker-based initialization ^(no additional software required!^)

        REM Run the bash script inside a lightweight Alpine container with sqlite3
        docker run --rm -v "%cd%\config:/config" -v "%cd%\templates:/templates" -w / alpine:latest sh -c "apk add --no-cache bash sqlite && bash /templates/init-databases.sh"

        echo.
        echo [INFO] Restarting services to apply configuration...
        docker compose restart

        echo.
        echo [OK] Automatic configuration complete!
    ) else (
        echo [ERROR] Initialization script not found
        echo.
        echo Please ensure templates\init-databases.sh exists
        echo You may need to configure services manually using docs\CONFIGURATION.md
        echo.
    )

    REM Auto-start instructions
    echo.
    echo ===============================================================
    echo Auto-Start on Boot
    echo ===============================================================
    echo.
    echo On Windows:
    echo.
    echo Docker Desktop has a built-in auto-start feature:
    echo.
    echo 1. Open Docker Desktop
    echo 2. Click the gear icon ^(Settings^)
    echo 3. Go to 'General'
    echo 4. Enable 'Start Docker Desktop when you log in'
    echo.
    echo Once Docker Desktop auto-starts, your containers will
    echo automatically start if they have 'restart: unless-stopped'
    echo in docker-compose.yml ^(which they do!^).
    echo.
    echo [INFO] No additional configuration needed on Windows

    echo.
    echo ===============================================================
    echo          Setup Complete with Auto-Config!
    echo ===============================================================
    echo.
    echo Access your services at:
    echo.
    echo   Jellyseerr:    http://localhost:5055  ^<-- Start here!
    echo   Jellyfin:      http://localhost:8096
    echo   Sonarr:        http://localhost:8989
    echo   Radarr:        http://localhost:7878
    echo   Prowlarr:      http://localhost:9696
    echo   qBittorrent:   http://localhost:8888
    echo.
    echo ===============================================================
    echo           What's Pre-Configured for You:
    echo ===============================================================
    echo.
    echo   [OK] 6 public torrent indexers in Prowlarr
    echo   [OK] Prowlarr connected to Sonarr and Radarr
    echo   [OK] Sonarr and Radarr connected to qBittorrent
    echo   [OK] Root folders configured ^(/tv and /movies^)
    echo   [OK] Download categories set up
    echo.
    echo Simplified Next Steps:
    echo   1. Open Jellyseerr at http://localhost:5055
    echo   2. Sign in with Jellyfin ^(follow the setup wizard^)
    echo   3. Connect Jellyseerr to Sonarr and Radarr
    echo   4. Start requesting movies and TV shows!
    echo.
    echo Authentication:
    echo   All services: No login required for local network access!
    echo   Note: Authentication is disabled for local addresses only
    echo.
    echo Happy streaming!
    echo.
) else (
    echo [INFO] Services not started
    echo You can start them later with: docker compose up -d
    echo Then run: python templates\init-databases.py
    echo.
)

pause
goto :eof

REM Helper function to convert to lowercase
:toLower
set %~1=!%~1:A=a!
set %~1=!%~1:B=b!
set %~1=!%~1:C=c!
set %~1=!%~1:D=d!
set %~1=!%~1:E=e!
set %~1=!%~1:F=f!
set %~1=!%~1:G=g!
set %~1=!%~1:H=h!
set %~1=!%~1:I=i!
set %~1=!%~1:J=j!
set %~1=!%~1:K=k!
set %~1=!%~1:L=l!
set %~1=!%~1:M=m!
set %~1=!%~1:N=n!
set %~1=!%~1:O=o!
set %~1=!%~1:P=p!
set %~1=!%~1:Q=q!
set %~1=!%~1:R=r!
set %~1=!%~1:S=s!
set %~1=!%~1:T=t!
set %~1=!%~1:U=u!
set %~1=!%~1:V=v!
set %~1=!%~1:W=w!
set %~1=!%~1:X=x!
set %~1=!%~1:Y=y!
set %~1=!%~1:Z=z!
goto :eof
