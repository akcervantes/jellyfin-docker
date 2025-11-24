# Troubleshooting Guide

Common issues and solutions for the Media Automation Stack.

## Table of Contents

- [Docker Issues](#docker-issues)
- [Service Access Issues](#service-access-issues)
- [Download Issues](#download-issues)
- [Jellyfin Issues](#jellyfin-issues)
- [Connection Issues](#connection-issues)
- [Performance Issues](#performance-issues)
- [General Tips](#general-tips)

---

## Docker Issues

### Docker Won't Start

**Symptoms:**
- Can't start Docker Desktop
- `docker info` returns error

**Solutions:**

**Windows:**
1. Check WSL 2 is installed: `wsl --status`
2. Update WSL: `wsl --update`
3. Restart computer
4. Enable virtualization in BIOS

**macOS:**
1. Check System Preferences → Security for blocked apps
2. Restart Docker Desktop
3. Reinstall Docker Desktop

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Port Already in Use

**Error:** `Bind for 0.0.0.0:8096 failed: port is already allocated`

**Solution 1: Change Port**
1. Edit `.env` file
2. Change the conflicting port:
   ```bash
   JELLYFIN_PORT=8097  # Was 8096
   ```
3. Restart: `docker compose down && docker compose up -d`

**Solution 2: Find What's Using the Port**

**Linux/macOS:**
```bash
sudo lsof -i :8096
# Kill the process if safe to do so
```

**Windows:**
```powershell
netstat -ano | findstr :8096
# Note the PID, then:
taskkill /PID <number> /F
```

### Container Keeps Restarting

**Check logs:**
```bash
docker compose logs <service-name>
```

**Common causes:**

1. **Permission issues** - Check PUID/PGID in `.env`
2. **Path doesn't exist** - Verify MEDIA_PATH exists
3. **Out of memory** - Check: `docker stats`
4. **Corrupted config** - Delete config folder and reconfigure

### Cannot Connect to Docker Daemon

**Error:** `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

**Solution:**

**Linux:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then:
docker ps  # Should work without sudo
```

**Windows/Mac:**
- Start Docker Desktop application
- Wait for it to fully start (whale icon in system tray)

---

## Service Access Issues

### qBittorrent Shows "Unauthorized" Page

**Symptoms:**
- Browser shows blank page with just "Unauthorized" text
- No login form appears

**Solutions:**

1. **Clear browser cache and try incognito/private mode:**
   - Press Ctrl+Shift+Delete (Cmd+Shift+Delete on Mac)
   - Clear cached images and files
   - Or open incognito/private window

2. **Try different URL formats:**
   - `http://127.0.0.1:8888`
   - `http://localhost:8888`

3. **Check qBittorrent logs for temporary password:**
   ```bash
   docker compose logs qbittorrent | grep "password"
   ```
   Look for: `The WebUI administrator password was not set. A temporary password is provided for this session: XXXXX`

4. **Restart qBittorrent to get new password:**
   ```bash
   docker compose restart qbittorrent
   docker compose logs qbittorrent --tail=20 | grep password
   ```

5. **If still not working, check the config:**
   - File: `config/qbittorrent/qBittorrent/qBittorrent.conf`
   - Should have `WebUI\AuthSubnetWhitelistEnabled=true` for localhost bypass

**Note**: LinuxServer's qBittorrent image has specific port requirements. The `WEBUI_PORT` environment variable must match both sides of the port mapping in docker-compose.yml.

### Can't Access Web Interface

**Symptoms:**
- Browser shows "This site can't be reached"
- Connection refused errors

**Solutions:**

1. **Check service is running:**
   ```bash
   docker compose ps
   ```
   All should show "Up" status

2. **Try different URL:**
   - Instead of `localhost`, try `127.0.0.1`
   - Example: `http://127.0.0.1:5055`

3. **Check firewall:**
   - Windows: Allow Docker in Windows Firewall
   - Linux: Check `ufw` or `firewalld`
   - macOS: System Preferences → Security

4. **Wait longer:**
   - Services take 30-60 seconds to fully start
   - Check logs: `docker compose logs -f <service>`

5. **Restart services:**
   ```bash
   docker compose restart <service-name>
   ```

### "Connection Refused" Between Services

**Symptoms:**
- Prowlarr can't connect to Sonarr
- Sonarr can't connect to qBittorrent

**Common Mistakes:**

❌ **Wrong:** `http://localhost:8989`
✅ **Correct:** `http://sonarr:8989`

❌ **Wrong:** `http://127.0.0.1:8080`
✅ **Correct:** `http://qbittorrent:8080`

**Always use service names, not localhost, when services communicate!**

### Forgot Password

**qBittorrent:**
1. Stop containers: `docker compose down`
2. Delete: `./config/qbittorrent/qBittorrent/config/qBittorrent.conf`
3. Start: `docker compose up -d`
4. Default password is `adminadmin` again

**Sonarr/Radarr/Jellyfin:**
1. Stop the service
2. Edit config file in `./config/<service>/`
3. Look for authentication settings
4. Or delete config and reconfigure

---

## Download Issues

### Torrents Not Starting

**Checklist:**

1. **Check qBittorrent credentials in Sonarr/Radarr:**
   - Settings → Download Clients → qBittorrent
   - Test connection (should show green checkmark)

2. **Check category exists:**
   - qBittorrent should have `tv-sonarr` and `movies-radarr` categories
   - Right-click in qBittorrent categories → Add category

3. **Check indexers are working:**
   - Prowlarr → Indexers → Test each one
   - Disable broken indexers

4. **Check Prowlarr is synced:**
   - Prowlarr → Settings → Apps
   - Click "Sync App Indexers"

### Downloads Stuck at 0%

**Possible causes:**

1. **No seeders:**
   - Check if torrent has seeders (Sonarr/Radarr → Activity)
   - Try manual search and pick different release

2. **Port forwarding:**
   - qBittorrent needs incoming connections
   - Enable UPnP in qBittorrent settings
   - Or manually forward port 6881

3. **Disk space:**
   - Check available space: `df -h` (Linux/macOS)
   - Clean up if needed

### Sonarr/Radarr Says "No Results"

**Solutions:**

1. **Check Prowlarr indexers:**
   - Go to Prowlarr → Indexers
   - Test each indexer
   - Add more indexers

2. **Check quality profile:**
   - Sonarr/Radarr → Settings → Profiles
   - Make sure desired qualities are allowed

3. **Try manual search:**
   - Go to the movie/show in Radarr/Sonarr
   - Click "Search" tab
   - Pick a release manually

4. **Check minimum availability:**
   - Radarr → Settings → Indexers → Minimum Availability
   - Change to "Announced" for earlier grabbing

---

## Jellyfin Issues

### Media Not Appearing in Library

**Solutions:**

1. **Manual scan:**
   - Dashboard → Libraries → Scan All Libraries

2. **Check file location:**
   ```bash
   # Files should be in:
   # Movies: ${MEDIA_PATH}/movies/
   # TV: ${MEDIA_PATH}/tvshows/
   ```

3. **Check permissions:**
   ```bash
   # Linux/macOS - make sure Jellyfin can read files
   chmod -R 755 ${MEDIA_PATH}
   ```

4. **Check file naming:**
   - Movies: `Movie Name (Year).mkv`
   - TV: `Show Name - S01E01.mkv`
   - See [Jellyfin Naming Guide](https://jellyfin.org/docs/general/server/media/movies.html)

### Playback Issues

**Buffering/stuttering:**

1. **Transcode settings:**
   - Dashboard → Playback
   - Adjust hardware acceleration
   - Lower transcoding quality

2. **Network speed:**
   - Use wired connection if possible
   - Check network speed

3. **Client device:**
   - Update Jellyfin app
   - Try different client

**"This client isn't compatible":**
- Try different browser
- Install codec packs (Windows)
- Enable hardware acceleration

### Can't Connect to Jellyfin

1. **Check container is running:** `docker compose ps jellyfin`
2. **Check logs:** `docker compose logs jellyfin`
3. **Try:** `http://127.0.0.1:8096`
4. **Restart:** `docker compose restart jellyfin`

---

## Connection Issues

### Prowlarr Not Syncing to Sonarr/Radarr

**Error:** "Unable to connect to Sonarr/Radarr"

**Checklist:**

1. **Use service names:**
   - ✅ `http://sonarr:8989`
   - ❌ `http://localhost:8989`

2. **Check API keys:**
   - Copy from Sonarr/Radarr → Settings → General
   - Paste exactly in Prowlarr

3. **Check services are running:**
   ```bash
   docker compose ps sonarr radarr prowlarr
   ```

4. **Check Docker network:**
   ```bash
   docker network ls
   docker network inspect tvmanager_media-network
   ```

### Jellyseerr Can't Connect to Jellyfin

**Solutions:**

1. **Use service name:** `http://jellyfin:8096`
2. **Check Jellyfin is fully started:**
   - Open http://localhost:8096 in browser
   - Should show Jellyfin login page
3. **Verify API key:**
   - Jellyfin → Dashboard → API Keys
   - Create new key if needed

---

## Performance Issues

### High CPU Usage

**Check what's using CPU:**
```bash
docker stats
```

**Common causes:**

1. **Jellyfin transcoding:**
   - Enable hardware acceleration
   - Dashboard → Playback

2. **Library scanning:**
   - Wait for scan to finish
   - Reduce scan frequency

3. **Multiple downloads:**
   - Limit simultaneous downloads in qBittorrent
   - Settings → Downloads → Maximum active downloads

### High RAM Usage

**Solutions:**

1. **Limit container memory:**
   Add to docker-compose.yml:
   ```yaml
   services:
     jellyfin:
       mem_limit: 2g
   ```

2. **Restart containers periodically:**
   ```bash
   docker compose restart
   ```

3. **Upgrade system RAM** if possible

### Slow Downloads

1. **Check qBittorrent limits:**
   - Tools → Options → Speed
   - Remove limits or increase

2. **Check seeders:**
   - Pick torrents with more seeders

3. **Port forwarding:**
   - Forward port 6881 in router
   - Or enable UPnP

---

## General Tips

### View Logs

**All services:**
```bash
docker compose logs -f
```

**Specific service:**
```bash
docker compose logs -f sonarr
```

**Last 100 lines:**
```bash
docker compose logs --tail=100 radarr
```

### Restart Everything

```bash
docker compose restart
```

### Nuclear Option (Full Reset)

**Keeps media, deletes all configs:**
```bash
docker compose down -v
rm -rf config/*
./setup.sh
```

Then reconfigure everything following [CONFIGURATION.md](CONFIGURATION.md)

### Check Service Health

```bash
# List all containers
docker compose ps

# Check specific service logs
docker compose logs <service-name>

# Check resource usage
docker stats
```

### Update Everything

```bash
docker compose pull
docker compose up -d
```

### Backup Your Config

**Important files to backup:**
```bash
# Copy these regularly
cp .env .env.backup
tar -czf config-backup.tar.gz config/
```

---

## Getting More Help

### Enable Debug Logging

**Sonarr/Radarr/Prowlarr:**
1. Settings → General
2. Log Level → Debug
3. Reproduce issue
4. Check logs

**qBittorrent:**
1. Tools → Options → Web UI
2. Log Level → Info
3. Check logs in container

### Collect Information for Bug Report

When asking for help, include:

1. **System info:**
   - OS and version
   - Docker version: `docker --version`
   - Docker Compose version: `docker compose version`

2. **Service logs:**
   ```bash
   docker compose logs <problematic-service> > logs.txt
   ```

3. **Container status:**
   ```bash
   docker compose ps
   ```

4. **Config (sanitized):**
   - .env file (remove sensitive data)
   - Error messages

### Where to Get Help

- 📖 [Read other docs](README.md)
- 🐛 [GitHub Issues](../../issues)
- 💬 Reddit: r/jellyfin, r/sonarr, r/radarr
- 💬 Discord: Jellyfin, Sonarr/Radarr communities

---

## Common Error Messages

| Error | Meaning | Solution |
|-------|---------|----------|
| `Connection refused` | Service not reachable | Check service is running, use correct hostname |
| `Unauthorized` | Wrong credentials | Check username/password/API key |
| `404 Not Found` | Wrong URL | Verify URL and port |
| `Port already in use` | Port conflict | Change port in .env |
| `No space left on device` | Disk full | Free up space |
| `Permission denied` | File permission issue | Check PUID/PGID, chmod files |

---

**Still stuck?** Open an issue on GitHub with details!
