#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
mkdir -p backups
stamp=$(date -u +%Y%m%dT%H%M%SZ)
docker compose exec -T database sh -c 'MYSQL_PWD="$MARIADB_PASSWORD" mariadb-dump -u pterodactyl --single-transaction panel' | gzip > "backups/panel-$stamp.sql.gz"
cp .env "backups/panel-$stamp.env"
if [ -d /var/lib/pterodactyl/volumes ]; then
  tar -czf "backups/minecraft-$stamp.tar.gz" -C /var/lib/pterodactyl volumes
fi
if [ -f /etc/pterodactyl/config.yml ]; then
  cp /etc/pterodactyl/config.yml "backups/wings-$stamp.yml"
fi
echo "Database, encryption settings, Wings configuration, and Minecraft files saved in backups/. Copy them outside this Codespace."
