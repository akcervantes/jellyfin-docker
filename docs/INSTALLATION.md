# Installation Guide

This guide will walk you through installing Docker and setting up the Media Automation Stack on Windows, macOS, or Linux.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing Docker](#installing-docker)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [Installing the Media Stack](#installing-the-media-stack)
- [First-Time Configuration](#first-time-configuration)
- [Verifying Installation](#verifying-installation)

## Prerequisites

Before you begin, ensure you have:

- **A computer running:**
  - Windows 10/11 (64-bit, Pro, Enterprise, or Education)
  - macOS 11 (Big Sur) or newer
  - Linux (Ubuntu, Debian, Fedora, etc.)

- **System Requirements:**
  - At least 4GB RAM (8GB recommended)
  - 10GB free disk space for Docker and configs
  - 100GB+ for media storage (external drive recommended)

- **Internet connection** for downloading Docker and images

- **Administrator/sudo access** to install software

## Installing Docker

### Windows

#### Option 1: Docker Desktop (Recommended)

1. **Download Docker Desktop**
   - Visit: https://www.docker.com/products/docker-desktop
   - Click "Download for Windows"

2. **Run the installer**
   - Double-click `Docker Desktop Installer.exe`
   - Follow the installation wizard
   - Enable WSL 2 if prompted (recommended)

3. **Restart your computer** when prompted

4. **Start Docker Desktop**
   - Launch from Start Menu
   - Wait for Docker to start (icon in system tray)

5. **Verify installation**
   ```powershell
   docker --version
   docker compose version
   ```

#### Troubleshooting Windows Installation

**WSL 2 Installation Required:**
If you see an error about WSL 2:
1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Restart your computer
4. Start Docker Desktop again

**Virtualization Not Enabled:**
If you see virtualization errors:
1. Restart your computer
2. Enter BIOS/UEFI settings (usually F2, F12, or Del during boot)
3. Enable "Intel VT-x" or "AMD-V" under CPU settings
4. Save and restart

### macOS

1. **Download Docker Desktop**
   - Visit: https://www.docker.com/products/docker-desktop
   - Choose the correct version:
     - **Apple Silicon** (M1/M2/M3): Download "Mac with Apple chip"
     - **Intel Mac**: Download "Mac with Intel chip"

2. **Install Docker Desktop**
   - Open the downloaded `.dmg` file
   - Drag Docker to Applications folder
   - Launch Docker from Applications

3. **Grant permissions**
   - Click "Open" if you see a security warning
   - Enter your password when prompted

4. **Verify installation**
   ```bash
   docker --version
   docker compose version
   ```

### Linux

#### Ubuntu/Debian

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (avoid using sudo)
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

#### Fedora

```bash
# Install Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

#### Verify Linux Installation

```bash
docker --version
docker compose version

# Test Docker (without sudo)
docker run hello-world
```

If you need to use `sudo` with docker, you didn't add your user to the docker group or haven't logged out/in yet.

## Installing the Media Stack

### Step 1: Download the Project

#### Option A: Using Git (Recommended)

```bash
# Install git if not already installed
# Ubuntu/Debian: sudo apt-get install git
# macOS: xcode-select --install
# Windows: Download from https://git-scm.com/download/win

# Clone the repository
git clone <repository-url>
cd media-automation-stack
```

#### Option B: Download ZIP

1. Go to the GitHub repository
2. Click the green "Code" button
3. Select "Download ZIP"
4. Extract the ZIP file
5. Open terminal/PowerShell in the extracted folder

### Step 2: Run the Setup Script

#### Linux/macOS

```bash
# Make script executable (if not already)
chmod +x setup.sh

# Run setup
./setup.sh
```

#### Windows (PowerShell)

```powershell
# Run via bash (included with Git for Windows)
bash setup.sh
```

#### Windows (Command Prompt)

```cmd
# Install Git Bash first, then use PowerShell method
```

### Step 3: Follow the Setup Wizard

The script will ask you:

1. **Media storage path**
   - Where to store your movies and TV shows
   - Example Linux: `/media/username/external-drive/media`
   - Example macOS: `/Volumes/MediaDrive/media`
   - Example Windows: `/c/Users/YourName/Media`

2. **Timezone**
   - Your local timezone
   - Find yours: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
   - Example: `America/New_York`, `Europe/London`, `Asia/Tokyo`

3. **Start services now?**
   - Say "Yes" to start everything automatically

### Step 4: Wait for Services to Start

The first time you run this, Docker will:
- Download all the container images (~2-3GB total)
- Start all services
- Initialize databases

This can take 5-10 minutes depending on your internet speed.

## First-Time Configuration

Once all services are running, you'll see:

```
Access your services at:
  Jellyseerr:    http://localhost:5055  ← Start here!
  Jellyfin:      http://localhost:8096
  Sonarr:        http://localhost:8989
  Radarr:        http://localhost:7878
  Prowlarr:      http://localhost:9696
  qBittorrent:   http://localhost:8080
```

### Next Steps

1. **Read [CONFIGURATION.md](CONFIGURATION.md)** for detailed setup of each service
2. Configure Prowlarr with torrent indexers
3. Connect Sonarr and Radarr to Prowlarr and qBittorrent
4. Set up Jellyfin media libraries
5. Connect Jellyseerr to everything

## Verifying Installation

### Check All Containers Are Running

```bash
docker compose ps
```

You should see all services with "Up" status:

```
NAME            STATUS
jellyfin        Up
jellyseerr      Up
qbittorrent     Up
prowlarr        Up
radarr          Up
sonarr          Up
flaresolverr    Up
```

### Check Container Logs

If something isn't working:

```bash
# View all logs
docker compose logs

# View specific service logs
docker compose logs jellyfin
docker compose logs sonarr

# Follow logs in real-time
docker compose logs -f
```

### Test Web Access

Open your browser and visit each service:

- http://localhost:5055 (Jellyseerr)
- http://localhost:8096 (Jellyfin)
- http://localhost:8989 (Sonarr)

If you can access all of them, installation was successful!

## Common Installation Issues

### Port Already in Use

**Error**: `Bind for 0.0.0.0:8096 failed: port is already allocated`

**Solution**: Another application is using that port. Either:
1. Stop the conflicting application, or
2. Change the port in `.env` file

Example: Change `JELLYFIN_PORT=8096` to `JELLYFIN_PORT=8097`

Then restart: `docker compose down && docker compose up -d`

### Permission Denied (Linux)

**Error**: `permission denied while trying to connect to the Docker daemon`

**Solution**: Add your user to the docker group:

```bash
sudo usermod -aG docker $USER
```

Then **log out and back in** (important!)

### Docker Not Running

**Error**: `Cannot connect to the Docker daemon`

**Solution**:
- **Windows/Mac**: Start Docker Desktop from the Start Menu/Applications
- **Linux**: `sudo systemctl start docker`

### Can't Access Web Interface

**Issue**: Browser says "This site can't be reached"

**Solutions**:
1. Try `http://127.0.0.1:5055` instead of `localhost`
2. Check service is running: `docker compose ps`
3. Check firewall isn't blocking the port
4. Wait a minute - service might still be starting

### Out of Disk Space

**Error**: `no space left on device`

**Solution**:
1. Free up disk space
2. Run: `docker system prune` to clean up old images
3. Consider using an external drive for media

## Getting Help

If you're still having issues:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Search existing [GitHub Issues](../../issues)
3. Create a new issue with:
   - Your operating system
   - Docker version (`docker --version`)
   - Error messages
   - Output of `docker compose logs`

---

**Next**: [Configuration Guide](CONFIGURATION.md) →
