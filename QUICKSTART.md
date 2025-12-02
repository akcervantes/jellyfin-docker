# Quick Start Guide - 5 Minute Setup

Get your media automation stack running in just 5 minutes with automatic configuration!

## Prerequisites

- **Docker Desktop** installed and running
- **Python 3** (usually pre-installed on macOS/Linux, included with Docker Desktop on Windows)
- **10GB free space** for Docker images
- **Media storage location** (external drive or folder)

> **Note**: Python is used for cross-platform database initialization. If Python isn't available, services will start but require manual configuration.

## Step 1: Get the Code (1 minute)

```bash
git clone <your-repo-url>
cd media-automation-stack
```

## Step 2: Run Auto-Setup (2 minutes)

**Linux/macOS:**
```bash
./setup-auto.sh
```

**Windows (easiest - just double-click):**
```
setup-auto.bat
```

**Or in Command Prompt:**
```cmd
setup-auto.bat
```

**Or in PowerShell:**
```powershell
.\setup-auto.ps1
```

**You'll be asked:**
1. Where to store your media (e.g., `/path/to/media`)
2. Your timezone (e.g., `America/New_York`)
3. Whether to start services now (say **Yes**)

The script will automatically:
- Create all necessary folders
- Start all Docker containers
- Configure 6 torrent indexers
- Connect all services together
- Set up download categories

## Step 3: Connect Jellyseerr (2 minutes)

Once services are running, open your browser:

### A. Setup Jellyfin

1. Go to **http://localhost:8096**
2. Create your admin account
3. Add media libraries:
   - **Movies**: `/data/movies`
   - **TV Shows**: `/data/tvshows`

### B. Setup Jellyseerr

1. Go to **http://localhost:5055**
2. Click **"Use your Jellyfin account"**
3. Enter Jellyfin server: `http://jellyfin:8096`
4. Sign in with your Jellyfin credentials

5. **Connect Sonarr:**
   - Hostname: `sonarr`
   - Port: `8989`
   - API Key: `f7425b1d04114fa887a6867d867f8bf5`
   - Quality Profile: `HD-1080p`
   - Root Folder: `/tv`

6. **Connect Radarr:**
   - Hostname: `radarr`
   - Port: `7878`
   - API Key: `2707496c99a5496fa7e66d2b100963b1`
   - Quality Profile: `HD-1080p`
   - Root Folder: `/movies`

7. Click **Finish Setup**

## Step 4: Start Requesting! (30 seconds)

1. Search for any movie or TV show
2. Click the **Request** button
3. Wait for it to download
4. Watch in Jellyfin!

---

## Default Credentials

**qBittorrent:**
- URL: http://localhost:8888
- Username: `admin`
- Password: `adminadmin` ⚠️ **Change this immediately!**

**All other services:**
- Create your own secure password on first login

---

## What Was Pre-Configured For You

The auto-setup has already configured:

✅ **6 Public Indexers in Prowlarr:**
- 1337x
- The Pirate Bay
- YTS (movies)
- EZTV (TV shows)
- TorrentGalaxy
- Torlock

✅ **Service Connections:**
- Prowlarr ↔ Sonarr
- Prowlarr ↔ Radarr
- Sonarr ↔ qBittorrent
- Radarr ↔ qBittorrent

✅ **Root Folders:**
- `/tv` for TV shows
- `/movies` for movies

✅ **Download Categories:**
- `tv-sonarr` for TV shows
- `movies-radarr` for movies

---

## Troubleshooting

### Services won't start?

```bash
# Check Docker is running
docker info

# View service logs
docker compose logs -f
```

### Can't access web interfaces?

- Try `http://127.0.0.1:5055` instead of `localhost`
- Wait a minute - services may still be starting
- Check your firewall

### Need to restart everything?

```bash
docker compose restart
```

### Want to start fresh?

```bash
# Stop and remove everything
docker compose down -v

# Delete config folder
rm -rf config/

# Run setup again
./setup-auto.sh
```

---

## Next Steps

### Add More Indexers

1. Open Prowlarr: http://localhost:9696
2. Go to **Indexers** → **Add Indexer**
3. Search for your preferred indexers
4. Click **Sync App Indexers** to push to Sonarr/Radarr

### Customize Quality Settings

1. Open Sonarr: http://localhost:8989
2. Go to **Settings** → **Profiles**
3. Edit **HD-1080p** profile to your preferences
4. Repeat in Radarr: http://localhost:7878

### Enable Auto-Start on Boot

**Windows & macOS:**
1. Open Docker Desktop
2. Settings → General
3. Enable "Start Docker Desktop when you log in"
4. Done! Containers auto-start with Docker Desktop

**Linux:**
The setup script offers systemd service installation during setup, or manually:
```bash
sudo cp media-stack.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl enable media-stack
```

### Access from Mobile

1. Find your computer's IP: `hostname -I`
2. On your phone, visit: `http://YOUR_IP:5055`
3. Install Jellyfin mobile app for best experience

---

## Service URLs Quick Reference

| Service | URL | Purpose |
|---------|-----|---------|
| **Jellyseerr** | http://localhost:5055 | Request content (start here!) |
| **Jellyfin** | http://localhost:8096 | Watch your media |
| **Sonarr** | http://localhost:8989 | Manage TV shows |
| **Radarr** | http://localhost:7878 | Manage movies |
| **Prowlarr** | http://localhost:9696 | Manage indexers |
| **qBittorrent** | http://localhost:8888 | View downloads |

---

## Common Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart all services
docker compose restart

# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f sonarr

# Update all services
docker compose pull
docker compose up -d

# Check service status
docker compose ps
```

---

## Security Reminders

🔒 **This stack is for LOCAL use only**

- Services run on your local network
- API keys are pre-configured for convenience
- You still set your own login passwords
- DO NOT expose to the internet without proper security
- Change default qBittorrent password immediately

---

## Need More Help?

- 📖 [Full Configuration Guide](docs/CONFIGURATION.md)
- 🔧 [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- 🛡️ [Security Best Practices](docs/SECURITY.md)
- 📱 [Mobile Apps Guide](docs/MOBILE-APPS.md)

---

**Enjoy your automated media server!** 🍿🎬
