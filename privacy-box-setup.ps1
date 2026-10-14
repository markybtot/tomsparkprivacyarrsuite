# ============================================================
# PRIVACY BOX - One-Click Media Server Setup
# Created by Tom Spark | https://youtube.com/@TomSparkReviews
#
# LICENSE: MIT with Attribution - You MUST credit Tom Spark
#          if you share, modify, or create content based on this.
#
# Original: https://github.com/loponai/tomsparkprivacyarrsuite (No-VPN edition)
# ============================================================

param(
    [switch]$SkipDockerCheck,
    [string]$InstallPath = "$env:USERPROFILE\Desktop\PrivacyServer"
)

# --- Configuration ---
$script:Version = "1.0.0"
$script:BeginnerMode = $false
$script:DefaultPorts = @{
    qBittorrent = 8080
    Prowlarr    = 8181  # Safe port (avoids Hyper-V conflicts)
    Sonarr      = 8989
    Radarr      = 7878
}

# --- Helper Functions ---
function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "       PRIVACY BOX - Secure Media Server Setup" -ForegroundColor White
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "         Created by " -ForegroundColor DarkGray -NoNewline
    Write-Host "TOM SPARK" -ForegroundColor Yellow -NoNewline
    Write-Host " | v$script:Version" -ForegroundColor DarkGray
    Write-Host "      YouTube: youtube.com/@TomSparkReviews" -ForegroundColor DarkGray
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "   (c) 2026 Tom Spark. Licensed under MIT+Attribution." -ForegroundColor DarkGray
    Write-Host "   Unauthorized copying without credit = DMCA takedown." -ForegroundColor DarkRed
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Number, [string]$Text)
    Write-Host "  [$Number] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "  [X] " -ForegroundColor Red -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [i] " -ForegroundColor Cyan -NoNewline
    Write-Host $Text -ForegroundColor Gray
}

function Write-Warning-Custom {
    param([string]$Text)
    Write-Host "  [!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Press-Enter {
    Write-Host ""
    Write-Host "  Press ENTER to continue..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Ask-YesNo {
    param([string]$Question)
    Write-Host ""
    Write-Host "  $Question (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    return $response -match "^[Yy]"
}

# --- Beginner Mode ---
function Show-BeginnerTip {
    param(
        [string]$Title,
        [string]$Body
    )

    if (-not $script:BeginnerMode) {
        return
    }

    Write-Host ""
    Write-Host "  +----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |  " -ForegroundColor Cyan -NoNewline
    Write-Host "[TIP] $Title" -ForegroundColor White
    Write-Host "  +----------------------------------------------------+" -ForegroundColor Cyan
    $Body -split "`n" | ForEach-Object {
        Write-Host "  |  " -ForegroundColor Cyan -NoNewline
        Write-Host $_.Trim() -ForegroundColor Gray
    }
    Write-Host "  +----------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Press ENTER to continue..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Get-ExperienceLevel {
    Write-Banner
    Write-Host "  EXPERIENCE LEVEL" -ForegroundColor Magenta
    Write-Host "  ----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  How familiar are you with the ARR suite?" -ForegroundColor White
    Write-Host ""
    Write-Host "    1. I'm brand new to ARR" -ForegroundColor Green -NoNewline
    Write-Host "  (show me extra explanations)" -ForegroundColor Gray
    Write-Host "    2. I'm familiar with ARR" -ForegroundColor Cyan -NoNewline
    Write-Host " (skip the intro tips)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Select (1-2) [default: 1]: " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host

    switch ($choice) {
        "2" {
            $script:BeginnerMode = $false
            Write-Success "Experienced mode — skipping beginner tips."
        }
        default {
            $script:BeginnerMode = $true
            Write-Success "Beginner mode — extra tips will be shown throughout setup."
        }
    }
}

function Show-ArrOverview {
    if (-not $script:BeginnerMode) {
        return
    }

    Write-Banner
    Write-Host "  WHAT IS THE ARR SUITE?" -ForegroundColor Magenta
    Write-Host "  ----------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  The ARR suite is a collection of apps that work together" -ForegroundColor White
    Write-Host "  to automatically find, download, and organize media:" -ForegroundColor White
    Write-Host ""
    Write-Host "  +---------------+--------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Service" -ForegroundColor Yellow -NoNewline
    Write-Host "       | " -ForegroundColor Cyan -NoNewline
    Write-Host "What it does" -ForegroundColor White -NoNewline
    Write-Host "                              |" -ForegroundColor Cyan
    Write-Host "  +---------------+--------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "qBittorrent" -ForegroundColor Green -NoNewline
    Write-Host "   | " -ForegroundColor Cyan -NoNewline
    Write-Host "Downloads torrent files" -ForegroundColor Gray -NoNewline
    Write-Host "                   |" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Prowlarr" -ForegroundColor Green -NoNewline
    Write-Host "      | " -ForegroundColor Cyan -NoNewline
    Write-Host "Searches torrent sites for content" -ForegroundColor Gray -NoNewline
    Write-Host "       |" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Sonarr" -ForegroundColor Green -NoNewline
    Write-Host "        | " -ForegroundColor Cyan -NoNewline
    Write-Host "Finds & organizes TV shows automatically" -ForegroundColor Gray -NoNewline
    Write-Host " |" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Radarr" -ForegroundColor Green -NoNewline
    Write-Host "        | " -ForegroundColor Cyan -NoNewline
    Write-Host "Finds & organizes movies automatically" -ForegroundColor Gray -NoNewline
    Write-Host "   |" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Plex" -ForegroundColor Green -NoNewline
    Write-Host "          | " -ForegroundColor Cyan -NoNewline
    Write-Host "Streams your media (like personal Netflix)" -ForegroundColor Gray -NoNewline
    Write-Host "|" -ForegroundColor Cyan
    Write-Host "  +---------------+--------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Optional:" -ForegroundColor Yellow -NoNewline
    Write-Host "      | " -ForegroundColor Cyan -NoNewline
    Write-Host "                                            " -ForegroundColor Gray -NoNewline
    Write-Host "|" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "SABnzbd" -ForegroundColor Green -NoNewline
    Write-Host "       | " -ForegroundColor Cyan -NoNewline
    Write-Host "Downloads from Usenet (alternative to torrents)" -ForegroundColor Gray -NoNewline
    Write-Host "|" -ForegroundColor Cyan
    Write-Host "  | " -ForegroundColor Cyan -NoNewline
    Write-Host "Lidarr" -ForegroundColor Green -NoNewline
    Write-Host "        | " -ForegroundColor Cyan -NoNewline
    Write-Host "Finds & organizes music automatically" -ForegroundColor Gray -NoNewline
    Write-Host "   |" -ForegroundColor Cyan
    Write-Host "  +---------------+--------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  How they connect:" -ForegroundColor White
    Write-Host ""
    Write-Host "  You search in " -ForegroundColor Gray -NoNewline
    Write-Host "Sonarr/Radarr" -ForegroundColor Green -NoNewline
    Write-Host " -> " -ForegroundColor Gray -NoNewline
    Write-Host "Prowlarr" -ForegroundColor Green -NoNewline
    Write-Host " finds it -> " -ForegroundColor Gray -NoNewline
    Write-Host "qBittorrent" -ForegroundColor Green -NoNewline
    Write-Host " downloads it" -ForegroundColor Gray
    Write-Host "  -> " -ForegroundColor Gray -NoNewline
    Write-Host "Sonarr/Radarr" -ForegroundColor Green -NoNewline
    Write-Host " organizes it -> " -ForegroundColor Gray -NoNewline
    Write-Host "Plex" -ForegroundColor Green -NoNewline
    Write-Host " streams it to your devices" -ForegroundColor Gray

    Press-Enter
}

