# Space Engineers Dedicated Server — Docker (Wine + noVNC)

Run the **Windows** Space Engineers Dedicated Server on **Linux** with a browser-accessible GUI via noVNC.

## Quick Start

1. Create a `docker-compose.yml`:

```yaml
services:
  space-engineers:
    image: ghcr.io/mrdkge/docker-space-engineers:latest
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

On the **first start**, SteamCMD downloads the SE Dedicated Server (~3 GB). You can watch
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

Back up `data/` regularly — it contains your world saves.

## Stopping the Server

**Important:** Before stopping the container, save your world manually through the server
GUI or console. Then run:

```bash
docker compose down
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| noVNC page won't load | Wait ~30 s after starting — Wine takes time to initialize |
| Install stuck / failed | Run `docker compose logs -f` and check for errors; restart to retry |
| Server won't start | Connect via noVNC and check the error dialog on screen |
| GUI text is garbled | Rebuild with `docker compose build --no-cache` |

## Known Bugs

- **No graceful shutdown** — When the container stops (`docker compose down`), the SE
  server is forcefully killed and does not save automatically. Always save your world
  manually before stopping the container.

## Contributing

Contributions are welcome! Please open an issue or pull request.

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.

> **Disclaimer:** Space Engineers is a trademark of Keen Software House. This project is
> not affiliated with or endorsed by Keen Software House.
