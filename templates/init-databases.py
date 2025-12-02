#!/usr/bin/env python3
"""
Database Initialization Script - Cross-Platform
Pre-configures Prowlarr, Sonarr, and Radarr with sensible defaults
Works on Windows, macOS, and Linux
"""

import sqlite3
import os
import sys
import time
from pathlib import Path
from datetime import datetime

# ANSI color codes (work on most terminals, fallback gracefully on Windows)
try:
    from colorama import init as colorama_init
    colorama_init()
except ImportError:
    pass

BLUE = '\033[0;34m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
NC = '\033[0m'

def print_info(message):
    print(f"{BLUE}[INFO]{NC} {message}")

def print_success(message):
    print(f"{GREEN}[✓]{NC} {message}")

def print_warning(message):
    print(f"{YELLOW}[WARNING]{NC} {message}")

def print_error(message):
    print(f"{RED}[ERROR]{NC} {message}")

def get_project_dir():
    """Get the project root directory"""
    script_dir = Path(__file__).parent.absolute()
    return script_dir.parent

def check_db_ready(db_path):
    """Check if database exists and has tables"""
    if not db_path.exists():
        return False

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table'")
        count = cursor.fetchone()[0]
        conn.close()
        return count > 5
    except Exception:
        return False

def wait_for_database(db_path, service_name, max_wait=120):
    """Wait for database to be ready"""
    print_info(f"⏳ Waiting for {service_name} database...")

    for i in range(max_wait):
        if check_db_ready(db_path):
            print_success(f"{service_name} database ready")
            return True
        time.sleep(2)

    print_error(f"{service_name} database did not initialize in time")
    return False

def configure_prowlarr_indexers(db_path):
    """Add public indexers to Prowlarr"""
    print_info("📋 Configuring Prowlarr indexers...")

    indexers = [
        {
            'name': '1337x',
            'definition': '1337x',
            'settings': '{"definitionFile":"1337x","extraFieldData":{"uploader":"","sort":2,"type":1},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}'
        },
        {
            'name': 'The Pirate Bay',
            'definition': 'thepiratebay',
            'settings': '{"definitionFile":"thepiratebay","extraFieldData":{"uploader":""},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}'
        },
        {
            'name': 'YTS',
            'definition': 'yts',
            'settings': '{"definitionFile":"yts","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}'
        },
        {
            'name': 'EZTV',
            'definition': 'eztv',
            'settings': '{"definitionFile":"eztv","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}'
        },
        {
            'name': 'TorrentGalaxy',
            'definition': 'torrentgalaxy',
            'settings': '{"definitionFile":"torrentgalaxy","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}'
        },
        {
            'name': 'Torlock',
            'definition': 'torlock',
            'settings': '{"definitionFile":"torlock","extraFieldData":{},"baseSettings":{"limitsUnit":0},"torrentBaseSettings":{"preferMagnetUrl":false}}'
        }
    ]

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Clear existing indexers
        cursor.execute("DELETE FROM Indexers")

        # Add indexers
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        for indexer in indexers:
            cursor.execute("""
                INSERT INTO Indexers (Name, Implementation, ConfigContract, Settings, Protocol, Priority, Enable, Added)
                VALUES (?, 'Cardigann', 'CardigannSettings', ?, 1, 25, 1, ?)
            """, (indexer['name'], indexer['settings'], now))

        conn.commit()
        conn.close()

        print_success(f"Added {len(indexers)} public indexers to Prowlarr")
        return True
    except Exception as e:
        print_error(f"Failed to configure Prowlarr indexers: {e}")
        return False

def configure_prowlarr_applications(db_path):
    """Connect Prowlarr to Sonarr and Radarr"""
    print_info("📋 Configuring Prowlarr applications...")

    applications = [
        {
            'name': 'Sonarr',
            'implementation': 'Sonarr',
            'settings': '{"prowlarrUrl":"http://prowlarr:9696","baseUrl":"http://sonarr:8989","apiKey":"f7425b1d04114fa887a6867d867f8bf5","syncCategories":[5000,5010,5020,5030,5040,5045,5050,5090],"animeSyncCategories":[5070],"syncAnimeStandardFormatSearch":true,"syncRejectBlocklistedTorrentHashesWhileGrabbing":false}',
            'contract': 'SonarrSettings'
        },
        {
            'name': 'Radarr',
            'implementation': 'Radarr',
            'settings': '{"prowlarrUrl":"http://prowlarr:9696","baseUrl":"http://radarr:7878","apiKey":"2707496c99a5496fa7e66d2b100963b1","syncCategories":[2000,2010,2020,2030,2040,2045,2050,2060,2070,2080,2090],"syncRejectBlocklistedTorrentHashesWhileGrabbing":false}',
            'contract': 'RadarrSettings'
        }
    ]

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Clear existing applications
        cursor.execute("DELETE FROM Applications")

        # Add applications
        for app in applications:
            cursor.execute("""
                INSERT INTO Applications (Name, Implementation, Settings, ConfigContract, SyncLevel, Tags)
                VALUES (?, ?, ?, ?, 2, '[]')
            """, (app['name'], app['implementation'], app['settings'], app['contract']))

        conn.commit()
        conn.close()

        print_success("Connected Prowlarr to Sonarr and Radarr")
        return True
    except Exception as e:
        print_error(f"Failed to configure Prowlarr applications: {e}")
        return False