# --- Pre-Flight Checks ---
function Test-DockerInstalled {
    Write-Step "1" "Checking if Docker Desktop is installed..."

    $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerPath) {
        Write-Error-Custom "Docker is NOT installed!"
        Write-Host ""
        Write-Host "  Please install Docker Desktop first:" -ForegroundColor White
        Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
        Write-Host ""
        Write-Warning-Custom "During installation, make sure 'Use WSL 2' is CHECKED!"
        return $false
    }
    Write-Success "Docker is installed"
    return $true
}

function Test-DockerRunning {
    Write-Step "2" "Checking if Docker is running..."

    try {
        $result = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Docker not running"
        }
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error-Custom "Docker is NOT running!"
        Write-Host ""
        Write-Host "  Please start Docker Desktop and wait for the whale icon" -ForegroundColor White
        Write-Host "  in the system tray to turn GREEN before continuing." -ForegroundColor White
        return $false
    }
}

function Get-Timezone {
    Write-Banner
    Write-Host "  STEP 1: TIMEZONE" -ForegroundColor Magenta
    Write-Host "  ----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Common timezones:" -ForegroundColor White
    Write-Host "    1. America/Los_Angeles (Pacific)" -ForegroundColor Gray
    Write-Host "    2. America/Denver (Mountain)" -ForegroundColor Gray
    Write-Host "    3. America/Chicago (Central)" -ForegroundColor Gray
    Write-Host "    4. America/New_York (Eastern)" -ForegroundColor Gray
    Write-Host "    5. Europe/London" -ForegroundColor Gray
    Write-Host "    6. Europe/Berlin" -ForegroundColor Gray
    Write-Host "    7. Custom" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Select (1-7) [default: 1]: " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host

    switch ($choice) {
        "2" { return "America/Denver" }
        "3" { return "America/Chicago" }
        "4" { return "America/New_York" }
        "5" { return "Europe/London" }
        "6" { return "Europe/Berlin" }
        "7" {
            Write-Host "  Enter timezone (e.g., Australia/Sydney): " -ForegroundColor Yellow -NoNewline
            return Read-Host
        }
        default { return "America/Los_Angeles" }
    }
}

# --- File Generation ---
function New-EnvFile {
    param(
        [string]$Path,
        [string]$Timezone
    )

    $content = @"
# ==========================================
# TOM SPARK'S PRIVACY BOX CONFIG
# Created by Tom Spark | youtube.com/@TomSparkReviews
# ==========================================

# --- SYSTEM SETTINGS ---
TZ=$Timezone
ROOT_DIR=.

# --- PLEX ---
# Plex claim token from https://plex.tv/claim (only used on first start)
PLEX_CLAIM=
"@

    $content | Out-File -FilePath "$Path\.env" -Encoding UTF8 -NoNewline
}

