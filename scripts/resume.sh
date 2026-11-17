#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -f .env ] && docker image inspect pterodactyl-workbench:1.15.2 >/dev/null 2>&1; then
  docker compose up -d
else
  echo "Run bash scripts/start.sh for the first installation."
fi
if [ -f /etc/pterodactyl/config.yml ] && [ -x /usr/local/bin/wings ] && ! pgrep -x wings >/dev/null; then
  nohup /usr/local/bin/wings --config /etc/pterodactyl/config.yml > /var/log/pterodactyl/wings.log 2>&1 < /dev/null &
fi
