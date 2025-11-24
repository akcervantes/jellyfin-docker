# Media Automation Stack

> 🎬 A complete, self-hosted media automation solution with Jellyfin, Sonarr, Radarr, and more

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)

## What is this?

This is a complete Docker-based media automation stack that allows you to:

- **Request** movies and TV shows through a beautiful Netflix-like interface (Jellyseerr)
- **Automatically download** content via torrents (qBittorrent + Sonarr + Radarr)
- **Stream** your media from anywhere on your local network (Jellyfin)
- **Manage** everything with minimal effort

Perfect for backing up your physical media collection and accessing it digitally! 

### Dev's note

I wanted to make this so I could more easily manage my media collection now that streaming has become so fragmented and cumbersome. 
This setup allows you to access your own content in your home network with the ease of access and commodity of streaming using jellyfin, jellyseerr, sonarr, radarr and prowlarr (some incredible opensource tools! Do check them out and donate/contribute!!). 

Please note that I was not involved in the development of any of these tools, this is only a script to easily configure everything you need to get your home streaming platform running with docker, I would like to share this with my less tech savvy friends and thought this might be the easiest way to help them set up their own services (or rather, help me set it up for them more easily lol). 
So if you're the more tech savvy person in your circle, maybe this can make setting up a home streaming service for your friends and family less of a hassle.

As a disclaimer, I am in no way advocating for piracy and this setup is only meant to help users back up their own physically/digitally owned content legally.

## Features

✨ **One-Command Setup** - Run `./setup.sh` and you're done
🔒 **Secure** - Everything runs on your local network only
🌍 **Cross-Platform** - Works on Windows, macOS, and Linux
📦 **Complete Solution** - All services integrated and ready to go
🎯 **User-Friendly** - Beautiful web interfaces for everything
🔄 **Automatic** - New episodes download automatically
📱 **Mobile Ready** - Access from your phone on the same network

## What's Included

| Service | Purpose | Port |
|---------|---------|------|
| **Jellyseerr** | Request movies/shows (Netflix-like UI) | 5055 |
| **Jellyfin** | Stream your media | 8096* |
| **Sonarr** | TV show automation | 8989 |
| **Radarr** | Movie automation | 7878 |
| **Prowlarr** | Torrent indexer manager | 9696 |
| **qBittorrent** | Torrent download client | 8888* |
| **FlareSolverr** | Cloudflare bypass helper | 8191 |

*Default ports. Can be customized in `.env` file if there are conflicts.

## Quick Start

### Prerequisites

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **At least 4GB RAM** for all services
- **External drive or folder** for media storage (recommended 100GB+)

### Installation (3 Steps)

1. **Clone this repository**
   ```bash
   git clone <your-repo-url>
   cd media-automation-stack
   ```

2. **Run the setup script**
   ```bash
   ./setup.sh
   ```

   On Windows (PowerShell):
   ```powershell
   bash setup.sh
   ```

3. **Follow the prompts**
   - Enter your media storage path
   - Select your timezone
   - Services will start automatically

That's it! 🎉

### First Time Access

Once setup is complete, open your browser and visit:

**http://localhost:5055** (Jellyseerr - Start here!)

Then configure the services by following the [Configuration Guide](docs/CONFIGURATION.md).

## Usage

### For Daily Use

