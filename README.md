# Space Engineers Dedicated Server — Docker (Wine + noVNC)

[![GitHub](https://img.shields.io/badge/GitHub-Repository-181717?logo=github)](https://github.com/MrDKGE/Docker-Space-Engineers)
[![Docker Image Version](https://img.shields.io/docker/v/dkge/space-engineers?logo=docker&label=Docker%20Hub)](https://hub.docker.com/r/dkge/space-engineers)
[![Docker Pulls](https://img.shields.io/docker/pulls/dkge/space-engineers?logo=docker&label=Pulls)](https://hub.docker.com/r/dkge/space-engineers)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://github.com/MrDKGE/Docker-Space-Engineers/blob/main/LICENSE)

Run the **Windows** Space Engineers Dedicated Server on **Linux** with a browser-accessible GUI via noVNC.

## Quick Start

1. Create a `docker-compose.yml`:

```yaml
services:
  space-engineers:
    image: dkge/space-engineers:latest
    container_name: space-engineers
    ports:
      - "6080:6080"
      - "27016:27016/udp"
    environment:
      - GUI=true
    volumes:
      - ./data/server:/opt/spaceengineers
      - ./data/instance:/opt/se-instance
    restart: unless-stopped
```

2. Start it:

```bash
docker compose up -d
```

3. Open **http://\<your-host-ip\>:6080** in a browser to access the server GUI.

On the **first start**, SteamCMD downloads the SE Dedicated Server (~7 GB). You can watch
the progress through the noVNC web UI. Subsequent starts skip this step.

### Building from source

If you prefer to build the image yourself:

```bash
git clone https://github.com/MrDKGE/Docker-Space-Engineers.git
cd Docker-Space-Engineers
docker compose up -d --build
```

## Configuration

Edit `docker-compose.yml` to change these:

| Variable | Default | Description |
|----------|---------|-------------|
| `GUI` | `true` | `true` = server GUI via noVNC · `false` = headless console mode |
| `RESOLUTION` | `1280x720x24` | Virtual display resolution |

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| **6080** | TCP | noVNC web UI — open this in your browser |
| **27016** | UDP | Game server — give this to players |
| 5900 | TCP | Raw VNC (commented out by default) |

### Volumes

| Host Path | Container Path | Contents |
|-----------|---------------|----------|
| `./data/server` | `/opt/spaceengineers` | Game installation |
| `./data/instance` | `/opt/se-instance` | World saves, mods, server config |

Back up `data/instance` regularly, it contains your world saves.

## Stopping the Server

**Important:** Before stopping the container, save your world manually through the server
GUI or console. Then run:

```bash
docker compose down
```

## Known Bugs

- **No graceful shutdown** — When the container stops (`docker compose down`), the SE
  server is forcefully killed and does not save automatically. Always save your world
  manually before stopping the container.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](https://github.com/MrDKGE/Docker-Space-Engineers/blob/main/LICENSE) for details.

> **Disclaimer:** Space Engineers is a trademark of Keen Software House. This project is
> not affiliated with or endorsed by Keen Software House.
