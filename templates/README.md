# Templates Directory

This directory contains pre-configured template files for automatic service setup.

## Contents

### Configuration Templates

- **`prowlarr/config.xml`** - Prowlarr API key and basic settings
- **`sonarr/config.xml`** - Sonarr API key and basic settings
- **`radarr/config.xml`** - Radarr API key and basic settings

### Initialization Scripts

- **`init-databases.py`** - Python script (cross-platform: Windows, macOS, Linux)
- **`init-databases.sh`** - Bash script (Linux fallback if Python unavailable)

Both scripts automatically populate service databases with:
- 6 pre-configured public torrent indexers
- Service connection settings
- Download client configurations
- Root folder paths
- Quality profiles

## How It Works

When you run `./setup-auto.sh`, the following happens:

1. Template XML files are copied to the `config/` directories
2. Services start with pre-configured API keys
3. Setup script detects available tools:
   - **Python 3** (preferred, works on all platforms)
   - **sqlite3** (Linux fallback)
4. Initialization script waits for services to create databases
5. Python/SQL commands populate the databases with:
   - Indexer definitions
   - Application connections (Prowlarr → Sonarr/Radarr)
   - Download client connections (Sonarr/Radarr → qBittorrent)
   - Root folders and categories
6. Services are restarted to apply changes

**Cross-Platform Compatibility:**
- **Windows**: Uses Python (included with Docker Desktop)
- **macOS**: Uses Python (pre-installed on macOS)
- **Linux**: Uses Python (usually pre-installed), falls back to bash/sqlite3 if needed

## Pre-Configured API Keys

For convenience, the following API keys are pre-configured:

- **Prowlarr**: `d584556d776e4d2abbebb8b5c0bb34b2`
- **Sonarr**: `f7425b1d04114fa887a6867d867f8bf5`
- **Radarr**: `2707496c99a5496fa7e66d2b100963b1`

These keys are used for **service-to-service communication only** and are safe for local-only deployments.

### Why Pre-Configured Keys Are Safe

✅ **Local-Only Access**: Services are not exposed to the internet
✅ **Internal Communication**: Keys are only for services talking to each other
✅ **Not User Passwords**: You still set your own login passwords
✅ **Convenience**: Allows fully automated setup for non-technical users

### If You Want Different Keys

To regenerate API keys for additional security:

1. Delete the XML files in `config/prowlarr/`, `config/sonarr/`, `config/radarr/`
2. Restart services: `docker compose restart`
3. Services will generate new random API keys
4. Manually reconnect services using the new keys

## Pre-Configured Indexers

The setup includes 6 public torrent indexers:

1. **1337x** - General purpose
2. **The Pirate Bay** - General purpose
3. **YTS** - Movies (small file sizes)
4. **EZTV** - TV shows
5. **TorrentGalaxy** - General purpose
6. **Torlock** - General purpose

All indexers are configured with:
- Minimum seeders: 1
- Standard priority: 25
- Enabled by default

## Modifying Templates

If you want to customize the default setup:

### Add More Indexers

Edit `init-databases.sh` and add SQL INSERT statements following this pattern:

```sql
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  'IndexerName',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"indexer-slug","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);
```

### Change Default Settings

Edit the SQL commands in `init-databases.sh` to modify:
- Quality profiles
- Download priorities
- Category names
- Root folder paths

### Use Different API Keys

Edit the XML template files to change the `<ApiKey>` values.

## Security Note

**These templates are intended for local-only deployments.**

If you plan to expose services externally (not recommended without proper security):
1. Regenerate all API keys
2. Set up HTTPS with valid certificates
3. Use strong authentication
4. Consider using a VPN (Tailscale, WireGuard)
5. Never use pre-configured keys for public-facing services

## Support

For questions or issues with templates:
- See [QUICKSTART.md](../QUICKSTART.md) for usage
- See [docs/CONFIGURATION.md](../docs/CONFIGURATION.md) for manual configuration
- See [docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) for common issues
