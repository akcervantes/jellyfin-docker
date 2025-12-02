#!/bin/bash

# Media Automation Stack - Enhanced Auto-Setup Script
# This script includes automatic service configuration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║     Media Automation Stack - Auto Setup Wizard 🚀            ║"
echo "║                                                               ║"
echo "║  This will set up and AUTO-CONFIGURE:                        ║"
echo "║    ✓ Jellyfin (Media Server)                                 ║"
echo "║    ✓ Sonarr (TV Shows) & Radarr (Movies)                     ║"
echo "║    ✓ Prowlarr (6 Torrent Indexers pre-configured!)           ║"
echo "║    ✓ qBittorrent (Download Client)                           ║"
echo "║    ✓ Jellyseerr (Request Management)                         ║"
echo "║    ✓ All service connections pre-configured!                 ║"
echo "║                                                               ║"
echo "║  ${MAGENTA}New:${BLUE} Services will be connected automatically!            ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
print_info "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    echo ""
    echo "Please install Docker Desktop first:"
    echo "  - Windows/Mac: https://www.docker.com/products/docker-desktop"
    echo "  - Linux: https://docs.docker.com/engine/install/"
    echo ""
    exit 1
fi

print_success "Docker is installed"

# Check if Docker Compose is available
print_info "Checking if Docker Compose is available..."
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available!"
    echo "Please install Docker Compose or update Docker Desktop"
    exit 1
fi

print_success "Docker Compose is available"

# Check if Docker is running
print_info "Checking if Docker is running..."
if ! docker info &> /dev/null; then
    print_error "Docker is not running!"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

print_success "Docker is running"

echo ""
echo -e "${GREEN}All prerequisites met!${NC}"
echo ""

# Security disclaimer
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                    SECURITY NOTICE                            ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This setup uses pre-configured API keys for service communication."
echo ""
echo -e "${GREEN}✓ Safe for local-only deployments${NC}"
echo -e "${GREEN}✓ All services run on your local network only${NC}"
echo -e "${GREEN}✓ You will still set your own account passwords${NC}"
echo ""
echo -e "${YELLOW}⚠ Do NOT expose these services to the internet${NC}"
echo ""
read -p "Press Enter to continue..."
echo ""

# Check if .env already exists
if [ -f .env ]; then
    print_warning ".env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Keeping existing .env file"
        echo "Skipping configuration..."
    else
        rm .env
    fi
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_info "Creating configuration file..."
    echo ""

    # Get media path
    echo -e "${YELLOW}Step 1: Media Storage Path${NC}"
    echo "Enter the full path where your media will be stored."
    echo "This should be a folder on your external drive or local storage."
    echo ""
    echo "Examples:"
    echo "  Linux:   /media/username/drive-name/media"
    echo "  macOS:   /Volumes/MediaDrive/media"
    echo "  Windows: /c/Users/YourName/Media"
    echo ""

    while true; do
        read -p "Media path: " MEDIA_PATH

        # Expand tilde if present
        MEDIA_PATH="${MEDIA_PATH/#\~/$HOME}"

        if [ -z "$MEDIA_PATH" ]; then
            print_error "Path cannot be empty!"
            continue
        fi

        # Check if path exists
        if [ ! -d "$MEDIA_PATH" ]; then
            print_warning "Path does not exist: $MEDIA_PATH"
            read -p "Do you want to create it? (Y/n): " -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                mkdir -p "$MEDIA_PATH"
                if [ -d "$MEDIA_PATH" ]; then
                    print_success "Created directory: $MEDIA_PATH"
                    break
                else
                    print_error "Failed to create directory"
                    continue
                fi
            else
                continue
            fi
        else
            print_success "Path exists: $MEDIA_PATH"
            break
        fi
    done

    # Create media subdirectories
    print_info "Creating media subdirectories..."
    mkdir -p "$MEDIA_PATH/movies"
    mkdir -p "$MEDIA_PATH/tvshows"
    mkdir -p "$MEDIA_PATH/downloads"
    mkdir -p "$MEDIA_PATH/downloads/movies"
    mkdir -p "$MEDIA_PATH/downloads/tvshows"
    print_success "Media directories created"

    echo ""
    echo -e "${YELLOW}Step 2: Timezone${NC}"
    echo "Enter your timezone (e.g., America/New_York, Europe/London, Asia/Tokyo)"
    echo "See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    echo ""
    read -p "Timezone [UTC]: " TZ
    TZ=${TZ:-UTC}
    print_success "Timezone set to: $TZ"

    echo ""
    echo -e "${YELLOW}Step 3: User/Group ID (Linux/macOS only)${NC}"

    # Get current user's UID and GID
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        CURRENT_UID=$(id -u)
        CURRENT_GID=$(id -g)
        echo "Detected UID: $CURRENT_UID, GID: $CURRENT_GID"
        read -p "Use these values? (Y/n): " -r
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter UID [1000]: " PUID
            read -p "Enter GID [1000]: " PGID
            PUID=${PUID:-1000}
            PGID=${PGID:-1000}
        else
            PUID=$CURRENT_UID
            PGID=$CURRENT_GID
        fi
    else
        PUID=1000
        PGID=1000
        echo "Windows detected, using default values"
    fi
    print_success "PUID set to: $PUID, PGID set to: $PGID"

    # Write .env file
    print_info "Writing configuration to .env file..."
    cat > .env <<EOF
