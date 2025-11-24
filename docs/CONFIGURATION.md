# Configuration Guide

This guide will walk you through configuring each service after installation. Follow these steps in order for the best experience.

## Table of Contents

1. [qBittorrent Setup](#1-qbittorrent-setup)
2. [Prowlarr Setup](#2-prowlarr-setup)
3. [Sonarr Setup](#3-sonarr-setup)
4. [Radarr Setup](#4-radarr-setup)
5. [Jellyfin Setup](#5-jellyfin-setup)
6. [Jellyseerr Setup](#6-jellyseerr-setup)
7. [Testing Everything](#7-testing-everything)

---

## 1. qBittorrent Setup

qBittorrent is your torrent download client.

### First Login

1. Open http://localhost:8080
2. **Default credentials:**
   - Username: `admin`
   - Password: `adminadmin`

### Change Password (Important!)

1. Click **Tools** → **Options**
2. Go to **Web UI** tab
3. Under **Authentication**:
   - Enter a new, strong password
   - Click **Save**

### Configure Downloads

1. Still in **Options**, go to **Downloads** tab
2. Set **Default Save Path**: `/downloads`
3. Enable **Keep incomplete torrents in**: `/downloads/incomplete`
4. Check **Append .!qB extension**
5. Click **Save**

### Create Categories

1. Right-click in the Categories section (left sidebar)
2. **Add category:**
   - Name: `tv-sonarr`
   - Save path: `/downloads/tvshows`
3. **Add another category:**
   - Name: `movies-radarr`
   - Save path: `/downloads/movies`

### Configure Connection (Optional but Recommended)

1. **Options** → **Connection**
2. Port used for incoming connections: `6881` (already set)
3. Enable **UPnP / NAT-PMP** (if your router supports it)
4. Click **Save**

### Bandwidth Settings (Optional)

If you want to limit speeds:

1. **Options** → **Speed**
2. Set limits as desired
3. Enable **Alternative Rate Limits** for scheduled throttling

---

## 2. Prowlarr Setup

Prowlarr manages torrent indexers and syncs them to Sonarr/Radarr.

### First Login

1. Open http://localhost:9696
2. No default credentials - you'll create an account

### Add Indexers

#### Add Public Indexers

1. Go to **Indexers** → **Add Indexer**
2. Search for:
   - **1337x**
   - **The Pirate Bay**
   - **RARBG** (if available)
   - **YTS** (for movies)
3. For each indexer:
   - Click the name
   - Set **Minimum Seeders**: 1
   - Click **Test**
   - Click **Save**

#### Add More Indexers (Optional)

Popular public indexers:
- LimeTorrents
- TorrentGalaxy
- EZTV (TV shows)
- Nyaa (Anime)

#### Private Trackers (Optional)

If you have accounts on private trackers:
1. Add the indexer
2. Enter your credentials or API key
3. Test and save

### Configure FlareSolverr (For Cloudflare-Protected Sites)

Some indexers are protected by Cloudflare. To bypass:

1. **Settings** → **Indexers**
2. Scroll to **Indexer Proxies**
3. Click **+** to add
4. Select **FlareSolverr**
5. **Tags**: Leave empty (applies to all)
6. **Host**: `http://flaresolverr:8191/`
7. Click **Test** then **Save**

### Add Applications (Connect to Sonarr/Radarr)

We'll do this after configuring Sonarr and Radarr.

---

## 3. Sonarr Setup

Sonarr manages TV show downloads.

### First Login

1. Open http://localhost:8989
2. No default credentials - create an account if prompted

### Get API Key

1. **Settings** → **General**
2. Scroll to **Security**
3. Copy the **API Key** (you'll need this for Prowlarr and Jellyseerr)
4. Enable **Authentication**: Forms (Web UI) or Basic (for mobile apps)
5. Create a username and password
6. Click **Save Changes**

### Add Download Client (qBittorrent)

1. **Settings** → **Download Clients**
2. Click **+** → **qBittorrent**
3. Configure:
   - **Name**: qBittorrent
   - **Host**: `qbittorrent`
   - **Port**: `8080`
   - **Username**: `admin`
   - **Password**: (your qBittorrent password)
   - **Category**: `tv-sonarr`
4. Click **Test** (should show green checkmark)
5. Click **Save**

### Configure Media Management

1. **Settings** → **Media Management**
2. **Enable** these options:
   - ✅ Rename Episodes
   - ✅ Replace Illegal Characters
   - ✅ Unmonitor Deleted Episodes
3. **Episode Naming:**
   - **Standard Episode Format**: `{Series Title} - S{season:00}E{episode:00} - {Episode Title}`
   - **Daily Episode Format**: `{Series Title} - {Air-Date} - {Episode Title}`
   - **Anime Episode Format**: `{Series Title} - S{season:00}E{episode:00}`
4. **Root Folders:**
   - Click **Add Root Folder**
   - Enter: `/tv`
   - Click OK
5. Click **Save Changes**

### Configure Quality Profiles

1. **Settings** → **Profiles**
2. Edit **HD-1080p** profile (or create new):
   - Move **WEBDL-1080p**, **WEBRip-1080p**, **Bluray-1080p** to top
   - This prioritizes 1080p content
3. Click **Save Changes**

---

## 4. Radarr Setup

Radarr manages movie downloads (very similar to Sonarr).

### First Login

1. Open http://localhost:7878
2. Create account if prompted

### Get API Key

1. **Settings** → **General**
2. Copy the **API Key**
3. Enable **Authentication** and set credentials
4. Click **Save Changes**

### Add Download Client (qBittorrent)

1. **Settings** → **Download Clients**
2. Click **+** → **qBittorrent**
3. Configure:
   - **Name**: qBittorrent
   - **Host**: `qbittorrent`
   - **Port**: `8080`
   - **Username**: `admin`
   - **Password**: (your qBittorrent password)
   - **Category**: `movies-radarr`
4. Click **Test**
5. Click **Save**

### Configure Media Management

1. **Settings** → **Media Management**
2. **Enable**:
   - ✅ Rename Movies
   - ✅ Replace Illegal Characters
   - ✅ Unmonitor Deleted Movies
3. **Movie Naming:**
   - **Standard Movie Format**: `{Movie Title} ({Release Year})`
   - **Movie Folder Format**: `{Movie Title} ({Release Year})`
4. **Root Folders:**
   - Click **Add Root Folder**
   - Enter: `/movies`
   - Click OK
5. Click **Save Changes**

### Configure Quality Profiles

1. **Settings** → **Profiles**
2. Edit **HD-1080p**:
   - Prioritize WEBDL-1080p and Bluray-1080p
3. Click **Save Changes**

---

## 5. Connect Prowlarr to Sonarr/Radarr

Now we'll connect everything together.

### Add Sonarr to Prowlarr

1. Open **Prowlarr** (http://localhost:9696)
2. **Settings** → **Apps**
3. Click **+** → **Sonarr**
4. Configure:
   - **Prowlarr Server**: `http://localhost:9696`
   - **Sonarr Server**: `http://sonarr:8989`
   - **API Key**: (paste Sonarr API key from step 3)
   - **Sync Level**: Add and Remove Only
5. Click **Test**
6. Click **Save**

### Add Radarr to Prowlarr

1. Still in **Settings** → **Apps**
2. Click **+** → **Radarr**
3. Configure:
   - **Prowlarr Server**: `http://localhost:9696`
   - **Radarr Server**: `http://radarr:7878`
   - **API Key**: (paste Radarr API key from step 4)
   - **Sync Level**: Add and Remove Only
4. Click **Test**
5. Click **Save**

### Sync Indexers

1. Click **Sync App Indexers** button
2. All your Prowlarr indexers will now appear in Sonarr and Radarr automatically!

---

## 6. Jellyfin Setup

Jellyfin is your media server for streaming.

### Initial Setup Wizard

1. Open http://localhost:8096
2. **Welcome screen**: Select your language
3. **Create Admin Account:**
   - Username: (choose yours)
   - Password: (strong password)
4. **Media Libraries**: We'll add these in the next step
5. **Metadata Language**: English (or your preference)
6. **Remote Access**: Leave defaults
7. **Finish** setup

### Add Media Libraries

1. **Dashboard** → **Libraries**
2. Click **Add Media Library**

#### Add TV Shows Library

- **Content type**: Shows
- **Display name**: TV Shows
- **Folders**: Click **+** and enter `/data/tvshows`
- **Library settings**: Leave defaults
- Click **OK**

#### Add Movies Library

- **Content type**: Movies
- **Display name**: Movies
- **Folders**: Click **+** and enter `/data/movies`
- **Library settings**: Leave defaults
- Click **OK**

### Scan Libraries

1. Go to **Dashboard** → **Libraries**
2. Click **Scan All Libraries**
3. This will find any existing media

### Get API Key (For Jellyseerr)

1. **Dashboard** → **API Keys**
2. Click **+** to add new key
3. **App Name**: Jellyseerr
4. Copy the generated API key
5. Click **OK**

---

## 7. Jellyseerr Setup

Jellyseerr is your beautiful request interface.

### Initial Setup

1. Open http://localhost:5055
2. Click **Use your Jellyfin account**

### Configure Jellyfin

1. **Server URL**: `http://jellyfin:8096`
2. Click **Sign in with Jellyfin**
3. Enter your Jellyfin username and password
4. Click **Sign In**

### Configure Sonarr

1. **Add Sonarr Server**
2. **Server Name**: Sonarr
3. **Hostname or IP**: `sonarr`
4. **Port**: `8989`
5. **API Key**: (paste Sonarr API key)
6. **URL Base**: Leave empty
7. **Use SSL**: Unchecked
8. Click **Test** (should succeed)
9. **Quality Profile**: HD-1080p
10. **Root Folder**: `/tv`
11. **Minimum Availability**: Released (or Announced for early grabbing)
12. Click **Add Server**

### Configure Radarr

1. **Add Radarr Server**
2. **Server Name**: Radarr
3. **Hostname or IP**: `radarr`
4. **Port**: `7878`
5. **API Key**: (paste Radarr API key)
6. **URL Base**: Leave empty
7. **Use SSL**: Unchecked
8. Click **Test**
9. **Quality Profile**: HD-1080p
10. **Root Folder**: `/movies`
11. **Minimum Availability**: Released
12. Click **Add Server**

### Finish Setup

1. Click **Finish Setup**
2. You're done! 🎉

---

## 8. Testing Everything

Let's make sure everything works end-to-end.

### Test 1: Search in Jellyseerr

1. Open **Jellyseerr** (http://localhost:5055)
2. Search for a public domain movie (e.g., "Night of the Living Dead")
3. Click the movie
4. Click **Request**
5. It should show "Requested"

### Test 2: Check Radarr

1. Open **Radarr** (http://localhost:7878)
2. Go to **Activity** → **Queue**
3. You should see the movie searching/downloading

### Test 3: Check qBittorrent

1. Open **qBittorrent** (http://localhost:8080)
2. You should see the torrent downloading
3. It should be in the `movies-radarr` category

### Test 4: Wait for Download

- Once download completes:
  - qBittorrent will seed the file
  - Radarr will move it to `/movies`
  - Jellyfin will detect it automatically (or scan library)

### Test 5: Watch in Jellyfin

1. Open **Jellyfin** (http://localhost:8096)
2. The movie should appear in your library
3. Click to play and verify it works

---

## Common Configuration Issues

### Can't Connect Services

**Issue**: Prowlarr can't reach Sonarr/Radarr

**Solution**: Make sure you use service names (`sonarr`, `radarr`) not `localhost`

### Downloads Not Starting

**Issue**: Torrent added but not downloading

**Checklist**:
- ✅ qBittorrent credentials correct in Sonarr/Radarr?
- ✅ Categories set correctly?
- ✅ Prowlarr indexers active and working?
- ✅ Check Sonarr/Radarr logs for errors

### Jellyfin Not Finding Media

**Issue**: Downloaded files don't appear in Jellyfin

**Solutions**:
- Manual scan: Dashboard → Libraries → Scan All Libraries
- Check file is in correct location (`/data/movies` or `/data/tvshows`)
- Check file permissions
- Wait a few minutes (automatic scan runs periodically)

---

## Next Steps

Now that everything is configured:

1. **Add your favorite shows** in Jellyseerr or directly in Sonarr
2. **Add movies** you want to watch
3. **Configure notifications** (optional) in Sonarr/Radarr
4. **Set up mobile apps** - see [MOBILE-APPS.md](MOBILE-APPS.md)
5. **Configure backups** of your config folder

---

**Enjoy your automated media setup!** 🍿

For issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
