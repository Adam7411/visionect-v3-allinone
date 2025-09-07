<!-- README_PL.md -->
<div align="right">
<a href="README.md">English</a> | <a href="README_pl.md">Polski</a>
</div>

# Visionect Server v3 (All‑in‑One) Home Assistant Add-on

All‑in‑one packaged Visionect Server v3 stack (Visionect upstream image + embedded PostgreSQL + Redis) for Home Assistant Supervisor.  
Tested with a Joan 6 e‑paper device.

> IMPORTANT: This add-on wraps the official `visionect/visionect-server-v3:7.6.5` Docker image. Usage is subject to Visionect’s original license/terms. This repository only adds orchestration glue (database + redis + HA integration). You are responsible for having the right to run the upstream software.

---

## Contents

- [Features](#features)
- [Architecture](#architecture)
- [Supported platforms](#supported-platforms)
- [Screens / Ports](#screens--ports)
- [Data persistence](#data-persistence)
- [Included components](#included-components)
- [Installation](#installation)
- [Configuration (options.json schema)](#configuration-optionsjson-schema)
- [Healthcheck](#healthcheck)
- [Logs](#logs)
- [Updating / Upgrading](#updating--upgrading)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)
- [Roadmap](#roadmap)
- [License / Disclaimer](#license--disclaimer)
- [Changelog](#changelog)

---

## Features

- Runs Visionect Server v3 side-by-side with:
  - Embedded PostgreSQL (cluster stored in `/data/pgdata`)
  - Embedded Redis (ephemeral / no persistence by default)
- Automatic first‑run initialization of DB user + database
- Optional auto-detection of host IP if `visionect_server_address` left at `localhost`
- Integrated lightweight HTTP health check watchdog
- Graceful shutdown handling (SIGTERM / SIGINT)
- Persistent logs (symlink `/var/log/vss` → `/data/logs`)
- Works on amd64, aarch64, armv7 (e.g. Raspberry Pi & x86_64)
- Tested with Joan 6 tablet

---

## Architecture

```
+--------------------------+
| Home Assistant Supervisor|
+------------+-------------+
             |
             v (Add-on)
   +-------------------------------+
   | Visionect All-in-One Container|
   |  - run.sh (bootstrap)         |
   |  - Redis (port 6379 internal) |
   |  - PostgreSQL (127.0.0.1:5432)|
   |  - Visionect processes via    |
   |    supervisord (admin/engine…)|
   +-------------------------------+
             |
     Exposed Ports (Host)
       8081 -> Visionect Management UI
       11113 -> Device communication (Joan)
```

All internal services communicate via loopback; only Visionect UI/device port is published.

---

## Supported Platforms

| Architecture | Status | Notes |
|--------------|--------|-------|
| amd64        | ✅     | Tested |
| aarch64      | ✅     | Raspberry Pi 4 / 5 |
| armv7        | ✅     | Raspberry Pi 3 (reduced performance) |

---

## Screens / Ports

| Purpose | Container Port | Host Mapping | Description |
|---------|----------------|--------------|-------------|
| Visionect Management UI | 8081 | 8081/tcp | Web interface |
| Device service / Koala  | 11113| 11113/tcp| Device communication (Joan, etc.) |

Update `config.yaml` / Supervisor UI if you need custom host ports.

---

## Data Persistence

| Path (Container) | Backed By | Description |
|------------------|----------|-------------|
| /data/pgdata     | Supervisor managed persistent volume | PostgreSQL cluster |
| /data/redis      | Persistent directory (not actively used for dump) | Redis dir (no RDB/AOF) |
| /data/logs       | Persistent | Visionect & add-on logs (symlink from `/var/log/vss`) |
| /data/options.json | Supervisor | Your runtime configuration |

Redis is configured without persistence by design (fast start, low wear).  
If you want persistence, adjust `redis-server` flags in `run.sh`.

---

## Included Components

| Component | Source |
|-----------|--------|
| Visionect Server v3 | `visionect/visionect-server-v3:7.6.5` |
| PostgreSQL 14       | Ubuntu packages |
| Redis 6             | Ubuntu packages |
| Supervisord         | From upstream Visionect image |
| Healthcheck (curl loop) | Custom shell logic |

---

## Installation

1. Add this custom repository URL to Home Assistant Add-on Store.
2. Locate “Visionect Server v3 (All-in-One)” in the store.
3. Click Install.
4. Open Configuration tab and set:
   - `postgres_password` (change default!)
   - Optionally `visionect_server_address` to your HA host IP (e.g. `192.168.1.50`).
5. Start the add-on.
6. Open Web UI (or navigate to `http://<HA_HOST>:8081`).
7. Pair your Joan 6 device.

---

## Configuration (options.json schema)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| postgres_user | string | visionect | Application DB user |
| postgres_password | string | visionect | CHANGE THIS IN PRODUCTION |
| postgres_db | string | koala | Application DB name |
| visionect_server_address | string | localhost | External address devices will use (auto-IP detection if left `localhost`) |
| timezone | string/null | auto | If set, will export TIMEZONE |
| bind_address | string | 0.0.0.0 | (Reserved – currently Visionect services bind internally) |
| healthcheck_enable | bool | true | Enable internal curl loop |
| healthcheck_url | string | http://127.0.0.1:8081 | URL polled for health |
| healthcheck_interval | int | 30 | Seconds between checks |
| healthcheck_max_failures | int | 5 | Consecutive failures before exit (Supervisor restarts) |

Example (raw options.json):
```json
{
  "postgres_user": "visionect",
  "postgres_password": "strongSecret123",
  "postgres_db": "koala",
  "visionect_server_address": "192.168.1.50",
  "timezone": "Europe/Warsaw",
  "healthcheck_enable": true,
  "healthcheck_url": "http://127.0.0.1:8081",
  "healthcheck_interval": 30,
  "healthcheck_max_failures": 5
}
```

---

## Healthcheck

A background loop runs `curl -fsS` against `healthcheck_url`.  
If `healthcheck_max_failures` is exceeded the add-on exits → Supervisor restarts it.

Set `healthcheck_enable: false` to disable.

---

## Logs

Persistent path: `/data/logs`

Key log files:
- `admin.log`
- `engine.log`
- `gateway.log`
- `networkmanager.log`

Supervisor Add-on UI consolidates stdout/stderr (includes bootstrap + supervisord events).

---

## Updating / Upgrading

1. Backup Home Assistant (recommended).
2. Update add-on via UI (new version bumps `version` in `config.yaml`).
3. PostgreSQL data preserved in `/data/pgdata`.
4. Review upstream Visionect release notes if the base image tag changes.

If upstream major version changes, test on a staging environment first.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Add-on restarts repeatedly | Healthcheck failing | Check UI availability, adjust `healthcheck_url` |
| DB init fails (`initdb: command not found`) | Missing server package | Reinstall / check Dockerfile integrity |
| UI not reachable on 8081 | Port conflict / firewall | Change host port mapping in advanced settings |
| Device can’t connect | Wrong `visionect_server_address` | Set to host LAN IP |
| Logs empty | Symlink not created | Remove `/var/log/vss`, restart add-on |

Quick diagnostics inside container:
```
ss -ltnp
tail -n 100 /data/logs/*.log
ps -ef | grep -i visionect
```

---

## Security Notes

- Change `postgres_password` immediately after first start.
- The embedded database is for convenience—consider an external managed PostgreSQL for production scale.
- Redis runs without auth and listens only inside the container (OK for this bundled use).
- No TLS termination is provided; place behind a reverse proxy if exposing remotely.
- Ensure your Home Assistant instance is not directly exposed to the public internet without proper protection.

---

## Roadmap

- Optional external PostgreSQL mode (skip embedded server)
- Redis persistence toggle (AOF option)
- Ingress support (HA reverse proxy)
- Automated backup export script
- Multi-device status panel

Contributions welcome—feel free to open Issues / PRs.

---

## Adding an Icon / Logo

Place `icon.png` (256×256) and optional `logo.png` in the add-on directory (same level as `config.yaml`), then:
1. Commit & push
2. Reload Add-on Store in HA
3. Bump `version` if cache persists

---

## License / Disclaimer

- Upstream Visionect Server: subject to Visionect’s original license (not included here).
- This repository: wrapper scripts & configuration under MIT (adjust if you choose another).
- No warranty. You assume all risk using proprietary upstream components.

(Replace this section with the actual license you choose for your glue code.)

---

## Changelog

See `CHANGELOG.md` (to be added) or Git history.

---

## Tested Hardware

- Joan 6 (e‑paper tablet) – successful registration & management UI verified.

---

## Contributing

1. Fork
2. Create feature branch
3. Commit changes
4. Open PR with clear description

Please include:
- Rationale
- Test notes
- Impact on existing data

---

## Support

Issues / questions: open a GitHub Issue in this repository.  
Please attach:
- Add-on version
- Relevant log excerpts
- Steps to reproduce

---