1. **Open Jellyseerr** (http://localhost:5055)
2. **Search** for a movie or TV show
3. **Click "Request"**
4. Wait for it to download automatically
5. **Watch in Jellyfin** (http://localhost:8096)

That's it! Everything else happens automatically.

### Managing Services

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Update all services
docker compose pull
docker compose up -d

# Restart a specific service
docker compose restart sonarr
```

## Documentation

- 📖 [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- ⚙️ [Configuration Guide](docs/CONFIGURATION.md) - Step-by-step service configuration
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- 📱 [Mobile Apps](docs/MOBILE-APPS.md) - Recommended mobile applications

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          You                                │
│                           ↓                                 │
│                     Jellyseerr                              │
│                  (Request Interface)                        │
│                           ↓                                 │
│                ┌──────────┴──────────┐                      │
│                ↓                     ↓                      │
│             Sonarr               Radarr                     │
│           (TV Shows)            (Movies)                    │
│                ↓                     ↓                      │
│                └──────────┬──────────┘                      │
│                           ↓                                 │
│                       Prowlarr                              │
│                  (Torrent Indexers)                         │
│                           ↓                                 │
│                     qBittorrent                             │
│                   (Downloads Files)                         │
│                           ↓                                 │
│                   Your Media Folder                         │
│                           ↓                                 │
│                       Jellyfin                              │
│                    (Streams Media)                          │
│                           ↓                                 │
│                          You                                │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

After setup, your media folder will look like this:

```
/path/to/media/
├── movies/              # Movies go here (Radarr manages)
├── tvshows/            # TV shows go here (Sonarr manages)
└── downloads/          # Temporary download location
    ├── movies/
    └── tvshows/
```

## Security & Privacy

🔒 **This stack runs ONLY on your local network by default**

- No external access unless you explicitly configure it
- All services require authentication
- No default passwords (you set them on first access)
- Your data stays on your computer

### Important Security Notes

1. **DO NOT** expose these services directly to the internet
2. **DO** use strong passwords for all services
3. **DO** keep your system and Docker updated
4. **Consider** using a VPN with qBittorrent for additional privacy

See [Security Best Practices](docs/SECURITY.md) for more information.

## Mobile Access

Access your services from your phone or tablet on the same WiFi network:

### Find Your Computer's IP

```bash
hostname -I
```

Look for an IP like `192.168.1.X` or `10.0.0.X`

### Access from Mobile

On your phone's browser:
- **Jellyseerr**: `http://YOUR_IP:5055` ⭐ (Main interface)
- **Jellyfin**: `http://YOUR_IP:8096`

Example: If your IP is `192.168.1.100`, use `http://192.168.1.100:5055`

### Mobile Apps (Recommended)

**For Jellyfin:**
- Android: [Jellyfin from Play Store](https://play.google.com/store/apps/details?id=org.jellyfin.mobile)
- iOS: [Jellyfin from App Store](https://apps.apple.com/app/jellyfin-mobile/id1480192618)

**For Managing Everything:**
- Android: nzb360 (paid, highly recommended)
- iOS/Android: LunaSea (free)

Configure with your local IP address!

## Auto-Start on Boot

Make the stack start automatically when your computer boots:

### 1. Enable Docker on Boot

```bash
sudo systemctl enable docker
```

### 2. Install Systemd Service (Linux)

```bash
# Copy service file
sudo cp media-stack.service /etc/systemd/system/

# Enable service
sudo systemctl daemon-reload
sudo systemctl enable media-stack.service
```

### 3. Auto-Mount External Drive (Optional)

If using an external drive, add to `/etc/fstab`:

```bash
UUID=your-drive-uuid /mnt/media ext4 defaults,nofail 0 2
```

Find your UUID with: `lsblk -f`

**Note**: The `nofail` option ensures your system boots even if the drive isn't connected.

See `.claude/SETUP_NOTES.md` for detailed configuration examples.

## Troubleshooting

### Services won't start?

```bash
# Check Docker is running
docker info

# Check for port conflicts
docker compose ps

# View service logs
docker compose logs -f [service-name]
```

### Can't access services?

- Make sure you're on the same network
- Try `http://127.0.0.1:5055` instead of localhost
- Check your firewall isn't blocking the ports

### Permission issues?

Make sure your PUID and PGID in `.env` match your user:

```bash
id -u  # Returns your UID
id -g  # Returns your GID
```

See the full [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for more solutions.

## Updating

To update all services to the latest versions:

```bash
docker compose pull
docker compose up -d
```

Your configuration and media files are preserved.

## Uninstalling

To remove all services (keeps your media and config):

```bash
docker compose down
```

To remove everything including config:

```bash
docker compose down -v
```

Your media files in `MEDIA_PATH` are never deleted.

## FAQ

**Q: Is this legal?**
A: This stack is designed for managing your own legally obtained media (DVD backups, purchased content, etc.). Ensure you have the right to download and store any content.

**Q: Does this work on Raspberry Pi?**
A: Yes, but performance may vary. Use ARM-compatible Docker images.

**Q: Can I access this remotely?**
A: Not recommended for security. Use Tailscale or a VPN for safe remote access.

**Q: How much bandwidth does this use?**
A: Depends on what you download. Configure speed limits in qBittorrent.

**Q: Can I use this with my existing Jellyfin?**
A: Yes! Just remove the Jellyfin service from docker-compose.yml and point to your existing instance.

**Q: Do I need a VPN?**
A: Optional but recommended. See the VPN setup guide.

## Contributing

Found a bug? Have a feature request? Contributions are welcome!

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Credits

This project uses these amazing open-source applications:

- [Jellyfin](https://jellyfin.org/) - Media server
- [Sonarr](https://sonarr.tv/) - TV show automation
- [Radarr](https://radarr.video/) - Movie automation
- [Prowlarr](https://prowlarr.com/) - Indexer manager
- [qBittorrent](https://www.qbittorrent.org/) - Torrent client
- [Jellyseerr](https://github.com/Fallenbagel/jellyseerr) - Request management
- [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) - Cloudflare bypass

## License

MIT License - See [LICENSE](LICENSE) file for details

## Support

- 📖 [Read the docs](docs/)
- 🐛 [Report a bug](../../issues)
- 💡 [Request a feature](../../issues)
- ❓ [Ask a question](../../discussions)

---

Made with ❤️ for easy media automation

**Remember**: Only download content you have the legal right to own!