# Media Automation Stack Configuration
# Generated by auto-setup script on $(date)

# Media Storage Path
MEDIA_PATH=$MEDIA_PATH

# System Configuration
PUID=$PUID
PGID=$PGID
TZ=$TZ

# Service Ports (default)
JELLYFIN_PORT=8096
QBITTORRENT_PORT=8888
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
JELLYSEERR_PORT=5055
FLARESOLVERR_PORT=8191
EOF

    print_success ".env file created successfully!"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Configuration complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Ask if user wants to start services
read -p "Do you want to start all services now? (Y/n): " -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_info "Starting services with Docker Compose..."
    echo ""

    # Copy template configs if they don't exist
    print_info "Copying template configurations..."
    mkdir -p config/prowlarr config/sonarr config/radarr config/qbittorrent/qBittorrent

    if [ ! -f "config/prowlarr/config.xml" ] && [ -f "templates/prowlarr/config.xml" ]; then
        cp templates/prowlarr/config.xml config/prowlarr/config.xml
        print_success "Prowlarr config copied"
    fi

    if [ ! -f "config/sonarr/config.xml" ] && [ -f "templates/sonarr/config.xml" ]; then
        cp templates/sonarr/config.xml config/sonarr/config.xml
        print_success "Sonarr config copied"
    fi

    if [ ! -f "config/radarr/config.xml" ] && [ -f "templates/radarr/config.xml" ]; then
        cp templates/radarr/config.xml config/radarr/config.xml
        print_success "Radarr config copied"
    fi

    if [ ! -f "config/qbittorrent/qBittorrent/qBittorrent.conf" ] && [ -f "templates/qbittorrent/qBittorrent/qBittorrent.conf" ]; then
        cp templates/qbittorrent/qBittorrent/qBittorrent.conf config/qbittorrent/qBittorrent/qBittorrent.conf
        print_success "qBittorrent config copied (no authentication required for local access)"
    fi

    docker compose up -d

    echo ""
    print_success "All services are starting!"
    echo ""
    print_info "Waiting for services to initialize..."

    # Show a progress indicator
    for i in {1..30}; do
        echo -n "."
        sleep 1
    done
    echo ""

    print_info "Running automatic configuration using Docker..."
    echo ""

    # Use Docker to run the initialization script (works on all platforms!)
    if [ -f "templates/init-databases.sh" ]; then
        print_info "Using Docker-based initialization (no additional software required!)"

        # Run the bash script inside a lightweight Alpine container with sqlite3
        docker run --rm \
            -v "$(pwd)/config:/config" \
            -v "$(pwd)/templates:/templates" \
            -w / \
            alpine:latest \
            sh -c "apk add --no-cache bash sqlite && bash /templates/init-databases.sh"

        echo ""
        print_info "Restarting services to apply configuration..."
        docker compose restart

        echo ""
        print_success "Automatic configuration complete!"
    else
        print_error "Initialization script not found"
        echo ""
        echo "Please ensure templates/init-databases.sh exists"
        echo "You may need to configure services manually using docs/CONFIGURATION.md"
        echo ""
    fi

    # Auto-start on boot configuration (platform-specific)
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Auto-Start on Boot${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux: Use systemd
        echo "Would you like the media stack to start automatically when your computer boots?"
        echo ""
        echo -e "${BLUE}Benefits:${NC}"
        echo "  • Services start automatically on reboot"
        echo "  • No need to manually start Docker containers"
        echo "  • Great for dedicated media servers"
        echo ""
        echo -e "${YELLOW}Note:${NC} This requires sudo/administrator access"
        echo ""
        read -p "Enable auto-start on boot? (y/N): " -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Setting up systemd service..."

            CURRENT_DIR=$(pwd)
            CURRENT_USER=$(whoami)

            cat > media-stack.service.tmp <<EOF
[Unit]
Description=Media Automation Stack
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$CURRENT_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0
User=$CURRENT_USER
Group=$CURRENT_USER

[Install]
WantedBy=multi-user.target
EOF

            if sudo cp media-stack.service.tmp /etc/systemd/system/media-stack.service 2>/dev/null; then
                rm media-stack.service.tmp
                sudo systemctl enable docker 2>/dev/null || true
                sudo systemctl daemon-reload

                if sudo systemctl enable media-stack.service; then
                    print_success "Auto-start enabled successfully!"
                    echo ""
                    echo -e "${GREEN}The media stack will now start automatically on boot.${NC}"
                    echo ""
                    echo "Useful commands:"
                    echo "  • Check status:  sudo systemctl status media-stack"
                    echo "  • Disable:       sudo systemctl disable media-stack"
                    echo "  • View logs:     sudo journalctl -u media-stack"
                else
                    print_error "Failed to enable service"
                fi
            else
                print_error "Failed to install service"
                rm -f media-stack.service.tmp
            fi
        else
            print_info "Skipping auto-start setup"
        fi

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Docker Desktop handles auto-start
        echo -e "${BLUE}On macOS:${NC}"
        echo ""
        echo "Docker Desktop has a built-in auto-start feature:"
        echo ""
        echo "1. Open Docker Desktop"
        echo "2. Click the gear icon (Settings)"
        echo "3. Go to 'General'"
        echo "4. Enable 'Start Docker Desktop when you log in'"
        echo ""
        echo "Once Docker Desktop auto-starts, your containers will"
        echo "automatically start if they have 'restart: unless-stopped'"
        echo "in docker-compose.yml (which they do!)."
        echo ""
        print_info "No additional configuration needed on macOS"

    else
        # Windows: Docker Desktop handles auto-start
        echo -e "${BLUE}On Windows:${NC}"
        echo ""
        echo "Docker Desktop has a built-in auto-start feature:"
        echo ""
        echo "1. Open Docker Desktop"
        echo "2. Click the gear icon (Settings)"
        echo "3. Go to 'General'"
        echo "4. Enable 'Start Docker Desktop when you log in'"
        echo ""
        echo "Once Docker Desktop auto-starts, your containers will"
        echo "automatically start if they have 'restart: unless-stopped'"
        echo "in docker-compose.yml (which they do!)."
        echo ""
        print_info "No additional configuration needed on Windows"
    fi

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🎉  Setup Complete with Auto-Config! 🎉          ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Access your services at:"
    echo ""
    echo -e "  ${BLUE}Jellyseerr:${NC}    http://localhost:5055  ${YELLOW}← Start here!${NC}"
    echo -e "  ${BLUE}Jellyfin:${NC}      http://localhost:8096"
    echo -e "  ${BLUE}Sonarr:${NC}        http://localhost:8989"
    echo -e "  ${BLUE}Radarr:${NC}        http://localhost:7878"
    echo -e "  ${BLUE}Prowlarr:${NC}      http://localhost:9696"
    echo -e "  ${BLUE}qBittorrent:${NC}   http://localhost:8888"
    echo ""
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║          What's Pre-Configured for You:                      ║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} 6 public torrent indexers in Prowlarr"
    echo -e "  ${GREEN}✓${NC} Prowlarr connected to Sonarr and Radarr"
    echo -e "  ${GREEN}✓${NC} Sonarr and Radarr connected to qBittorrent"
    echo -e "  ${GREEN}✓${NC} Root folders configured (/tv and /movies)"
    echo -e "  ${GREEN}✓${NC} Download categories set up"
    echo ""
    echo -e "${YELLOW}Simplified Next Steps:${NC}"
    echo "  1. Open Jellyseerr at http://localhost:5055"
    echo "  2. Sign in with Jellyfin (follow the setup wizard)"
    echo "  3. Connect Jellyseerr to Sonarr and Radarr"
    echo "  4. Start requesting movies and TV shows!"
    echo ""
    echo -e "${BLUE}Default Credentials:${NC}"
    echo "  qBittorrent: admin / adminadmin ${YELLOW}(change this!)${NC}"
    echo "  Other services: Set your own password on first login"
    echo ""
    echo -e "${GREEN}Happy streaming! 🍿${NC}"
    echo ""
else
    print_info "Services not started"
    echo "You can start them later with: docker compose up -d"
    echo "Then run: bash templates/init-databases.sh"
    echo ""
fi
