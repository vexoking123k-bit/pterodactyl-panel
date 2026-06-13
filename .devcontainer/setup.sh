#!/bin/bash
set -e

echo "==> Installing Docker Compose..."
apt-get update -qq
apt-get install -y -qq docker-compose curl

echo "==> Starting Pterodactyl via Docker Compose..."
cd /workspaces/pterodactyl-panel
docker-compose up -d

echo "==> Waiting for panel to be ready..."
for i in $(seq 1 30); do
  if curl -s http://localhost/auth/login | grep -q "Pterodactyl\|Login"; then
    echo "Panel is up!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 10
done

echo "==> Creating admin user..."
docker-compose exec -T panel php artisan p:user:make \
  --email=admin@admin.com \
  --username=admin \
  --name-first=Admin \
  --name-last=User \
  --password=Admin1234! \
  --admin=1 2>/dev/null || true

echo ""
echo "======================================"
echo " Pterodactyl Panel is ready!"
echo " URL: http://localhost"
echo " Email: admin@admin.com"
echo " Password: Admin1234!"
echo "======================================"
