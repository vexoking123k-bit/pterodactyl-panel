#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p /etc/pterodactyl /var/lib/pterodactyl/volumes /var/log/pterodactyl
if [ ! -x /usr/local/bin/wings ]; then
  curl -fL https://github.com/pterodactyl/wings/releases/download/v1.13.5/wings_linux_amd64 -o /usr/local/bin/wings
  chmod 755 /usr/local/bin/wings
fi
docker compose cp scripts/provision-minecraft.php panel:/app/var/provision-minecraft.php
docker compose exec -T -e CODESPACE_WINGS_DOMAIN="${CODESPACE_NAME}-8081.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}" panel php /app/var/provision-minecraft.php setup
docker compose cp panel:/app/var/wings-config.json /etc/pterodactyl/config.yml
chmod 600 /etc/pterodactyl/config.yml
if ! pgrep -x wings >/dev/null; then
  nohup /usr/local/bin/wings --config /etc/pterodactyl/config.yml > /var/log/pterodactyl/wings.log 2>&1 < /dev/null &
fi
ready=0
for attempt in $(seq 1 30); do
  if curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8081/api/system | grep -qE '401|403'; then ready=1; break; fi
  sleep 2
done
if [ "$ready" -ne 1 ]; then
  tail -n 30 /var/log/pterodactyl/wings.log >&2
  exit 1
fi
docker compose exec -T panel php /app/var/provision-minecraft.php create
docker compose exec -T panel test -s /app/var/minecraft-server.json
echo "Minecraft files are being installed. EULA acceptance is still required before first start."
