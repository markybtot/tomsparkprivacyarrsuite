# Privacy Box (No-VPN, Plex edition)

**One-click media server setup for Windows, Mac, and Linux.**

A setup script that deploys a complete *arr stack (Sonarr, Radarr, Prowlarr, qBittorrent) with Plex as the media server, using Docker.

This is a modified version of [Tom Spark's Privacy Box](https://github.com/loponai/tomsparkprivacyarrsuite) with the Gluetun VPN container removed and Plex in place of Jellyfin. Every service runs directly on your normal internet connection. If you want torrent traffic to go through a VPN, run one at the router or host level, or use the original project.

> **Heads up:** without a VPN, your public IP address is visible to other peers in any torrent swarm qBittorrent joins.

---

## Download & Install

<details>
<summary><b>Windows (Docker Desktop) - Recommended for beginners</b></summary>

### Prerequisites
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. During installation, make sure **"Use WSL 2"** is checked
3. Start Docker Desktop and wait for the whale icon to turn green

### Install
**Option A - One-liner (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/markybtot/tomsparkprivacyarrsuite/main/install.ps1 | iex
```
Then double-click **`Setup-PrivacyBox.bat`** in the folder that opens.

**Option B - Manual:**
1. Download the repo as a ZIP and extract it to your Desktop
2. Double-click **`Setup-PrivacyBox.bat`**
3. Follow the prompts

</details>

<details>
<summary><b>macOS / Linux / WSL2</b></summary>

### Prerequisites
- **macOS:** install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and start it
- **Linux / WSL2:**
  ```bash
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
  ```
  Log out and back in (or run `newgrp docker`)

### Install
**Option A - One-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/markybtot/tomsparkprivacyarrsuite/main/install.sh | bash
```

**Option B - Manual:**
```bash
chmod +x setup.sh && ./setup.sh
```

</details>

---

## Features

- **One-click setup** - just your timezone and a Plex claim token
- **Cross-platform** - Windows, macOS, and Linux
- **Plex included** - stream your media to any device
- **Discord notifications** - optional Notifiarr integration
- **FlareSolverr support** - optional Cloudflare bypass for protected indexers
- **Usenet support** - optional SABnzbd
- **Music management** - optional Lidarr
- **Guided configuration** - step-by-step instructions for connecting all apps

## What Gets Installed

| Service | Open in browser | Address used inside other apps | Description |
|---------|-----------------|--------------------------------|-------------|
| qBittorrent | `localhost:8080` | `qbittorrent:8080` | Torrent client (torrent port 6881 TCP/UDP) |
| Prowlarr | `localhost:8181` | `http://prowlarr:9696` | Indexer manager |
| Sonarr | `localhost:8989` | `http://sonarr:8989` | TV show manager |
| Radarr | `localhost:7878` | `http://radarr:7878` | Movie manager |
| Plex | `localhost:32400/web` | `plex:32400` | Media server |
| SABnzbd | `localhost:8085` | `sabnzbd:8080` | Usenet client (optional) |
| Lidarr | `localhost:8686` | `http://lidarr:8686` | Music manager (optional) |
| Notifiarr | `localhost:5454` | - | Discord notifications (optional) |
| FlareSolverr | - | `http://flaresolverr:8191` | Cloudflare bypass proxy (optional) |

**Important:** the apps no longer share one network namespace, so when one app connects to another (e.g. adding qBittorrent as a download client in Sonarr, or adding Sonarr in Prowlarr's Apps), use the service name, not `localhost`. The setup wizard tells you the right values.

## Plex

The wizard asks for a **claim token** just before it starts the containers. It links the server to your Plex account, which first-time setup needs when Plex runs inside Docker. Tokens come from [plex.tv/claim](https://plex.tv/claim) and expire after 4 minutes.

Then open `http://localhost:32400/web`, sign in, and add libraries:

| Library | Folder |
|---------|--------|
| Movies | `/data/movies` |
| TV Shows | `/data/tvshows` |
| Music | `/data/music` |

**Auto-refresh Plex when downloads finish:** in Sonarr and Radarr, Settings > Connect > + > Plex Media Server, Host `plex`, Port `32400`, Authenticate with Plex.tv.

**Server not showing up?** The claim was skipped or expired. Get a fresh token, set `PLEX_CLAIM="claim-..."` in `.env`, and within 4 minutes run `docker compose up -d --force-recreate plex`.

**Devices on your home network can't find it?** In Plex, Settings > Network > Custom server access URLs, enter `http://YOUR-LAN-IP:32400`.

## Manual Commands

```bash
docker compose up -d                              # Start the stack
docker compose down                               # Stop the stack
docker compose ps                                 # Check container status
docker compose logs --tail 50 <service>           # Recent logs for a service

docker compose --profile notifications up -d      # Notifiarr (add NOTIFIARR_API_KEY to .env first)
docker compose --profile flaresolverr up -d       # FlareSolverr
docker compose --profile sabnzbd up -d            # SABnzbd
docker compose --profile lidarr up -d             # Lidarr
```

## Discord Notifications (Notifiarr)

1. Create a free account at [notifiarr.com](https://notifiarr.com) and copy your API key
2. Add it to `.env`: `NOTIFIARR_API_KEY=your-api-key-here`
3. Run `docker compose --profile notifications up -d`
4. Open `http://localhost:5454` (username `admin`, password is your API key)
5. Under **Starr Apps**, add Radarr (`http://radarr:7878`) and Sonarr (`http://sonarr:8989`) with their API keys from Settings > General
6. On notifiarr.com, go to **Integrations > Manage**, enable Radarr/Sonarr and pick your Discord channel

## Cloudflare Bypass (FlareSolverr)

1. Run `docker compose --profile flaresolverr up -d`
2. In Prowlarr (`http://localhost:8181`): **Settings > Indexers**, **+** under Indexer Proxies, **FlareSolverr**, Host `http://flaresolverr:8191`, **Test**, **Save**

## Usenet Downloads (SABnzbd)

1. Run `docker compose --profile sabnzbd up -d`
2. Open `http://localhost:8085` and follow the Quick-Start Wizard with your Usenet provider details
3. In Sonarr/Radarr/Lidarr: Settings > Download Clients > + > SABnzbd, Host `sabnzbd`, Port `8080`, API key from SABnzbd > Config > General

## Music Management (Lidarr)

1. Run `docker compose --profile lidarr up -d`
2. Open `http://localhost:8686` and create your admin account
3. Root folder: `/data/media/music`
4. Download client: qBittorrent, Host `qbittorrent`, Port `8080`
5. In Prowlarr: Settings > Apps > + > Lidarr, Prowlarr Server `http://prowlarr:9696`, Lidarr Server `http://lidarr:8686`
6. In Plex add a Music library at `/data/music`

## Troubleshooting

### "Connection refused" when testing a connection between apps
You've probably used `localhost`. Inside the apps, use the service name (`qbittorrent`, `sonarr`, `radarr`, `prowlarr`, `lidarr`, `sabnzbd`, `flaresolverr`).

### Upgrading from the original VPN version
Run `docker compose down --remove-orphans` first so the old `gluetun` and `jellyfin` containers are removed. Your app configs in `./config` carry over, but update any `localhost` connections inside the apps to service names as above.

### Port Already in Use
- **Windows:** Hyper-V reserves random ports in the 9000-9999 range, which is why Prowlarr uses 8181
- Check a port: `netstat -an | grep 8080` (Mac/Linux) or `netstat -an | findstr 8080` (Windows)

### Prowlarr Shows Few Indexers
Change the Language filter from "en-US" to "Any".

### qBittorrent Password
qBittorrent generates a random password on first run:
```bash
docker logs qbittorrent 2>&1 | grep password       # Mac/Linux
docker logs qbittorrent 2>&1 | findstr password    # Windows
```
Username is `admin`. Change the password after logging in.

### Slow or few torrent peers
Forward TCP/UDP port `6881` on your router to the machine running the stack.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                        INTERNET                          │
└───────────────────────────┬──────────────────────────────┘
                            │
┌───────────────────────────┴──────────────────────────────┐
│                 Docker network: "arr"                    │
│ ┌───────────┐ ┌──────────┐ ┌────────┐ ┌────────┐         │
│ │qBittorrent│ │ Prowlarr │ │ Sonarr │ │ Radarr │         │
│ │   :8080   │ │  :8181   │ │ :8989  │ │ :7878  │         │
│ └───────────┘ └──────────┘ └────────┘ └────────┘         │
│ ┌───────────┐ ┌──────────┐ ┌────────┐ ┌──────────────┐   │
│ │   Plex    │ │ Lidarr*  │ │SABnzbd*│ │FlareSolverr* │   │
│ │  :32400   │ │  :8686   │ │ :8085  │ │  (internal)  │   │
│ └───────────┘ └──────────┘ └────────┘ └──────────────┘   │
└──────────────────────────────────────────────────────────┘
                                                * = optional
```

## Remote Access

**Plex Remote Access (built in):** Plex > Settings > Remote Access > Enable, and forward port `32400` on your router to this machine. Easiest option, but it opens a port to the internet.

**Tailscale (no port forwarding):** [Tailscale](https://tailscale.com/) creates a private, encrypted network between your devices.

```bash
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up
```

Then reach your apps on the machine's Tailscale IP, e.g. Plex at `http://[tailscale-ip]:32400/web`.

## License

**MIT License with Attribution Requirement**

Original work created by Tom Spark - youtube.com/@TomSparkReviews. This modified version keeps that attribution as required. See [LICENSE](LICENSE) for full terms.

Tom Spark's maintained, full version of this project is **[SparkBox](https://tomsparkbox.com)**. Support for the original is on the **[Tom Spark Discord](https://discord.gg/uPdRcKxEVS)**.

## Credits

- Tom Spark - original Privacy Box scripts and tutorial
- [LinuxServer.io](https://www.linuxserver.io/) - Docker images
- [Plex](https://www.plex.tv/) - Media server
- [Notifiarr](https://notifiarr.com) - Discord notifications
- [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) - Cloudflare bypass proxy
- [SABnzbd](https://sabnzbd.org/) - Usenet download client
- [Lidarr](https://lidarr.audio/) - Music manager

---

**Disclaimer:** This tool is for legal purposes only. Respect copyright laws in your jurisdiction.