function New-DockerComposeFile {
    param([string]$Path)

    $content = @'
# ==========================================
# TOM SPARK'S PRIVACY BOX (No-VPN edition)
# Created by Tom Spark | youtube.com/@TomSparkReviews
# Modified to remove the Gluetun VPN container.
#
# All services share the "arr" bridge network, so containers reach
# each other by service name (e.g. http://qbittorrent:8080,
# http://sonarr:8989). From your browser, use http://localhost:<port>.
# ==========================================

networks:
  arr:
    driver: bridge

services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - WEBUI_PORT=8080
      - TORRENTING_PORT=6881
    ports:
      - 8080:8080         # qBittorrent Web UI
      - 6881:6881         # Torrent traffic (TCP)
      - 6881:6881/udp     # Torrent traffic (UDP)
    volumes:
      - ./config/qbittorrent:/config
      - ./media/downloads:/data/downloads
    networks:
      - arr
    healthcheck:
      test: ["CMD-SHELL", "curl -fs http://localhost:8080 || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    ports:
      - 8181:9696         # Prowlarr (Safe Port - avoids Windows conflicts)
    volumes:
      - ./config/prowlarr:/config
    networks:
      - arr
    healthcheck:
      test: ["CMD-SHELL", "curl -fs http://localhost:9696/ping || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    ports:
      - 8989:8989         # Sonarr
    volumes:
      - ./config/sonarr:/config
      - ./media:/data/media
      - ./media/downloads:/data/downloads
    networks:
      - arr
    healthcheck:
      test: ["CMD-SHELL", "curl -fs http://localhost:8989/ping || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    ports:
      - 7878:7878         # Radarr
    volumes:
      - ./config/radarr:/config
      - ./media:/data/media
      - ./media/downloads:/data/downloads
    networks:
      - arr
    healthcheck:
      test: ["CMD-SHELL", "curl -fs http://localhost:7878/ping || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped

  # --- Media Server: Plex (accessible on local network) ---
  # PLEX_CLAIM links the server to your Plex account on first start.
  # Get a token at https://plex.tv/claim (it expires after 4 minutes).
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - VERSION=docker
      - PLEX_CLAIM=${PLEX_CLAIM:-}
    ports:
      - 32400:32400       # Plex Web UI and streaming
    volumes:
      - ./config/plex:/config
      - ./media/tv:/data/tvshows
      - ./media/movies:/data/movies
      - ./media/music:/data/music
    networks:
      - arr
    healthcheck:
      test: ["CMD-SHELL", "curl -fs http://localhost:32400/identity || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped

  # --- SABnzbd (Optional - enable with: docker compose --profile sabnzbd up -d) ---
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    profiles:
      - sabnzbd
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    ports:
      - 8085:8080         # SABnzbd Web UI
    volumes:
      - ./config/sabnzbd:/config
      - ./media/downloads:/data/downloads
    networks:
      - arr
    restart: unless-stopped

  # --- Lidarr (Optional - enable with: docker compose --profile lidarr up -d) ---
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    container_name: lidarr
    profiles:
      - lidarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    ports:
      - 8686:8686         # Lidarr
    volumes:
      - ./config/lidarr:/config
      - ./media:/data/media
      - ./media/downloads:/data/downloads
    networks:
      - arr
    healthcheck:
      test: ["CMD-SHELL", "curl -fs http://localhost:8686/ping || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped

  # --- Notifications (Optional - enable with: docker compose --profile notifications up -d) ---
  notifiarr:
    image: golift/notifiarr
    container_name: notifiarr
    hostname: notifiarr
    profiles:
      - notifications
    environment:
      - DN_API_KEY=${NOTIFIARR_API_KEY:-}
      - TZ=${TZ}
    ports:
      - 5454:5454         # Notifiarr Web UI
    volumes:
      - ./config/notifiarr:/config
      - /var/run/utmp:/var/run/utmp:ro
    networks:
      - arr
    restart: unless-stopped

  # --- FlareSolverr (Optional - enable with: docker compose --profile flaresolverr up -d) ---
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    profiles:
      - flaresolverr
    environment:
      - LOG_LEVEL=info
      - TZ=${TZ}
    # No host ports needed. Prowlarr reaches it at http://flaresolverr:8191
    networks:
      - arr
    restart: unless-stopped
'@

    $content | Out-File -FilePath "$Path\docker-compose.yml" -Encoding UTF8 -NoNewline
}

# --- Plex Claim Token ---
function Set-PlexClaim {
    param(
        [string]$Path,
        [string]$Token
    )

    $envPath = Join-Path $Path ".env"
    if (-not (Test-Path $envPath)) {
        return
    }

    # Keep the file's existing encoding (with or without BOM)
    $bytes = [System.IO.File]::ReadAllBytes($envPath)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $encoding = New-Object System.Text.UTF8Encoding($hasBom)
    $text = [System.IO.File]::ReadAllText($envPath, $encoding)

    $line = "PLEX_CLAIM=`"$Token`""
    if ($text -match '(?m)^PLEX_CLAIM=.*$') {
        $text = [regex]::Replace($text, '(?m)^PLEX_CLAIM=[^\r\n]*', { param($m) $line })
    } else {
        $text = $text.TrimEnd("`r", "`n") + "`n" + $line + "`n"
    }

    [System.IO.File]::WriteAllText($envPath, $text, $encoding)
}

function Get-PlexClaim {
    param([string]$Path)

    Write-Banner
    Write-Host "  LINK PLEX TO YOUR PLEX ACCOUNT" -ForegroundColor Magenta
    Write-Host "  ------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  A claim token links this Plex server to your Plex account." -ForegroundColor White
    Write-Host "  It is needed for first-time setup to work reliably in Docker." -ForegroundColor White
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " IMPORTANT " -BackgroundColor DarkRed -ForegroundColor White
    Write-Host "  The token expires 4 minutes after you generate it, so get it now." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  How to get it:" -ForegroundColor White
    Write-Host "    1. Go to: " -ForegroundColor Gray -NoNewline
    Write-Host "https://plex.tv/claim" -ForegroundColor Cyan
    Write-Host "    2. Sign in, or create a free Plex account" -ForegroundColor Gray
    Write-Host "    3. Copy the token shown (it starts with " -ForegroundColor Gray -NoNewline
    Write-Host "claim-" -ForegroundColor Cyan -NoNewline
    Write-Host ")" -ForegroundColor Gray
    Write-Host ""

    if (Ask-YesNo "Open https://plex.tv/claim in your browser now?") {
        Start-Process "https://plex.tv/claim"
        Write-Host ""
        Write-Info "Browser opened. Copy the claim token, then come back here."
    }

    Write-Host ""
    Write-Host "  Paste your Plex claim token (or press ENTER to skip): " -ForegroundColor Yellow -NoNewline
    $token = Read-Host
    if ($null -eq $token) { $token = "" }
    $token = ($token -replace '[\s"]', '')

    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-Host ""
        Write-Info "Skipped. You can link Plex later (see the Plex setup guide)."
        return
    }

    if (-not $token.StartsWith("claim-")) {
        Write-Warning-Custom "That doesn't look like a claim token (should start with 'claim-'). Using it anyway."
    }

    Set-PlexClaim -Path $Path -Token $token
    Write-Success "Plex claim token saved to .env"
}

# --- Docker Operations ---
function Start-PrivacyBox {
    param([string]$Path)

    Write-Banner
    Write-Host "  LAUNCHING PRIVACY BOX" -ForegroundColor Magenta
    Write-Host "  ---------------------" -ForegroundColor DarkGray
    Write-Host ""

    Push-Location $Path

    Write-Step "1" "Pulling Docker images (this may take a few minutes on first run)..."
    Write-Host ""

    docker compose pull 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

    Get-PlexClaim -Path $Path

    Write-Host ""
    Write-Step "2" "Starting containers..."
    Write-Host ""

    docker compose up -d 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }

    Write-Host ""
    Write-Step "3" "Waiting for containers to start..."

    $coreContainers = @("qbittorrent", "prowlarr", "sonarr", "radarr", "plex")
    $maxAttempts = 30
    $attempt = 0
    $allRunning = $false

    while ($attempt -lt $maxAttempts -and -not $allRunning) {
        Start-Sleep -Seconds 2
        $attempt++

        $allRunning = $true
        foreach ($name in $coreContainers) {
            $status = docker inspect --format '{{.State.Status}}' $name 2>$null
            if ($status -ne "running") {
                $allRunning = $false
                break
            }
        }

        Write-Host "." -NoNewline -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host ""

    if ($allRunning) {
        Write-Success "All core containers are running!"
        foreach ($name in $coreContainers) {
            # Health is informational only; containers may still be starting up
            $health = docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' $name 2>$null
            if ($health -eq "healthy") {
                Write-Host "      $name" -ForegroundColor Gray -NoNewline
                Write-Host " (healthy)" -ForegroundColor Green
            } elseif ($health) {
                Write-Host "      $name" -ForegroundColor Gray -NoNewline
                Write-Host " ($health, still warming up is normal)" -ForegroundColor DarkGray
            } else {
                Write-Host "      $name" -ForegroundColor Gray -NoNewline
                Write-Host " (running)" -ForegroundColor Green
            }
        }
        Pop-Location
        return $true
    } else {
        Write-Error-Custom "Some containers did not start in time. Current status:"
        Write-Host ""
        docker compose ps 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        Pop-Location
        return $false
    }
}

# --- Guided Setup ---
function Show-SetupGuide {
    # --- qBittorrent Setup ---
    Show-BeginnerTip -Title "What is qBittorrent?" -Body "qBittorrent is a download client for torrents. Think
of it like a download manager. Sonarr, Radarr and Lidarr
send it the files to download."
    Write-Banner
    Write-Host "  SETUP GUIDE: qBittorrent (Step 1 of 4)" -ForegroundColor Magenta
    Write-Host "  --------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open qBittorrent in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8080"
    Write-Host ""
    Write-Host "  Login:" -ForegroundColor Yellow
    Write-Host "    Username: " -ForegroundColor White -NoNewline
    Write-Host "admin" -ForegroundColor Cyan
    Write-Host "    Password: " -ForegroundColor White -NoNewline
    Write-Host "(check the command below)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " IMPORTANT " -BackgroundColor DarkRed -ForegroundColor White
    Write-Host "  qBittorrent generates a random password on first run." -ForegroundColor White
    Write-Host ""
    Write-Host "  To find your password:" -ForegroundColor Yellow
    Write-Host "    1. Press " -ForegroundColor White -NoNewline
    Write-Host "Windows + R" -ForegroundColor Cyan -NoNewline
    Write-Host ", type " -ForegroundColor White -NoNewline
    Write-Host "cmd" -ForegroundColor Cyan -NoNewline
    Write-Host ", press Enter" -ForegroundColor White
    Write-Host "    2. In the black window, paste this command:" -ForegroundColor White
    Write-Host ""
    Write-Host "       docker logs qbittorrent 2>&1 | findstr password" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    3. Press Enter - your password will appear" -ForegroundColor White
    Write-Host "    4. Copy the password and use it to log in above" -ForegroundColor White
    Write-Host ""
    Write-Host "  After logging in, change your password:" -ForegroundColor Yellow
    Write-Host "    Tools > Options > Web UI > Password" -ForegroundColor Gray

    Press-Enter

    # --- Prowlarr Setup ---
    Show-BeginnerTip -Title "What is Prowlarr?" -Body "Prowlarr is a search engine that looks across many
torrent sites at once. It connects to Sonarr and Radarr
so they can automatically find the content you want."
    Write-Banner
    Write-Host "  SETUP GUIDE: Prowlarr (Step 2 of 4)" -ForegroundColor Magenta
    Write-Host "  -----------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open Prowlarr in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8181"
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " IMPORTANT " -BackgroundColor DarkRed -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Create your admin account when prompted" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Add Indexers:" -ForegroundColor Yellow
    Write-Host "     - Click 'Indexers' in the sidebar" -ForegroundColor White
    Write-Host "     - Click '+ Add Indexer'" -ForegroundColor White
    Write-Host "     - " -ForegroundColor White -NoNewline
    Write-Host "CRITICAL: Change 'Language' filter from 'en-US' to 'Any'" -ForegroundColor Red
    Write-Host "       (Otherwise you'll only see ~6 indexers instead of 400+)" -ForegroundColor Gray
    Write-Host "     - Add: 1337x, TorrentGalaxy, or your preferred sites" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. We'll connect Prowlarr to Sonarr/Radarr in the next steps" -ForegroundColor Gray

    Press-Enter

    # --- Sonarr Setup ---
    Show-BeginnerTip -Title "What is Sonarr?" -Body "Sonarr automates TV show management. Tell it what shows
you want, and it will find episodes, download them via
qBittorrent, and organize them into neat folders."
    Write-Banner
    Write-Host "  SETUP GUIDE: Sonarr (Step 3 of 4)" -ForegroundColor Magenta
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open Sonarr in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8989"
    Write-Host ""
    Write-Host "  1. Create your admin account when prompted" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Add Root Folder (where TV shows are saved):" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Media Management" -ForegroundColor White
    Write-Host "     - Scroll down and click 'Add Root Folder'" -ForegroundColor White
    Write-Host "     - Enter path: " -ForegroundColor White -NoNewline
    Write-Host "/data/media/tv" -ForegroundColor Cyan
    Write-Host "     - Click 'OK'" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Add Download Client:" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Download Clients" -ForegroundColor White
    Write-Host "     - Click '+' and select 'qBittorrent'" -ForegroundColor White
    Write-Host "     - Host: " -ForegroundColor White -NoNewline
    Write-Host "qbittorrent" -ForegroundColor Cyan
    Write-Host "     - Port: " -ForegroundColor White -NoNewline
    Write-Host "8080" -ForegroundColor Cyan
    Write-Host "     - Username: " -ForegroundColor White -NoNewline
    Write-Host "admin" -ForegroundColor Cyan
    Write-Host "     - Password: " -ForegroundColor White -NoNewline
    Write-Host "(your qBittorrent password)" -ForegroundColor Cyan
    Write-Host "     - Click 'Test' then 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "  4. Copy your API Key:" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > General" -ForegroundColor White
    Write-Host "     - Copy the 'API Key' (you'll need this for Prowlarr)" -ForegroundColor White

    Press-Enter

    # --- Radarr Setup ---
    Show-BeginnerTip -Title "What is Radarr?" -Body "Radarr is just like Sonarr, but for movies. Tell it what
movies you want, and it will find, download, and organize
them automatically."
    Write-Banner
    Write-Host "  SETUP GUIDE: Radarr (Step 4 of 4)" -ForegroundColor Magenta
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open Radarr in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:7878"
    Write-Host ""
    Write-Host "  1. Create your admin account when prompted" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Add Root Folder (where movies are saved):" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Media Management" -ForegroundColor White
    Write-Host "     - Scroll down and click 'Add Root Folder'" -ForegroundColor White
    Write-Host "     - Enter path: " -ForegroundColor White -NoNewline
    Write-Host "/data/media/movies" -ForegroundColor Cyan
    Write-Host "     - Click 'OK'" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Add Download Client (same as Sonarr):" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Download Clients" -ForegroundColor White
    Write-Host "     - Click '+' and select 'qBittorrent'" -ForegroundColor White
    Write-Host "     - Host: " -ForegroundColor White -NoNewline
    Write-Host "qbittorrent" -ForegroundColor Cyan
    Write-Host "     - Port: " -ForegroundColor White -NoNewline
    Write-Host "8080" -ForegroundColor Cyan
    Write-Host "     - Username/Password: same as before" -ForegroundColor White
    Write-Host "     - Click 'Test' then 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "  4. Copy your API Key:" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > General" -ForegroundColor White
    Write-Host "     - Copy the 'API Key' (you'll need this for Prowlarr)" -ForegroundColor White

    Press-Enter

    # --- Connect Prowlarr ---
    Write-Banner
    Write-Host "  FINAL STEP: Connect Prowlarr to Apps" -ForegroundColor Magenta
    Write-Host "  ------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open Prowlarr in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8181"
    Write-Host ""
    Write-Host "  Go to: Settings > Apps" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Add Sonarr:" -ForegroundColor White
    Write-Host "    - Click '+' and select 'Sonarr'" -ForegroundColor Gray
    Write-Host "    - Prowlarr Server: " -ForegroundColor Gray -NoNewline
    Write-Host "http://prowlarr:9696" -ForegroundColor Cyan
    Write-Host "    - Sonarr Server: " -ForegroundColor Gray -NoNewline
    Write-Host "http://sonarr:8989" -ForegroundColor Cyan
    Write-Host "    - API Key: " -ForegroundColor Gray -NoNewline
    Write-Host "(paste the Sonarr API key you copied)" -ForegroundColor Cyan
    Write-Host "    - Click 'Test' then 'Save'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Add Radarr:" -ForegroundColor White
    Write-Host "    - Click '+' and select 'Radarr'" -ForegroundColor Gray
    Write-Host "    - Prowlarr Server: " -ForegroundColor Gray -NoNewline
    Write-Host "http://prowlarr:9696" -ForegroundColor Cyan
    Write-Host "    - Radarr Server: " -ForegroundColor Gray -NoNewline
    Write-Host "http://radarr:7878" -ForegroundColor Cyan
    Write-Host "    - API Key: " -ForegroundColor Gray -NoNewline
    Write-Host "(paste the Radarr API key you copied)" -ForegroundColor Cyan
    Write-Host "    - Click 'Test' then 'Save'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  If you enabled Lidarr, add it too:" -ForegroundColor Gray
    Write-Host "    - Click '+' and select 'Lidarr'" -ForegroundColor Gray
    Write-Host "    - Prowlarr Server: " -ForegroundColor Gray -NoNewline
    Write-Host "http://prowlarr:9696" -ForegroundColor Cyan
    Write-Host "    - Lidarr Server: " -ForegroundColor Gray -NoNewline
    Write-Host "http://lidarr:8686" -ForegroundColor Cyan
    Write-Host "    - API Key: " -ForegroundColor Gray -NoNewline
    Write-Host "(from Lidarr > Settings > General)" -ForegroundColor Cyan
    Write-Host "    - Click 'Test' then 'Save'" -ForegroundColor Gray

    Press-Enter

    # --- Plex Setup ---
    Show-BeginnerTip -Title "What is Plex?" -Body "Plex is your personal Netflix. It streams your movies,
TV and music to phones, smart TVs, consoles and browsers.
It's free to use."
    Write-Banner
    Write-Host "  SETUP GUIDE: Plex (Media Server)" -ForegroundColor Magenta
    Write-Host "  --------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " PLEX IS ALREADY INSTALLED! " -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host ""
    Write-Host "  Plex is included in your Privacy Box. Watch your media on any device!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Press ENTER to open Plex in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:32400/web"
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " STEP 1: Initial Setup " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Sign in with your Plex account" -ForegroundColor White
    Write-Host "  2. Give your server a name" -ForegroundColor White
    Write-Host "  3. 'Allow me to access my media outside my home': tick or untick as you like" -ForegroundColor White
    Write-Host "  4. Add your libraries:" -ForegroundColor White
    Write-Host ""
    Write-Host "     Movies:   " -ForegroundColor Yellow -NoNewline
    Write-Host "/data/movies" -ForegroundColor Cyan
    Write-Host "     TV Shows: " -ForegroundColor Yellow -NoNewline
    Write-Host "/data/tvshows" -ForegroundColor Cyan
    Write-Host "     Music:    " -ForegroundColor Yellow -NoNewline
    Write-Host "/data/music" -ForegroundColor Cyan -NoNewline
    Write-Host " (if you enabled Lidarr)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  5. Finish the setup wizard" -ForegroundColor White
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " SERVER NOT SHOWING UP? " -BackgroundColor DarkRed -ForegroundColor White
    Write-Host ""
    Write-Host "  This happens if the claim step was skipped or the token expired." -ForegroundColor White
    Write-Host "    1. Get a fresh token from: " -ForegroundColor White -NoNewline
    Write-Host "https://plex.tv/claim" -ForegroundColor Cyan
    Write-Host "    2. In the .env file in your PrivacyServer folder, set:" -ForegroundColor White
    Write-Host "       PLEX_CLAIM=`"claim-...`"" -ForegroundColor Cyan
    Write-Host "    3. Within 4 minutes, run this from the PrivacyServer folder:" -ForegroundColor White
    Write-Host "       docker compose up -d --force-recreate plex" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " OPTIONAL: Auto-refresh Plex when downloads finish " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
    Write-Host "  In Sonarr and Radarr go to: Settings > Connect > + > Plex Media Server" -ForegroundColor White
    Write-Host "    - Host: " -ForegroundColor Gray -NoNewline
    Write-Host "plex" -ForegroundColor Cyan
    Write-Host "    - Port: " -ForegroundColor Gray -NoNewline
    Write-Host "32400" -ForegroundColor Cyan
    Write-Host "    - Click 'Authenticate with Plex.tv', then 'Test' and 'Save'" -ForegroundColor Gray

    Press-Enter

    Write-Banner
    Write-Host "  SETUP GUIDE: Plex (Watch on Other Devices)" -ForegroundColor Magenta
    Write-Host "  ------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " WATCH ON OTHER DEVICES " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Install the Plex app on your TV/phone/tablet" -ForegroundColor White
    Write-Host "  2. Sign in with the same Plex account" -ForegroundColor White
    Write-Host "  3. Your server appears automatically" -ForegroundColor White
    Write-Host ""
    Write-Host "  Device on your home network can't find it?" -ForegroundColor Yellow
    Write-Host "    1. Find this PC's IP: Open CMD and type 'ipconfig'" -ForegroundColor White
    Write-Host "       Look for 'IPv4 Address' (e.g., 192.168.1.100)" -ForegroundColor Gray
    Write-Host "    2. In Plex go to: Settings > Network > Custom server access URLs" -ForegroundColor White
    Write-Host "    3. Enter: " -ForegroundColor White -NoNewline
    Write-Host "http://YOUR-IP:32400" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " CAN'T CONNECT FROM OTHER DEVICES? " -BackgroundColor DarkRed -ForegroundColor White
    Write-Host ""
    Write-Host "  Windows Firewall may be blocking connections:" -ForegroundColor Yellow
    Write-Host "    1. Open Windows Defender Firewall" -ForegroundColor White
    Write-Host "    2. Click 'Allow an app through firewall'" -ForegroundColor White
    Write-Host "    3. Click 'Change settings' then 'Allow another app'" -ForegroundColor White
    Write-Host "    4. Add: " -ForegroundColor White -NoNewline
    Write-Host "C:\Windows\System32\cmd.exe" -ForegroundColor Cyan -NoNewline
    Write-Host " (Docker handles the rest)" -ForegroundColor Gray
    Write-Host "    5. Check BOTH 'Private' and 'Public' boxes" -ForegroundColor White
    Write-Host ""
    Write-Host "  Or allow the port directly (PowerShell as Admin):" -ForegroundColor Gray
    Write-Host "    Plex: " -ForegroundColor Gray -NoNewline
    Write-Host "netsh advfirewall firewall add rule name=`"Plex`" dir=in action=allow protocol=tcp localport=32400" -ForegroundColor DarkGray

    Press-Enter

    # --- Remote Access Setup (Optional) ---
    Write-Banner
    Write-Host "  OPTIONAL: Watch Your Media From Anywhere" -ForegroundColor Magenta
    Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Want to access your media outside your home (hotel, work, etc.)?" -ForegroundColor White
    Write-Host "  Use Plex's built-in Remote Access, or a secure mesh network (Tailscale)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " OPTION A: Plex Remote Access (built in) " -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host ""
    Write-Host "    1. In Plex go to: Settings > Remote Access > Enable" -ForegroundColor White
    Write-Host "    2. Needs port " -ForegroundColor White -NoNewline
    Write-Host "32400" -ForegroundColor Cyan -NoNewline
    Write-Host " forwarded on your router to this computer" -ForegroundColor White
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " OPTION B: Tailscale (Free, no port forwarding) " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
    Write-Host "  On this PC:" -ForegroundColor Yellow
    Write-Host "    1. Download Tailscale: " -ForegroundColor White -NoNewline
    Write-Host "https://tailscale.com/download" -ForegroundColor Cyan
    Write-Host "    2. Install and sign in (Google/Microsoft/etc.)" -ForegroundColor White
    Write-Host "    3. Note your Tailscale IP (starts with 100.x.x.x)" -ForegroundColor White
    Write-Host ""
    Write-Host "  On your phone/laptop:" -ForegroundColor Yellow
    Write-Host "    1. Install Tailscale app and sign in with same account" -ForegroundColor White
    Write-Host "    2. In the Plex app or a browser, open:" -ForegroundColor White
    Write-Host "       " -ForegroundColor White -NoNewline
    Write-Host "http://100.x.x.x:32400/web" -ForegroundColor Cyan -NoNewline
    Write-Host " (use your actual Tailscale IP)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " WHY THIS IS SAFE " -BackgroundColor DarkMagenta -ForegroundColor White
    Write-Host ""
    Write-Host "  Tailscale creates an encrypted tunnel directly between your devices." -ForegroundColor Gray
    Write-Host "  Nothing is exposed to the internet - no hackers can find your server!" -ForegroundColor Gray
    Write-Host "  Plex Remote Access does open port 32400 to the internet. Plex handles" -ForegroundColor Gray
    Write-Host "  sign-in and encryption, but Tailscale is the more private option." -ForegroundColor Gray

    Press-Enter

    # --- Complete ---
    Write-Banner
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Green
    Write-Host "       PRIVACY BOX SETUP COMPLETE!" -ForegroundColor White
    Write-Host "  =============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Your Services:" -ForegroundColor Yellow
    Write-Host "    qBittorrent:  http://localhost:8080" -ForegroundColor White
    Write-Host "    Prowlarr:     http://localhost:8181" -ForegroundColor White
    Write-Host "    Sonarr:       http://localhost:8989" -ForegroundColor White
    Write-Host "    Radarr:       http://localhost:7878" -ForegroundColor White
    Write-Host "    Plex:         http://localhost:32400/web" -ForegroundColor Cyan -NoNewline
    Write-Host " (Media Server)" -ForegroundColor Gray
    # Show optional services if they were enabled
    $sabnzbdRunning = docker ps --format '{{.Names}}' 2>$null | Select-String '^sabnzbd$'
    if ($sabnzbdRunning) {
        Write-Host "    SABnzbd:      http://localhost:8085" -ForegroundColor White -NoNewline
        Write-Host " (Usenet Downloads)" -ForegroundColor Gray
    }
    $lidarrRunning = docker ps --format '{{.Names}}' 2>$null | Select-String '^lidarr$'
    if ($lidarrRunning) {
        Write-Host "    Lidarr:       http://localhost:8686" -ForegroundColor White -NoNewline
        Write-Host " (Music Manager)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "  Your media folder:" -ForegroundColor Yellow
    Write-Host "    $env:USERPROFILE\Desktop\PrivacyServer\media\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Your media server is up and running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor DarkGray
    Write-Host "  IS IT RUNNING?" -ForegroundColor Yellow
    Write-Host "  =============================================" -ForegroundColor DarkGray
    Write-Host "  Your Privacy Box is currently " -ForegroundColor White -NoNewline
    Write-Host "RUNNING" -ForegroundColor Green -NoNewline
    Write-Host "!" -ForegroundColor White
    Write-Host "  It will keep running in the background." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Useful Commands (run from PrivacyServer folder):" -ForegroundColor Yellow
    Write-Host "    Start:   docker compose up -d" -ForegroundColor Gray
    Write-Host "    Stop:    docker compose down" -ForegroundColor Gray
    Write-Host "    Restart: docker compose restart" -ForegroundColor Gray
    Write-Host "    Status:  docker ps" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host "  Created by TOM SPARK" -ForegroundColor Yellow
    Write-Host "  Subscribe: youtube.com/@TomSparkReviews" -ForegroundColor White
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Questions? Join the Discord!" -ForegroundColor Yellow
    Write-Host "  https://discord.gg/uPdRcKxEVS" -ForegroundColor Cyan
    Write-Host ""
}

# --- Bonus: Notifiarr Setup ---
function Setup-Notifiarr {
    param([string]$Path)

    Write-Banner
    Write-Host "  BONUS: Discord Notifications with Notifiarr" -ForegroundColor Magenta
    Write-Host "  --------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Want Discord notifications when:" -ForegroundColor White
    Write-Host "    - A movie/show starts downloading?" -ForegroundColor Gray
    Write-Host "    - Downloads complete?" -ForegroundColor Gray
    Write-Host "    - New episodes are available?" -ForegroundColor Gray
    Write-Host "    - Something goes wrong?" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Notifiarr" -ForegroundColor Cyan -NoNewline
    Write-Host " sends beautiful notifications to your Discord server!" -ForegroundColor White
    Write-Host ""

    if (-not (Ask-YesNo "Would you like to set up Discord notifications?")) {
        Write-Host ""
        Write-Info "Skipping Notifiarr setup. You can enable it later!"
        Write-Host ""
        Write-Host "  To enable later, run:" -ForegroundColor Gray
        Write-Host "    docker compose --profile notifications up -d" -ForegroundColor Cyan
        return
    }

    Write-Banner
    Write-Host "  STEP 1: Create Notifiarr Account" -ForegroundColor Magenta
    Write-Host "  --------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  1. Go to " -ForegroundColor White -NoNewline
    Write-Host "https://notifiarr.com" -ForegroundColor Cyan -NoNewline
    Write-Host " and create a FREE account" -ForegroundColor White
    Write-Host "  2. Sign in with Discord (recommended) or email" -ForegroundColor White
    Write-Host "  3. Go to your Profile and copy your " -ForegroundColor White -NoNewline
    Write-Host "API Key" -ForegroundColor Yellow
    Write-Host ""

    if (Ask-YesNo "Open Notifiarr.com in your browser now?") {
        Start-Process "https://notifiarr.com"
        Write-Host ""
        Write-Info "Browser opened. Create account, then copy your API Key."
        Press-Enter
    }

    Write-Host ""
    Write-Host "  Paste your Notifiarr API Key: " -ForegroundColor Yellow -NoNewline
    $apiKey = Read-Host

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Error-Custom "No API key provided. Skipping Notifiarr."
        return
    }

    # Add API key to .env
    Add-Content -Path "$Path\.env" -Value ""
    Add-Content -Path "$Path\.env" -Value "# --- NOTIFIARR (Discord Notifications) ---"
    Add-Content -Path "$Path\.env" -Value "NOTIFIARR_API_KEY=$apiKey"

    Write-Success "API Key saved!"
    Write-Host ""

    Write-Step "1" "Starting Notifiarr container..."
    Push-Location $Path
    docker compose --profile notifications up -d 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    Pop-Location

    Write-Host ""
    Write-Success "Notifiarr is running!"

    Press-Enter

    Write-Banner
    Write-Host "  STEP 2: Configure Notifiarr" -ForegroundColor Magenta
    Write-Host "  ---------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open Notifiarr in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:5454"
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " LOGIN " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host "    Username: " -ForegroundColor White -NoNewline
    Write-Host "admin" -ForegroundColor Cyan
    Write-Host "    Password: " -ForegroundColor White -NoNewline
    Write-Host "(your API key)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " CONNECT YOUR APPS " -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
    Write-Host "  In Notifiarr web UI:" -ForegroundColor Yellow
    Write-Host "    1. Go to 'Starr Apps' in the menu" -ForegroundColor White
    Write-Host "    2. Enable Radarr and add:" -ForegroundColor White
    Write-Host "       - URL: " -ForegroundColor Gray -NoNewline
    Write-Host "http://radarr:7878" -ForegroundColor Cyan
    Write-Host "       - API Key: " -ForegroundColor Gray -NoNewline
    Write-Host "(from Radarr > Settings > General)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    3. Enable Sonarr and add:" -ForegroundColor White
    Write-Host "       - URL: " -ForegroundColor Gray -NoNewline
    Write-Host "http://sonarr:8989" -ForegroundColor Cyan
    Write-Host "       - API Key: " -ForegroundColor Gray -NoNewline
    Write-Host "(from Sonarr > Settings > General)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  On notifiarr.com website:" -ForegroundColor Yellow
    Write-Host "    1. Go to Integrations > Manage" -ForegroundColor White
    Write-Host "    2. Enable Radarr/Sonarr integrations" -ForegroundColor White
    Write-Host "    3. Set up your Discord channel for notifications" -ForegroundColor White
    Write-Host ""
    Write-Host "  That's it! You'll now get Discord notifications!" -ForegroundColor Green

    Press-Enter

    Write-Banner
    Write-Host "  =============================================" -ForegroundColor Green
    Write-Host "       NOTIFIARR SETUP COMPLETE!" -ForegroundColor White
    Write-Host "  =============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Notifiarr Web UI: " -ForegroundColor Yellow -NoNewline
    Write-Host "http://localhost:5454" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Configure notifications at: " -ForegroundColor White -NoNewline
    Write-Host "https://notifiarr.com" -ForegroundColor Cyan
    Write-Host ""
}

# --- Bonus: FlareSolverr Setup ---
function Setup-FlareSolverr {
    param([string]$Path)

    Write-Banner
    Write-Host "  BONUS: Cloudflare Bypass with FlareSolverr" -ForegroundColor Magenta
    Write-Host "  -------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Some indexers are protected by Cloudflare anti-bot challenges." -ForegroundColor White
    Write-Host "  FlareSolverr runs a headless browser to solve these automatically," -ForegroundColor White
    Write-Host "  so Prowlarr can access protected indexers without manual intervention." -ForegroundColor White
    Write-Host ""

    if (-not (Ask-YesNo "Would you like to enable FlareSolverr?")) {
        Write-Host ""
        Write-Info "Skipping FlareSolverr setup. You can enable it later!"
        Write-Host ""
        Write-Host "  To enable later, run:" -ForegroundColor Gray
        Write-Host "    docker compose --profile flaresolverr up -d" -ForegroundColor Cyan
        return
    }

    Write-Host ""
    Write-Step "1" "Starting FlareSolverr container..."
    Push-Location $Path
    docker compose --profile flaresolverr up -d 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    Pop-Location

    Write-Host ""
    Write-Success "FlareSolverr is running!"
    Write-Host ""
    Write-Host "  Configure FlareSolverr in Prowlarr:" -ForegroundColor Yellow
    Write-Host "    1. Open Prowlarr: " -ForegroundColor White -NoNewline
    Write-Host "http://localhost:8181" -ForegroundColor Cyan
    Write-Host "    2. Go to: Settings > Indexers" -ForegroundColor White
    Write-Host "    3. Click '+' under 'Indexer Proxies'" -ForegroundColor White
    Write-Host "    4. Select 'FlareSolverr'" -ForegroundColor White
    Write-Host "    5. Set Host to: " -ForegroundColor White -NoNewline
    Write-Host "http://flaresolverr:8191" -ForegroundColor Cyan
    Write-Host "    6. Click 'Test' then 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "  Prowlarr will now automatically bypass Cloudflare challenges!" -ForegroundColor Green

    Press-Enter
}

# --- Bonus: SABnzbd Setup ---
function Setup-SABnzbd {
    param([string]$Path)

    Write-Banner
    Write-Host "  BONUS: Usenet Downloads with SABnzbd" -ForegroundColor Magenta
    Write-Host "  -------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  SABnzbd is a Usenet download client — an alternative to torrents." -ForegroundColor White
    Write-Host "  Usenet downloads are SSL-encrypted and typically faster." -ForegroundColor White
    Write-Host "  You'll need a Usenet provider subscription (e.g., Newshosting, Eweka)." -ForegroundColor White
    Write-Host ""

    if (-not (Ask-YesNo "Would you like to enable Usenet downloads (SABnzbd)?")) {
        Write-Host ""
        Write-Info "Skipping SABnzbd setup. You can enable it later!"
        Write-Host ""
        Write-Host "  To enable later, run:" -ForegroundColor Gray
        Write-Host "    docker compose --profile sabnzbd up -d" -ForegroundColor Cyan
        return
    }

    Write-Host ""
    Write-Step "1" "Starting SABnzbd container..."
    Push-Location $Path
    docker compose --profile sabnzbd up -d 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    Pop-Location

    Write-Host ""
    Write-Success "SABnzbd is running!"

    Press-Enter

    Write-Banner
    Write-Host "  Configure SABnzbd" -ForegroundColor Magenta
    Write-Host "  -----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open SABnzbd in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8085"
    Write-Host ""
    Write-Host "  1. Follow the SABnzbd Quick-Start Wizard" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Add your Usenet provider:" -ForegroundColor Yellow
    Write-Host "     - Host: " -ForegroundColor White -NoNewline
    Write-Host "(from your Usenet provider, e.g., news.newshosting.com)" -ForegroundColor Cyan
    Write-Host "     - Port: " -ForegroundColor White -NoNewline
    Write-Host "563" -ForegroundColor Cyan -NoNewline
    Write-Host " (SSL)" -ForegroundColor Gray
    Write-Host "     - Username & Password: " -ForegroundColor White -NoNewline
    Write-Host "(your Usenet account credentials)" -ForegroundColor Cyan
    Write-Host "     - SSL: " -ForegroundColor White -NoNewline
    Write-Host "Yes" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. Use SABnzbd as a download client in Sonarr/Radarr/Lidarr:" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Download Clients" -ForegroundColor White
    Write-Host "     - Click '+' and select 'SABnzbd'" -ForegroundColor White
    Write-Host "     - Host: " -ForegroundColor White -NoNewline
    Write-Host "sabnzbd" -ForegroundColor Cyan
    Write-Host "     - Port: " -ForegroundColor White -NoNewline
    Write-Host "8080" -ForegroundColor Cyan
    Write-Host "     - API Key: " -ForegroundColor White -NoNewline
    Write-Host "(from SABnzbd > Config > General)" -ForegroundColor Cyan
    Write-Host "     - Click 'Test' then 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "  SABnzbd is ready for Usenet downloads!" -ForegroundColor Green

    Press-Enter
}

# --- Bonus: Lidarr Setup ---
function Setup-Lidarr {
    param([string]$Path)

    Write-Banner
    Write-Host "  BONUS: Music Management with Lidarr" -ForegroundColor Magenta
    Write-Host "  ------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Lidarr automatically finds, downloads, and organizes music." -ForegroundColor White
    Write-Host "  It works just like Sonarr/Radarr but for music albums and artists." -ForegroundColor White
    Write-Host "  Your music will be available in Plex for streaming!" -ForegroundColor White
    Write-Host ""

    if (-not (Ask-YesNo "Would you like to enable music management (Lidarr)?")) {
        Write-Host ""
        Write-Info "Skipping Lidarr setup. You can enable it later!"
        Write-Host ""
        Write-Host "  To enable later, run:" -ForegroundColor Gray
        Write-Host "    docker compose --profile lidarr up -d" -ForegroundColor Cyan
        return
    }

    Write-Host ""
    Write-Step "1" "Starting Lidarr container..."
    Push-Location $Path
    docker compose --profile lidarr up -d 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    Pop-Location

    Write-Host ""
    Write-Success "Lidarr is running!"

    Press-Enter

    Write-Banner
    Write-Host "  Configure Lidarr" -ForegroundColor Magenta
    Write-Host "  ----------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press ENTER to open Lidarr in your browser..." -ForegroundColor Yellow
    Read-Host | Out-Null
    Start-Process "http://localhost:8686"
    Write-Host ""
    Write-Host "  1. Create your admin account when prompted" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Add Root Folder (where music is saved):" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Media Management" -ForegroundColor White
    Write-Host "     - Scroll down and click 'Add Root Folder'" -ForegroundColor White
    Write-Host "     - Enter path: " -ForegroundColor White -NoNewline
    Write-Host "/data/media/music" -ForegroundColor Cyan
    Write-Host "     - Click 'OK'" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. Add Download Client:" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > Download Clients" -ForegroundColor White
    Write-Host "     - Click '+' and select 'qBittorrent'" -ForegroundColor White
    Write-Host "     - Host: " -ForegroundColor White -NoNewline
    Write-Host "qbittorrent" -ForegroundColor Cyan
    Write-Host "     - Port: " -ForegroundColor White -NoNewline
    Write-Host "8080" -ForegroundColor Cyan
    Write-Host "     - Username: " -ForegroundColor White -NoNewline
    Write-Host "admin" -ForegroundColor Cyan
    Write-Host "     - Password: " -ForegroundColor White -NoNewline
    Write-Host "(your qBittorrent password)" -ForegroundColor Cyan
    Write-Host "     - Click 'Test' then 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "  4. Copy your API Key (for Prowlarr):" -ForegroundColor Yellow
    Write-Host "     - Go to: Settings > General" -ForegroundColor White
    Write-Host "     - Copy the 'API Key'" -ForegroundColor White
    Write-Host ""
    Write-Host "  5. Connect in Prowlarr:" -ForegroundColor Yellow
    Write-Host "     - Open Prowlarr: " -ForegroundColor White -NoNewline
    Write-Host "http://localhost:8181" -ForegroundColor Cyan
    Write-Host "     - Go to: Settings > Apps" -ForegroundColor White
    Write-Host "     - Click '+' and select 'Lidarr'" -ForegroundColor White
    Write-Host "     - Prowlarr Server: " -ForegroundColor White -NoNewline
    Write-Host "http://prowlarr:9696" -ForegroundColor Cyan
    Write-Host "     - Lidarr Server: " -ForegroundColor White -NoNewline
    Write-Host "http://lidarr:8686" -ForegroundColor Cyan
    Write-Host "     - API Key: " -ForegroundColor White -NoNewline
    Write-Host "(paste the Lidarr API key)" -ForegroundColor Cyan
    Write-Host "     - Click 'Test' then 'Save'" -ForegroundColor White
    Write-Host ""
    Write-Host "  Lidarr is ready! Add artists and let it find your music." -ForegroundColor Green

    Press-Enter
}

# --- Main Execution ---
function Main {
    Write-Banner

    # Pre-flight checks
    if (-not $SkipDockerCheck) {
        if (-not (Test-DockerInstalled)) {
            Press-Enter
            exit 1
        }

        if (-not (Test-DockerRunning)) {
            Press-Enter
            exit 1
        }
    }

    Write-Success "Pre-flight checks passed!"
    Press-Enter

    # Experience level selection
    Get-ExperienceLevel
    Show-ArrOverview

    # Collect configuration
    $timezone = Get-Timezone

    # Confirmation
    Write-Banner
    Write-Host "  CONFIGURATION SUMMARY" -ForegroundColor Magenta
    Write-Host "  ---------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Install Path:    $InstallPath" -ForegroundColor White
    Write-Host "  Timezone:        $timezone" -ForegroundColor White
    Write-Host ""

    if (-not (Ask-YesNo "Proceed with installation?")) {
        Write-Host ""
        Write-Info "Installation cancelled."
        exit 0
    }

    # Create directory structure
    Write-Banner
    Write-Host "  CREATING FILES" -ForegroundColor Magenta
    Write-Host "  --------------" -ForegroundColor DarkGray
    Write-Host ""

    Write-Step "1" "Creating directory: $InstallPath"
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallPath\config" -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallPath\media\downloads" -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallPath\media\music" -Force | Out-Null
    Write-Success "Directories created"

    Write-Step "2" "Generating .env file..."
    New-EnvFile -Path $InstallPath -Timezone $timezone
    Write-Success ".env file created"

    Write-Step "3" "Generating docker-compose.yml..."
    New-DockerComposeFile -Path $InstallPath
    Write-Success "docker-compose.yml created"

    Press-Enter

    # Launch
    $success = Start-PrivacyBox -Path $InstallPath

    if ($success) {
        Press-Enter
        Show-SetupGuide
        Setup-Notifiarr -Path $InstallPath
        Setup-FlareSolverr -Path $InstallPath
        Setup-SABnzbd -Path $InstallPath
        Setup-Lidarr -Path $InstallPath
    } else {
        Write-Host ""
        Write-Error-Custom "Setup failed. Some containers did not start."
        Write-Host ""
        Write-Host "  Common fixes:" -ForegroundColor Yellow
        Write-Host "    1. Make sure Docker Desktop is running and has finished starting" -ForegroundColor White
        Write-Host "    2. Check no other program is using ports 8080, 8181, 8989, 7878 or 32400" -ForegroundColor White
        Write-Host "    3. View recent logs from the PrivacyServer folder:" -ForegroundColor White
        Write-Host "       docker compose logs --tail 50" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  To retry, run this script again." -ForegroundColor Gray
    }
}

# Run
Main
