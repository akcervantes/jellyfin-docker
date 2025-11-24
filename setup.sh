#!/bin/bash

# Media Automation Stack - Interactive Setup Script
# This script will guide you through the initial setup

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║        Media Automation Stack - Setup Wizard                 ║"
echo "║                                                               ║"
echo "║  This will set up:                                           ║"
echo "║    • Jellyfin (Media Server)                                 ║"
echo "║    • Sonarr (TV Shows) & Radarr (Movies)                     ║"
echo "║    • Prowlarr (Torrent Indexers)                             ║"
echo "║    • qBittorrent (Download Client)                           ║"
echo "║    • Jellyseerr (Request Management)                         ║"
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
# Generated by setup script on $(date)

# Media Storage Path
MEDIA_PATH=$MEDIA_PATH

# System Configuration
PUID=$PUID
PGID=$PGID
TZ=$TZ

# Service Ports (default)
JELLYFIN_PORT=8096
QBITTORRENT_PORT=8080
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

    docker compose up -d

    echo ""
    print_success "All services are starting!"
    echo ""
    print_info "Waiting for services to be healthy (this may take a minute)..."
    sleep 10

    # Ask about auto-start on boot (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo ""
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Optional: Auto-Start on Boot${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
        echo ""
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
            print_info "Setting up auto-start service..."

            # Get current directory
            CURRENT_DIR=$(pwd)
            CURRENT_USER=$(whoami)

            # Create service file with current paths
            print_info "Creating systemd service file..."
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

            # Install the service
            echo ""
            print_info "Installing service (requires sudo password)..."

            if sudo cp media-stack.service.tmp /etc/systemd/system/media-stack.service 2>/dev/null; then
                rm media-stack.service.tmp

                # Enable Docker to start on boot
                print_info "Enabling Docker to start on boot..."
                sudo systemctl enable docker 2>/dev/null || true

                # Reload systemd and enable service
                print_info "Enabling media stack service..."
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
                    rm -f media-stack.service.tmp
                fi
            else
                print_error "Failed to install service (permission denied or sudo not available)"
                rm -f media-stack.service.tmp
                echo ""
                echo "You can manually install the service later by running:"
                echo "  sudo cp media-stack.service /etc/systemd/system/"
                echo "  sudo systemctl daemon-reload"
                echo "  sudo systemctl enable docker"
                echo "  sudo systemctl enable media-stack"
            fi
        else
            print_info "Skipping auto-start setup"
            echo "You can enable it later by following the instructions in docs/INSTALLATION.md"
        fi
    fi

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Setup Complete! 🎉                        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Access your services at:"
    echo ""
    echo -e "  ${BLUE}Jellyseerr:${NC}    http://localhost:5055  ${YELLOW}← Start here!${NC}"
    echo -e "  ${BLUE}Jellyfin:${NC}      http://localhost:8096"
    echo -e "  ${BLUE}Sonarr:${NC}        http://localhost:8989"
    echo -e "  ${BLUE}Radarr:${NC}        http://localhost:7878"
    echo -e "  ${BLUE}Prowlarr:${NC}      http://localhost:9696"
    echo -e "  ${BLUE}qBittorrent:${NC}   http://localhost:8080"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Read docs/CONFIGURATION.md for detailed setup instructions"
    echo "  2. Configure Prowlarr with torrent indexers"
    echo "  3. Connect Sonarr/Radarr to Prowlarr and qBittorrent"
    echo "  4. Set up Jellyfin libraries"
    echo "  5. Connect Jellyseerr to Jellyfin and start requesting!"
    echo ""
    echo -e "${GREEN}Happy streaming! 🍿${NC}"
    echo ""
else
    print_info "Services not started"
    echo "You can start them later with: docker compose up -d"
    echo ""
fi
