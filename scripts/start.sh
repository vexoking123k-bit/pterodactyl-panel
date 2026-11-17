#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -d panel-source/.git ]; then
  git clone --depth 1 --branch v1.15.2 https://github.com/pterodactyl/panel.git panel-source
fi
if git -C panel-source apply --check ../theme.patch 2>/dev/null; then
  git -C panel-source apply ../theme.patch
elif ! git -C panel-source apply --reverse --check ../theme.patch 2>/dev/null; then
  echo "Theme differs from the pinned source. Inspect panel-source before continuing." >&2
  exit 1
fi
if [ ! -f .env ]; then
  umask 077
  python3 - <<'PY'
import base64, os, pathlib, secrets
name=os.environ.get("CODESPACE_NAME")
domain=os.environ.get("GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN","app.github.dev")
url=f"https://{name}-8080.{domain}" if name else "https://panel.example.invalid"
values={"APP_URL":url,"DB_ROOT_PASSWORD":secrets.token_hex(32),"DB_PASSWORD":secrets.token_hex(32),"APP_KEY":"base64:"+base64.b64encode(secrets.token_bytes(32)).decode(),"HASHIDS_SALT":secrets.token_hex(24)}
pathlib.Path(".env").write_text("".join(f"{k}={v}\n" for k,v in values.items()))
PY
fi
docker compose up -d --build
echo "Panel is starting. Check: docker compose ps"
echo "Create your administrator: docker compose exec panel php artisan p:user:make"
