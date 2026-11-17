# Pterodactyl Panel Workbench

Customized Pterodactyl v1.15.2 for a GitHub Codespaces development environment.

## Start and resume

Run `bash scripts/start.sh` for the first installation. Open forwarded port **8080** with **Private** visibility, and create your own administrator with:

```sh
docker compose exec panel php artisan p:user:make
```

After a Codespace restart, `bash scripts/resume.sh` starts existing services. This also runs through the devcontainer post-start hook for future rebuilt environments. The first install builds the custom frontend on top of the pinned official Panel image.

Credentials are generated into ignored `.env`. Never commit it. Preserve the `APP_KEY`, database, and panel volumes. Mail uses the log driver; password-reset emails are not delivered until real SMTP is configured.

## Uptime limits

Default idle timeout is set in GitHub account settings, up to 240 minutes. GitHub enforces a 12-hour maximum Codespace session even during active use. No fake activity, polling to prevent shutdown, restart loops, or quota bypasses are included. Docker restart policies restart services while the host is available; they cannot keep a suspended Codespace alive.

A 16-core machine is not offered to the current account; the created Codespace uses the highest available option, 4 cores / 16 GB. Included compute is measured in core-hours. Always check GitHub billing before changing machine size.

## Game servers

This deployment includes the Panel and a native Wings v1.13.5 development node. Exactly one Paper 1.8.8 build 445 server is provisioned for 1.8.9 clients: 4 GB RAM, 300% CPU, 10 GB disk, Java 8. The installer refuses to delete unexpected existing servers.

The artifact is downloaded from PaperMC and must match SHA-256 7ff6d2cec671ef0d95b3723b5c92890118fb882d73b7f8fa0a2cd31d97c55f86 before first start. Minecraft EULA acceptance is required separately. Authentication stays enabled.

Codespaces browser URLs are web proxies. On the player's PC, use GitHub CLI to forward raw TCP:

```powershell
gh codespace ports forward 25565:25565 -c supreme-chainsaw-jrjww79rjg7925wwq
```

While that connection is running and the Codespace is active, join **127.0.0.1:25565** from that PC. This is not a public IP for friends. Use a persistent VPS for continuous hosting.

Panel-to-Wings requests use a node-specific internal address; browsers use the private forwarded HTTPS Wings address. The internal address override is limited to the configured node ID.

Administrator credentials use a reserved example.invalid address and are saved inside the panel volume at /app/var/admin-credentials.json. Do not commit or publish that file.

## Backups

`bash scripts/backup.sh` exports the database and encryption settings into ignored `backups/`. Copy them off the Codespace. This includes the local Wings node configuration and Minecraft files. Back up a running world after a save-all flush console command. Native Wings files survive stopping and starting this Codespace; rebuilds may replace the dev container filesystem, so keep an off-Codespace backup.

## Design

Graphite and moss, IBM Plex Sans, a responsive navigation rail, readable CPU/memory/storage readings, page filtering, explicit connection errors, staged entrances, button feedback, and reduced-motion support. Authentication and server management retain Pterodactyl APIs and authorization.

Design process informed by Unslop by [Damir Sokolovsky](https://x.com/heydamir), CC BY 4.0. Pterodactyl retains its upstream MIT license. The theme patch applies only to pinned v1.15.2.

## Artwork

The world illustration is saved in theme-assets/workbench-world.png, generated with the built-in image tool. Prompt: cinematic voxel pine forest, timber cottage, calm river, stepped grass cliffs and misty mountains; morning light; dark left-side negative space; no text, logos, or UI.