def configure_sonarr_download_client(db_path):
    """Add qBittorrent to Sonarr"""
    print_info("📋 Configuring Sonarr download client...")

    settings = '{"host":"qbittorrent","port":8888,"useSsl":false,"username":"admin","password":"adminadmin","tvCategory":"tv-sonarr","recentTvPriority":0,"olderTvPriority":0,"initialState":0,"sequentialOrder":false,"firstAndLast":false,"contentLayout":0}'

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Clear existing download clients
        cursor.execute("DELETE FROM DownloadClients")

        # Add qBittorrent
        cursor.execute("""
            INSERT INTO DownloadClients (Enable, Name, Implementation, Settings, ConfigContract, Priority)
            VALUES (1, 'qBittorrent', 'QBittorrent', ?, 'QBittorrentSettings', 1)
        """, (settings,))

        conn.commit()
        conn.close()

        print_success("Connected Sonarr to qBittorrent")
        return True
    except Exception as e:
        print_error(f"Failed to configure Sonarr download client: {e}")
        return False

def configure_radarr_download_client(db_path):
    """Add qBittorrent to Radarr"""
    print_info("📋 Configuring Radarr download client...")

    settings = '{"host":"qbittorrent","port":8888,"useSsl":false,"username":"admin","password":"adminadmin","movieCategory":"movies-radarr","recentMoviePriority":0,"olderMoviePriority":0,"initialState":0,"sequentialOrder":false,"firstAndLast":false,"contentLayout":0}'

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Clear existing download clients
        cursor.execute("DELETE FROM DownloadClients")

        # Add qBittorrent
        cursor.execute("""
            INSERT INTO DownloadClients (Enable, Name, Implementation, Settings, ConfigContract, Priority)
            VALUES (1, 'qBittorrent', 'QBittorrent', ?, 'QBittorrentSettings', 1)
        """, (settings,))

        conn.commit()
        conn.close()

        print_success("Connected Radarr to qBittorrent")
        return True
    except Exception as e:
        print_error(f"Failed to configure Radarr download client: {e}")
        return False

def configure_sonarr_root_folder(db_path):
    """Add root folder to Sonarr"""
    print_info("📋 Configuring Sonarr root folder...")

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Clear existing root folders
        cursor.execute("DELETE FROM RootFolders")

        # Add TV root folder
        cursor.execute("INSERT INTO RootFolders (Path) VALUES ('/tv')")

        conn.commit()
        conn.close()

        print_success("Added /tv root folder to Sonarr")
        return True
    except Exception as e:
        print_error(f"Failed to configure Sonarr root folder: {e}")
        return False

def configure_radarr_root_folder(db_path):
    """Add root folder to Radarr"""
    print_info("📋 Configuring Radarr root folder...")

    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()

        # Clear existing root folders
        cursor.execute("DELETE FROM RootFolders")

        # Add Movies root folder
        cursor.execute("INSERT INTO RootFolders (Path) VALUES ('/movies')")

        conn.commit()
        conn.close()

        print_success("Added /movies root folder to Radarr")
        return True
    except Exception as e:
        print_error(f"Failed to configure Radarr root folder: {e}")
        return False

def main():
    print(f"{BLUE}🔧 Initializing service databases with pre-configured settings...{NC}")
    print()

    project_dir = get_project_dir()
    config_dir = project_dir / 'config'

    # Wait for services to create initial databases
    print_info("⏳ Waiting for services to initialize (30 seconds)...")
    time.sleep(30)
    print()

    # Database paths
    prowlarr_db = config_dir / 'prowlarr' / 'prowlarr.db'
    sonarr_db = config_dir / 'sonarr' / 'sonarr.db'
    radarr_db = config_dir / 'radarr' / 'radarr.db'

    # Wait for databases to be ready
    success = True
    success &= wait_for_database(prowlarr_db, 'Prowlarr')
    success &= wait_for_database(sonarr_db, 'Sonarr')
    success &= wait_for_database(radarr_db, 'Radarr')

    if not success:
        print_error("Some databases did not initialize properly")
        sys.exit(1)

    print()

    # Configure Prowlarr
    configure_prowlarr_indexers(prowlarr_db)
    print()
    configure_prowlarr_applications(prowlarr_db)
    print()

    # Configure Sonarr
    configure_sonarr_download_client(sonarr_db)
    print()
    configure_sonarr_root_folder(sonarr_db)
    print()

    # Configure Radarr
    configure_radarr_download_client(radarr_db)
    print()
    configure_radarr_root_folder(radarr_db)
    print()

    print(f"{GREEN}🎉 Database initialization complete!{NC}")
    print()
    print("📝 Next steps:")
    print("   1. Restart all services: docker compose restart")
    print("   2. Access Jellyseerr at http://localhost:5055 to complete setup")
    print()

if __name__ == '__main__':
    main()
