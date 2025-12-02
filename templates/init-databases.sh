#!/bin/bash
# Database Initialization Script
# This script pre-configures Prowlarr, Sonarr, and Radarr with sensible defaults

set -e

# Detect if running inside Docker container
if [ -d "/config" ] && [ -d "/templates" ]; then
    # Running in Docker container
    PROJECT_DIR=""
    CONFIG_DIR="/config"
else
    # Running on host system
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    CONFIG_DIR="$PROJECT_DIR/config"
fi

echo "🔧 Initializing service databases with pre-configured settings..."

# Wait for services to create initial databases
echo "⏳ Waiting for services to initialize (30 seconds)..."
sleep 30

# Function to check if database exists and has tables
check_db_ready() {
    local db_path=$1
    if [ -f "$db_path" ]; then
        table_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "0")
        [ "$table_count" -gt 5 ]
        return $?
    fi
    return 1
}

# Wait for Prowlarr database
echo "⏳ Waiting for Prowlarr database..."
for i in {1..60}; do
    if check_db_ready "$CONFIG_DIR/prowlarr/prowlarr.db"; then
        echo "✅ Prowlarr database ready"
        break
    fi
    sleep 2
done

# Wait for Sonarr database
echo "⏳ Waiting for Sonarr database..."
for i in {1..60}; do
    if check_db_ready "$CONFIG_DIR/sonarr/sonarr.db"; then
        echo "✅ Sonarr database ready"
        break
    fi
    sleep 2
done

# Wait for Radarr database
echo "⏳ Waiting for Radarr database..."
for i in {1..60}; do
    if check_db_ready "$CONFIG_DIR/radarr/radarr.db"; then
        echo "✅ Radarr database ready"
        break
    fi
    sleep 2
done

echo ""
echo "📋 Configuring Prowlarr indexers..."

# Add public indexers to Prowlarr
sqlite3 "$CONFIG_DIR/prowlarr/prowlarr.db" <<'EOF'
-- Clear existing indexers
DELETE FROM Indexers;

-- Add 1337x
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  '1337x',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"1337x","extraFieldData":{"uploader":"","sort":2,"type":1},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);

-- Add The Pirate Bay
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  'The Pirate Bay',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"thepiratebay","extraFieldData":{"uploader":""},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);

-- Add YTS
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  'YTS',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"yts","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);

-- Add EZTV
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  'EZTV',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"eztv","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);

-- Add TorrentGalaxy
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  'TorrentGalaxy',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"torrentgalaxy","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);

-- Add Torlock
INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
VALUES (
  'Torlock',
  'Cardigann',
  'CardigannSettings',
  '{"definitionFile":"torlock","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}',
  1, 25, 1, datetime('now')
);
EOF

echo "✅ Added 6 public indexers to Prowlarr"

echo ""
echo "📋 Configuring Prowlarr applications..."

# Add Sonarr and Radarr to Prowlarr
sqlite3 "$CONFIG_DIR/prowlarr/prowlarr.db" <<'EOF'
-- Clear existing applications
DELETE FROM Applications;

-- Add Sonarr
INSERT INTO Applications (Name, Implementation, Settings, ConfigContract, SyncLevel, Tags)
VALUES (
  'Sonarr',
  'Sonarr',
  '{"prowlarrUrl":"http://prowlarr:9696","baseUrl":"http://sonarr:8989","apiKey":"f7425b1d04114fa887a6867d867f8bf5","syncCategories":[5000,5010,5020,5030,5040,5045,5050,5090],"animeSyncCategories":[5070],"syncAnimeStandardFormatSearch":true,"syncRejectBlocklistedTorrentHashesWhileGrabbing":false}',
  'SonarrSettings',
  2,
  '[]'
);

-- Add Radarr
INSERT INTO Applications (Name, Implementation, Settings, ConfigContract, SyncLevel, Tags)
VALUES (
  'Radarr',
  'Radarr',
  '{"prowlarrUrl":"http://prowlarr:9696","baseUrl":"http://radarr:7878","apiKey":"2707496c99a5496fa7e66d2b100963b1","syncCategories":[2000,2010,2020,2030,2040,2045,2050,2060,2070,2080,2090],"syncRejectBlocklistedTorrentHashesWhileGrabbing":false}',
  'RadarrSettings',
  2,
  '[]'
);
EOF

echo "✅ Connected Prowlarr to Sonarr and Radarr"

echo ""
echo "📋 Configuring Sonarr download client..."

# Add qBittorrent to Sonarr
sqlite3 "$CONFIG_DIR/sonarr/sonarr.db" <<'EOF'
-- Clear existing download clients
DELETE FROM DownloadClients;

-- Add qBittorrent
INSERT INTO DownloadClients (Enable, Name, Implementation, Settings, ConfigContract, Priority)
VALUES (
  1,
  'qBittorrent',
  'QBittorrent',
  '{"host":"qbittorrent","port":8888,"useSsl":false,"username":"admin","password":"adminadmin","tvCategory":"tv-sonarr","recentTvPriority":0,"olderTvPriority":0,"initialState":0,"sequentialOrder":false,"firstAndLast":false,"contentLayout":0}',
  'QBittorrentSettings',
  1
);
EOF

echo "✅ Connected Sonarr to qBittorrent"

echo ""
echo "📋 Configuring Radarr download client..."

# Add qBittorrent to Radarr
sqlite3 "$CONFIG_DIR/radarr/radarr.db" <<'EOF'
-- Clear existing download clients
DELETE FROM DownloadClients;

-- Add qBittorrent
INSERT INTO DownloadClients (Enable, Name, Implementation, Settings, ConfigContract, Priority)
VALUES (
  1,
  'qBittorrent',
  'QBittorrent',
  '{"host":"qbittorrent","port":8888,"useSsl":false,"username":"admin","password":"adminadmin","movieCategory":"movies-radarr","recentMoviePriority":0,"olderMoviePriority":0,"initialState":0,"sequentialOrder":false,"firstAndLast":false,"contentLayout":0}',
  'QBittorrentSettings',
  1
);
EOF

echo "✅ Connected Radarr to qBittorrent"

echo ""
echo "📋 Configuring Sonarr root folder..."

# Add root folder to Sonarr
sqlite3 "$CONFIG_DIR/sonarr/sonarr.db" <<'EOF'
-- Clear existing root folders
DELETE FROM RootFolders;

-- Add TV root folder
INSERT INTO RootFolders (Path)
VALUES ('/tv');
EOF

echo "✅ Added /tv root folder to Sonarr"

echo ""
echo "📋 Configuring Radarr root folder..."

# Add root folder to Radarr
sqlite3 "$CONFIG_DIR/radarr/radarr.db" <<'EOF'
-- Clear existing root folders
DELETE FROM RootFolders;

-- Add Movies root folder
INSERT INTO RootFolders (Path)
VALUES ('/movies');
EOF

echo "✅ Added /movies root folder to Radarr"

echo ""
echo "🎉 Database initialization complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Restart all services: docker compose restart"
echo "   2. Access Jellyseerr at http://localhost:5055 to complete setup"
echo ""
