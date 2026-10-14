#!/bin/bash
# ============================================================
# PRIVACY BOX - One-Click Media Server Setup
# Created by Tom Spark | https://youtube.com/@TomSparkReviews
#
# LICENSE: MIT with Attribution - You MUST credit Tom Spark
#          if you share, modify, or create content based on this.
#
# Original: https://github.com/loponai/tomsparkprivacyarrsuite (No-VPN edition)
# ============================================================

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BEGINNER_MODE=false

# --- WSL2 Detection ---
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
NC='\033[0m' # No Color

# --- Helper Functions ---
write_banner() {
    clear
    echo ""
    echo -e "  ${CYAN}=====================================================${NC}"
    echo -e "       ${WHITE}PRIVACY BOX - Secure Media Server Setup${NC}"
    echo -e "  ${CYAN}=====================================================${NC}"
    echo -e "         ${DARKGRAY}Created by ${YELLOW}TOM SPARK${DARKGRAY} | v${VERSION}${NC}"
    echo -e "      ${DARKGRAY}YouTube: youtube.com/@TomSparkReviews${NC}"
    echo -e "  ${CYAN}=====================================================${NC}"
    echo -e "   ${DARKGRAY}(c) 2026 Tom Spark. Licensed under MIT+Attribution.${NC}"
    echo -e "   ${RED}Unauthorized copying without credit = DMCA takedown.${NC}"
    echo -e "  ${CYAN}=====================================================${NC}"
    echo ""
}

write_step() {
    echo -e "  ${YELLOW}[$1]${NC} ${WHITE}$2${NC}"
}

write_success() {
    echo -e "  ${GREEN}[OK]${NC} ${WHITE}$1${NC}"
}

write_error() {
    echo -e "  ${RED}[X]${NC} ${WHITE}$1${NC}"
}

write_info() {
    echo -e "  ${CYAN}[i]${NC} ${GRAY}$1${NC}"
}

write_warning() {
    echo -e "  ${YELLOW}[!]${NC} ${WHITE}$1${NC}"
}

press_enter() {
    echo ""
    echo -e "  ${DARKGRAY}Press ENTER to continue...${NC}"
    read -r
}

ask_yes_no() {
    echo ""
    echo -ne "  ${YELLOW}$1 (Y/N): ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

open_url() {
    local url="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url"
    elif [[ "$IS_WSL" == "true" ]]; then
        explorer.exe "$url" 2>/dev/null || wslview "$url" 2>/dev/null || \
        echo -e "  ${CYAN}Open: $url${NC}"
    else
        xdg-open "$url" 2>/dev/null || echo -e "  ${CYAN}Open: $url${NC}"
    fi
}

# --- Beginner Mode ---
show_beginner_tip() {
    local title="$1"
    local body="$2"

    if [[ "$BEGINNER_MODE" != "true" ]]; then
        return
    fi

    echo ""
    echo -e "  ${CYAN}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC}  ${WHITE}💡 $title${NC}"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────┤${NC}"
    while IFS= read -r line; do
        echo -e "  ${CYAN}│${NC}  ${GRAY}$line${NC}"
    done <<< "$body"
    echo -e "  ${CYAN}└──────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${DARKGRAY}Press ENTER to continue...${NC}"
    read -r
}

get_experience_level() {
    write_banner
    echo -e "  ${MAGENTA}EXPERIENCE LEVEL${NC}"
    echo -e "  ${DARKGRAY}----------------${NC}"
    echo ""
    echo -e "  ${WHITE}How familiar are you with the ARR suite?${NC}"
    echo ""
    echo -e "    ${GREEN}1. I'm brand new to ARR${NC}  ${GRAY}(show me extra explanations)${NC}"
    echo -e "    ${CYAN}2. I'm familiar with ARR${NC} ${GRAY}(skip the intro tips)${NC}"
    echo ""
    echo -ne "  ${YELLOW}Select (1-2) [default: 1]: ${NC}"
    read -r choice

    case "$choice" in
        2)
            BEGINNER_MODE=false
            write_success "Experienced mode — skipping beginner tips."
            ;;
        *)
            BEGINNER_MODE=true
            write_success "Beginner mode — extra tips will be shown throughout setup."
            ;;
    esac
}

show_arr_overview() {
    if [[ "$BEGINNER_MODE" != "true" ]]; then
        return
    fi

    write_banner
    echo -e "  ${MAGENTA}WHAT IS THE ARR SUITE?${NC}"
    echo -e "  ${DARKGRAY}----------------------${NC}"
    echo ""
    echo -e "  ${WHITE}The ARR suite is a collection of apps that work together${NC}"
    echo -e "  ${WHITE}to automatically find, download, and organize media:${NC}"
    echo ""
    echo -e "  ${CYAN}┌─────────────┬──────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC} ${YELLOW}Service${NC}     ${CYAN}│${NC} ${WHITE}What it does${NC}                              ${CYAN}│${NC}"
    echo -e "  ${CYAN}├─────────────┼──────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}qBittorrent${NC} ${CYAN}│${NC} ${GRAY}Downloads torrent files${NC}                  ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}Prowlarr${NC}    ${CYAN}│${NC} ${GRAY}Searches torrent sites for content${NC}       ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}Sonarr${NC}      ${CYAN}│${NC} ${GRAY}Finds & organizes TV shows automatically${NC} ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}Radarr${NC}      ${CYAN}│${NC} ${GRAY}Finds & organizes movies automatically${NC}   ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}Jellyfin${NC}    ${CYAN}│${NC} ${GRAY}Streams your media (like personal Netflix)${NC}${CYAN}│${NC}"
    echo -e "  ${CYAN}├─────────────┼──────────────────────────────────────────┤${NC}"
    echo -e "  ${CYAN}│${NC} ${YELLOW}Optional:${NC}   ${CYAN}│${NC}                                          ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}SABnzbd${NC}     ${CYAN}│${NC} ${GRAY}Downloads from Usenet (alternative to torrents)${NC}${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC} ${GREEN}Lidarr${NC}      ${CYAN}│${NC} ${GRAY}Finds & organizes music automatically${NC}   ${CYAN}│${NC}"
    echo -e "  ${CYAN}└─────────────┴──────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${WHITE}How they connect:${NC}"
    echo ""
    echo -e "  ${GRAY}You search in${NC} ${GREEN}Sonarr/Radarr${NC} ${GRAY}→${NC} ${GREEN}Prowlarr${NC} ${GRAY}finds it →${NC} ${GREEN}qBittorrent${NC} ${GRAY}downloads it${NC}"
    echo -e "  ${GRAY}→${NC} ${GREEN}Sonarr/Radarr${NC} ${GRAY}organizes it →${NC} ${GREEN}Jellyfin${NC} ${GRAY}streams it to your devices${NC}"

    press_enter
}

# --- Pre-Flight Checks ---
test_docker_installed() {
    write_step "1" "Checking if Docker is installed..."

    if ! command -v docker &> /dev/null; then
        write_error "Docker is NOT installed!"
        echo ""
        echo -e "  ${WHITE}Please install Docker first:${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "  ${CYAN}https://www.docker.com/products/docker-desktop/${NC}"
            echo -e "  ${WHITE}Download Docker Desktop for Mac${NC}"
        else
            echo -e "  ${CYAN}https://docs.docker.com/engine/install/${NC}"
            echo -e "  ${WHITE}Or run: curl -fsSL https://get.docker.com | sh${NC}"
        fi
        return 1
    fi
    write_success "Docker is installed"
    return 0
}

test_docker_running() {
    write_step "2" "Checking if Docker is running..."

    if ! docker info &> /dev/null; then
        write_error "Docker is NOT running!"
        echo ""
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "  ${WHITE}Please start Docker Desktop and wait for it to be ready.${NC}"
        else
            echo -e "  ${WHITE}Please start Docker: ${CYAN}sudo systemctl start docker${NC}"
        fi
        return 1
    fi
    write_success "Docker is running"
    return 0
}

get_timezone() {
    write_banner
    echo -e "  ${MAGENTA}STEP 1: TIMEZONE${NC}"
    echo -e "  ${DARKGRAY}----------------${NC}"
    echo ""
    echo -e "  ${WHITE}Common timezones:${NC}"
    echo -e "    ${GRAY}1. America/Los_Angeles (Pacific)${NC}"
    echo -e "    ${GRAY}2. America/Denver (Mountain)${NC}"
    echo -e "    ${GRAY}3. America/Chicago (Central)${NC}"
    echo -e "    ${GRAY}4. America/New_York (Eastern)${NC}"
    echo -e "    ${GRAY}5. Europe/London${NC}"
    echo -e "    ${GRAY}6. Europe/Berlin${NC}"
    echo -e "    ${GRAY}7. Custom${NC}"
    echo ""
    echo -ne "  ${YELLOW}Select (1-7) [default: 1]: ${NC}"
    read -r choice

    case "$choice" in
        2) TIMEZONE="America/Denver" ;;
        3) TIMEZONE="America/Chicago" ;;
        4) TIMEZONE="America/New_York" ;;
        5) TIMEZONE="Europe/London" ;;
        6) TIMEZONE="Europe/Berlin" ;;
        7)
            echo -ne "  ${YELLOW}Enter timezone (e.g., Australia/Sydney): ${NC}"
            read -r TIMEZONE
            ;;
        *) TIMEZONE="America/Los_Angeles" ;;
    esac
}

# --- Sanitize value for .env file (escape special chars) ---
sanitize_env_value() {
    local val="$1"
    # Escape backslashes first, then double quotes, then dollar signs
    val="${val//\\/\\\\}"
    val="${val//\"/\\\"}"
    val="${val//\$/\\\$}"
    val="${val//\`/\\\`}"
    printf '%s' "$val"
}

# --- File Generation ---
create_env_file() {
    cat > "$SCRIPT_DIR/.env" << EOF
# ==========================================
# TOM SPARK'S PRIVACY BOX CONFIG (No-VPN edition)
# Created by Tom Spark | youtube.com/@TomSparkReviews
# ==========================================

# --- SYSTEM SETTINGS ---
TZ=$(sanitize_env_value "$TIMEZONE")
ROOT_DIR=.
EOF
}

# --- Docker Operations ---
start_privacy_box() {
    write_banner
    echo -e "  ${MAGENTA}LAUNCHING PRIVACY BOX${NC}"
    echo -e "  ${DARKGRAY}---------------------${NC}"
    echo ""

    cd "$SCRIPT_DIR" || exit 1

    write_step "1" "Pulling Docker images (this may take a few minutes on first run)..."
    echo ""
    docker compose pull </dev/null 2>&1 | sed 's/^/      /'

    echo ""
    write_step "2" "Starting containers..."
    echo ""
    docker compose up -d </dev/null 2>&1 | sed 's/^/      /'

    echo ""
    write_step "3" "Waiting for containers to start..."

    core_containers=(qbittorrent prowlarr sonarr radarr jellyfin)
    max_attempts=30
    attempt=0
    all_running=false

    while [[ $attempt -lt $max_attempts ]] && [[ "$all_running" == "false" ]]; do
        sleep 2
        ((attempt++))

        all_running=true
        for c in "${core_containers[@]}"; do
            state=$(docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null)
            if [[ "$state" != "running" ]]; then
                all_running=false
                break
            fi
        done

        echo -ne "${YELLOW}.${NC}"
    done

    echo ""
    echo ""

    if [[ "$all_running" == "true" ]]; then
        write_success "All core containers are running!"
        for c in "${core_containers[@]}"; do
            health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}' "$c" 2>/dev/null)
            [[ "$health" == "starting" ]] && health="running (still warming up)"
            echo -e "      ${GRAY}${c}: ${health}${NC}"
        done
        return 0
    else
        write_error "Some containers did not start in time."
        echo ""
        docker compose ps </dev/null 2>&1 | sed 's/^/      /'
        return 1
    fi
}

# --- Setup Guide ---
show_setup_guide() {
    # --- qBittorrent Setup ---
    show_beginner_tip "What is qBittorrent?" \
"qBittorrent is a download client for torrents. Think
of it like a download manager. Sonarr, Radarr and Lidarr
hand it the files to fetch."
    write_banner
    echo -e "  ${MAGENTA}SETUP GUIDE: qBittorrent (Step 1 of 4)${NC}"
    echo -e "  ${DARKGRAY}--------------------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open qBittorrent in your browser...${NC}"
    read -r
    open_url "http://localhost:8080"
    echo ""
    echo -e "  ${YELLOW}Login:${NC}"
    echo -e "    ${WHITE}Username: ${CYAN}admin${NC}"
    echo -e "    ${WHITE}Password: ${CYAN}(check the command below)${NC}"
    echo ""
    echo -e "  ${WHITE} IMPORTANT ${NC}"
    echo -e "  ${WHITE}qBittorrent generates a random password on first run.${NC}"
    echo ""
    echo -e "  ${YELLOW}To find your password:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "    ${WHITE}1. Open a new Terminal window (Cmd + T)${NC}"
    else
        echo -e "    ${WHITE}1. Open a new terminal window${NC}"
    fi
    echo -e "    ${WHITE}2. Paste this command:${NC}"
    echo ""
    echo -e "       ${CYAN}docker logs qbittorrent 2>&1 | grep password${NC}"
    echo ""
    echo -e "    ${WHITE}3. Press Enter - your password will appear${NC}"
    echo -e "    ${WHITE}4. Copy the password and use it to log in above${NC}"
    echo ""
    echo -e "  ${YELLOW}After logging in, change your password:${NC}"
    echo -e "    ${GRAY}Tools > Options > Web UI > Password${NC}"

    press_enter

    # --- Prowlarr Setup ---
    show_beginner_tip "What is Prowlarr?" \
"Prowlarr is a search engine that looks across many
torrent sites at once. It connects to Sonarr and Radarr
so they can automatically find the content you want."
    write_banner
    echo -e "  ${MAGENTA}SETUP GUIDE: Prowlarr (Step 2 of 4)${NC}"
    echo -e "  ${DARKGRAY}-----------------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Prowlarr in your browser...${NC}"
    read -r
    open_url "http://localhost:8181"
    echo ""
    echo -e "  ${WHITE} IMPORTANT ${NC}"
    echo ""
    echo -e "  ${WHITE}1. Create your admin account when prompted${NC}"
    echo ""
    echo -e "  ${YELLOW}2. Add Indexers:${NC}"
    echo -e "     ${WHITE}- Click 'Indexers' in the sidebar${NC}"
    echo -e "     ${WHITE}- Click '+ Add Indexer'${NC}"
    echo -e "     ${RED}- CRITICAL: Change 'Language' filter from 'en-US' to 'Any'${NC}"
    echo -e "       ${GRAY}(Otherwise you'll only see ~6 indexers instead of 400+)${NC}"
    echo -e "     ${WHITE}- Add: 1337x, TorrentGalaxy, or your preferred sites${NC}"
    echo ""
    echo -e "  ${GRAY}3. We'll connect Prowlarr to Sonarr/Radarr in the next steps${NC}"

    press_enter

    # --- Sonarr Setup ---
    show_beginner_tip "What is Sonarr?" \
"Sonarr automates TV show management. Tell it what shows
you want, and it will find episodes, download them via
qBittorrent, and organize them into neat folders."
    write_banner
    echo -e "  ${MAGENTA}SETUP GUIDE: Sonarr (Step 3 of 4)${NC}"
    echo -e "  ${DARKGRAY}---------------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Sonarr in your browser...${NC}"
    read -r
    open_url "http://localhost:8989"
    echo ""
    echo -e "  ${WHITE}1. Create your admin account when prompted${NC}"
    echo ""
    echo -e "  ${YELLOW}2. Add Root Folder (where TV shows are saved):${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Media Management${NC}"
    echo -e "     ${WHITE}- Scroll down and click 'Add Root Folder'${NC}"
    echo -e "     ${WHITE}- Enter path: ${CYAN}/data/media/tv${NC}"
    echo -e "     ${WHITE}- Click 'OK'${NC}"
    echo ""
    echo -e "  ${YELLOW}3. Add Download Client:${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Download Clients${NC}"
    echo -e "     ${WHITE}- Click '+' and select 'qBittorrent'${NC}"
    echo -e "     ${WHITE}- Host: ${CYAN}qbittorrent${NC}"
    echo -e "     ${WHITE}- Port: ${CYAN}8080${NC}"
    echo -e "     ${WHITE}- Username: ${CYAN}admin${NC}"
    echo -e "     ${WHITE}- Password: ${CYAN}(your qBittorrent password)${NC}"
    echo -e "     ${WHITE}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${YELLOW}4. Copy your API Key:${NC}"
    echo -e "     ${WHITE}- Go to: Settings > General${NC}"
    echo -e "     ${WHITE}- Copy the 'API Key' (you'll need this for Prowlarr)${NC}"

    press_enter

    # --- Radarr Setup ---
    show_beginner_tip "What is Radarr?" \
"Radarr is just like Sonarr, but for movies. Tell it what
movies you want, and it will find, download, and organize
them automatically."
    write_banner
    echo -e "  ${MAGENTA}SETUP GUIDE: Radarr (Step 4 of 4)${NC}"
    echo -e "  ${DARKGRAY}---------------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Radarr in your browser...${NC}"
    read -r
    open_url "http://localhost:7878"
    echo ""
    echo -e "  ${WHITE}1. Create your admin account when prompted${NC}"
    echo ""
    echo -e "  ${YELLOW}2. Add Root Folder (where movies are saved):${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Media Management${NC}"
    echo -e "     ${WHITE}- Scroll down and click 'Add Root Folder'${NC}"
    echo -e "     ${WHITE}- Enter path: ${CYAN}/data/media/movies${NC}"
    echo -e "     ${WHITE}- Click 'OK'${NC}"
    echo ""
    echo -e "  ${YELLOW}3. Add Download Client (same as Sonarr):${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Download Clients${NC}"
    echo -e "     ${WHITE}- Click '+' and select 'qBittorrent'${NC}"
    echo -e "     ${WHITE}- Host: ${CYAN}qbittorrent${NC}"
    echo -e "     ${WHITE}- Port: ${CYAN}8080${NC}"
    echo -e "     ${WHITE}- Username/Password: same as before${NC}"
    echo -e "     ${WHITE}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${YELLOW}4. Copy your API Key:${NC}"
    echo -e "     ${WHITE}- Go to: Settings > General${NC}"
    echo -e "     ${WHITE}- Copy the 'API Key' (you'll need this for Prowlarr)${NC}"

    press_enter

    # --- Connect Prowlarr ---
    write_banner
    echo -e "  ${MAGENTA}FINAL STEP: Connect Prowlarr to Apps${NC}"
    echo -e "  ${DARKGRAY}------------------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Prowlarr in your browser...${NC}"
    read -r
    open_url "http://localhost:8181"
    echo ""
    echo -e "  ${YELLOW}Go to: Settings > Apps${NC}"
    echo ""
    echo -e "  ${WHITE}Add Sonarr:${NC}"
    echo -e "    ${GRAY}- Click '+' and select 'Sonarr'${NC}"
    echo -e "    ${GRAY}- Prowlarr Server: ${CYAN}http://prowlarr:9696${NC}"
    echo -e "    ${GRAY}- Sonarr Server: ${CYAN}http://sonarr:8989${NC}"
    echo -e "    ${GRAY}- API Key: ${CYAN}(paste the Sonarr API key you copied)${NC}"
    echo -e "    ${GRAY}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${WHITE}Add Radarr:${NC}"
    echo -e "    ${GRAY}- Click '+' and select 'Radarr'${NC}"
    echo -e "    ${GRAY}- Prowlarr Server: ${CYAN}http://prowlarr:9696${NC}"
    echo -e "    ${GRAY}- Radarr Server: ${CYAN}http://radarr:7878${NC}"
    echo -e "    ${GRAY}- API Key: ${CYAN}(paste the Radarr API key you copied)${NC}"
    echo -e "    ${GRAY}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${GRAY}If you enabled Lidarr, add it too:${NC}"
    echo -e "    ${GRAY}- Click '+' and select 'Lidarr'${NC}"
    echo -e "    ${GRAY}- Prowlarr Server: ${CYAN}http://prowlarr:9696${NC}"
    echo -e "    ${GRAY}- Lidarr Server: ${CYAN}http://lidarr:8686${NC}"
    echo -e "    ${GRAY}- API Key: ${CYAN}(from Lidarr > Settings > General)${NC}"
    echo -e "    ${GRAY}- Click 'Test' then 'Save'${NC}"

    press_enter

    # --- Jellyfin Setup ---
    show_beginner_tip "What is Jellyfin?" \
"Jellyfin is your personal Netflix. It streams your movies
and TV shows to any device — phone, tablet, smart TV, or
browser. It's completely free and open-source."
    write_banner
    echo -e "  ${MAGENTA}SETUP GUIDE: Jellyfin (Media Server)${NC}"
    echo -e "  ${DARKGRAY}------------------------------------${NC}"
    echo ""
    echo -e "  ${GREEN} JELLYFIN IS ALREADY INSTALLED! ${NC}"
    echo ""
    echo -e "  ${GRAY}Jellyfin is included in your Privacy Box. Watch your media on any device!${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Jellyfin in your browser...${NC}"
    read -r
    open_url "http://localhost:8096"
    echo ""
    echo -e "  ${WHITE} STEP 1: Initial Setup ${NC}"
    echo ""
    echo -e "  ${WHITE}1. Select your language and click Next${NC}"
    echo -e "  ${WHITE}2. Create your admin username and password${NC}"
    echo -e "  ${WHITE}3. Click 'Add Media Library' and add:${NC}"
    echo ""
    echo -e "     ${YELLOW}For Movies:${NC}"
    echo -e "       ${GRAY}- Content type: Movies${NC}"
    echo -e "       ${GRAY}- Click '+' next to Folders${NC}"
    echo -e "       ${GRAY}- Enter: ${CYAN}/data/movies${NC}"
    echo ""
    echo -e "     ${YELLOW}For TV Shows:${NC}"
    echo -e "       ${GRAY}- Content type: Shows${NC}"
    echo -e "       ${GRAY}- Click '+' next to Folders${NC}"
    echo -e "       ${GRAY}- Enter: ${CYAN}/data/tvshows${NC}"
    echo ""
    echo -e "     ${YELLOW}For Music (if you enabled Lidarr):${NC}"
    echo -e "       ${GRAY}- Content type: Music${NC}"
    echo -e "       ${GRAY}- Click '+' next to Folders${NC}"
    echo -e "       ${GRAY}- Enter: ${CYAN}/data/music${NC}"
    echo ""
    echo -e "  ${WHITE}4. Finish the setup wizard${NC}"
    echo ""
    echo -e "  ${WHITE} STEP 2: Watch on Other Devices ${NC}"
    echo ""
    echo -e "  ${YELLOW}Same Network (Home WiFi):${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "    ${WHITE}1. Find this Mac's IP: ${CYAN}ifconfig | grep 'inet '${NC}"
    else
        echo -e "    ${WHITE}1. Find this computer's IP: ${CYAN}ip addr${NC} or ${CYAN}hostname -I${NC}"
    fi
    echo -e "       ${GRAY}Look for your local IP (e.g., 192.168.1.100)${NC}"
    echo -e "    ${WHITE}2. On your TV/phone/tablet, download the Jellyfin app${NC}"
    echo -e "    ${WHITE}3. Enter server address: ${CYAN}http://YOUR-IP:8096${NC}"
    echo ""
    echo -e "  ${WHITE} CAN'T CONNECT FROM OTHER DEVICES? ${NC}"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "  ${YELLOW}macOS Firewall may be blocking connections:${NC}"
        echo -e "    ${WHITE}System Preferences > Security & Privacy > Firewall > Firewall Options${NC}"
        echo -e "    ${WHITE}Add Docker or allow incoming connections${NC}"
    else
        echo -e "  ${YELLOW}Linux firewall may be blocking connections:${NC}"
        echo -e "    ${CYAN}sudo ufw allow 8096/tcp${NC}"
    fi

    press_enter

    # --- Remote Access Setup (Optional) ---
    write_banner
    echo -e "  ${MAGENTA}OPTIONAL: Watch Your Media From Anywhere${NC}"
    echo -e "  ${DARKGRAY}-----------------------------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Want to access your media outside your home (hotel, work, etc.)?${NC}"
    echo -e "  ${GRAY}Use a secure mesh network - NO port forwarding needed!${NC}"
    echo ""
    echo -e "  ${WHITE} RECOMMENDED: Tailscale (Free) ${NC}"
    echo ""
    echo -e "  ${YELLOW}On this computer:${NC}"
    echo -e "    ${WHITE}1. Download Tailscale: ${CYAN}https://tailscale.com/download${NC}"
    echo -e "    ${WHITE}2. Install and sign in (Google/Microsoft/etc.)${NC}"
    echo -e "    ${WHITE}3. Note your Tailscale IP (starts with 100.x.x.x)${NC}"
    echo ""
    echo -e "  ${YELLOW}On your phone/laptop:${NC}"
    echo -e "    ${WHITE}1. Install Tailscale app and sign in with same account${NC}"
    echo -e "    ${WHITE}2. Open Jellyfin/Emby app and connect to:${NC}"
    echo -e "       ${CYAN}http://100.x.x.x:8096${NC} ${GRAY}(use your actual Tailscale IP)${NC}"
    echo ""
    echo -e "  ${WHITE} WHY THIS IS SAFE ${NC}"
    echo ""
    echo -e "  ${GRAY}Tailscale creates an encrypted tunnel directly between your devices.${NC}"
    echo -e "  ${GRAY}Nothing is exposed to the internet - no hackers can find your server!${NC}"

    press_enter

    # --- Complete ---
    write_banner
    echo ""
    echo -e "  ${GREEN}=============================================${NC}"
    echo -e "       ${WHITE}PRIVACY BOX SETUP COMPLETE!${NC}"
    echo -e "  ${GREEN}=============================================${NC}"
    echo ""
    echo -e "  ${YELLOW}Your Services:${NC}"
    echo -e "    ${WHITE}qBittorrent:  http://localhost:8080${NC}"
    echo -e "    ${WHITE}Prowlarr:     http://localhost:8181${NC}"
    echo -e "    ${WHITE}Sonarr:       http://localhost:8989${NC}"
    echo -e "    ${WHITE}Radarr:       http://localhost:7878${NC}"
    echo -e "    ${CYAN}Jellyfin:     http://localhost:8096${NC} ${GRAY}(Media Server)${NC}"
    # Show optional services if they were enabled
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^sabnzbd$'; then
        echo -e "    ${WHITE}SABnzbd:      http://localhost:8085${NC} ${GRAY}(Usenet Downloads)${NC}"
    fi
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^lidarr$'; then
        echo -e "    ${WHITE}Lidarr:       http://localhost:8686${NC} ${GRAY}(Music Manager)${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}Your media folder:${NC}"
    echo -e "    ${GRAY}${SCRIPT_DIR}/media/${NC}"
    echo ""
    echo -e "  ${GREEN}Your media server is up and running!${NC}"
    echo ""
    echo -e "  ${DARKGRAY}=============================================${NC}"
    echo -e "  ${YELLOW}IS IT RUNNING?${NC}"
    echo -e "  ${DARKGRAY}=============================================${NC}"
    echo -e "  ${WHITE}Your Privacy Box is currently ${GREEN}RUNNING${WHITE}!${NC}"
    echo -e "  ${GRAY}It will keep running in the background.${NC}"
    echo ""
    echo -e "  ${YELLOW}Useful Commands (run from this folder):${NC}"
    echo -e "    ${GRAY}Start:   docker compose up -d${NC}"
    echo -e "    ${GRAY}Stop:    docker compose down${NC}"
    echo -e "    ${GRAY}Restart: docker compose restart${NC}"
    echo -e "    ${GRAY}Status:  docker ps${NC}"
    echo ""
    echo -e "  ${CYAN}=============================================${NC}"
    echo -e "  ${YELLOW}Created by TOM SPARK${NC}"
    echo -e "  ${WHITE}Subscribe: youtube.com/@TomSparkReviews${NC}"
    echo -e "  ${CYAN}=============================================${NC}"
    echo ""
    echo -e "  ${YELLOW}Questions? Join the Discord!${NC}"
    echo -e "  ${CYAN}https://discord.gg/uPdRcKxEVS${NC}"
    echo ""
}

# --- Bonus: Notifiarr Setup ---
setup_notifiarr() {
    write_banner
    echo -e "  ${MAGENTA}BONUS: Discord Notifications with Notifiarr${NC}"
    echo -e "  ${DARKGRAY}--------------------------------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Want Discord notifications when:${NC}"
    echo -e "    ${GRAY}- A movie/show starts downloading?${NC}"
    echo -e "    ${GRAY}- Downloads complete?${NC}"
    echo -e "    ${GRAY}- New episodes are available?${NC}"
    echo -e "    ${GRAY}- Something goes wrong?${NC}"
    echo ""
    echo -e "  ${CYAN}Notifiarr${NC} ${WHITE}sends beautiful notifications to your Discord server!${NC}"
    echo ""

    if ! ask_yes_no "Would you like to set up Discord notifications?"; then
        echo ""
        write_info "Skipping Notifiarr setup. You can enable it later!"
        echo ""
        echo -e "  ${GRAY}To enable later, run:${NC}"
        echo -e "    ${CYAN}docker compose --profile notifications up -d${NC}"
        return 0
    fi

    write_banner
    echo -e "  ${MAGENTA}STEP 1: Create Notifiarr Account${NC}"
    echo -e "  ${DARKGRAY}--------------------------------${NC}"
    echo ""
    echo -e "  ${WHITE}1. Go to ${CYAN}https://notifiarr.com${WHITE} and create a FREE account${NC}"
    echo -e "  ${WHITE}2. Sign in with Discord (recommended) or email${NC}"
    echo -e "  ${WHITE}3. Go to your Profile and copy your ${YELLOW}API Key${NC}"
    echo ""

    if ask_yes_no "Open Notifiarr.com in your browser now?"; then
        open_url "https://notifiarr.com"
        echo ""
        write_info "Browser opened. Create account, then copy your API Key."
        press_enter
    fi

    echo ""
    echo -e "  ${DARKGRAY}TIP: Ctrl+V may not paste here. Use right-click or Shift+Insert to paste.${NC}"
    echo ""
    echo -ne "  ${YELLOW}Paste your Notifiarr API Key: ${NC}"
    read -r NOTIFIARR_API_KEY

    if [[ -z "$NOTIFIARR_API_KEY" ]]; then
        write_error "No API key provided. Skipping Notifiarr."
        return 1
    fi

    # Add API key to .env
    echo "" >> "$SCRIPT_DIR/.env"
    echo "# --- NOTIFIARR (Discord Notifications) ---" >> "$SCRIPT_DIR/.env"
    echo "NOTIFIARR_API_KEY=\"$(sanitize_env_value "$NOTIFIARR_API_KEY")\"" >> "$SCRIPT_DIR/.env"

    write_success "API Key saved!"
    echo ""

    write_step "1" "Starting Notifiarr container..."
    cd "$SCRIPT_DIR" || exit 1
    docker compose --profile notifications up -d </dev/null 2>&1 | sed 's/^/      /'

    echo ""
    write_success "Notifiarr is running!"

    press_enter

    write_banner
    echo -e "  ${MAGENTA}STEP 2: Configure Notifiarr${NC}"
    echo -e "  ${DARKGRAY}---------------------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Notifiarr in your browser...${NC}"
    read -r
    open_url "http://localhost:5454"
    echo ""
    echo -e "  ${WHITE} LOGIN ${NC}"
    echo -e "    ${WHITE}Username: ${CYAN}admin${NC}"
    echo -e "    ${WHITE}Password: ${CYAN}(your API key)${NC}"
    echo ""
    echo -e "  ${WHITE} CONNECT YOUR APPS ${NC}"
    echo ""
    echo -e "  ${YELLOW}In Notifiarr web UI:${NC}"
    echo -e "    ${WHITE}1. Go to 'Starr Apps' in the menu${NC}"
    echo -e "    ${WHITE}2. Enable Radarr and add:${NC}"
    echo -e "       ${GRAY}- URL: ${CYAN}http://radarr:7878${NC}"
    echo -e "       ${GRAY}- API Key: ${CYAN}(from Radarr > Settings > General)${NC}"
    echo ""
    echo -e "    ${WHITE}3. Enable Sonarr and add:${NC}"
    echo -e "       ${GRAY}- URL: ${CYAN}http://sonarr:8989${NC}"
    echo -e "       ${GRAY}- API Key: ${CYAN}(from Sonarr > Settings > General)${NC}"
    echo ""
    echo -e "  ${YELLOW}On notifiarr.com website:${NC}"
    echo -e "    ${WHITE}1. Go to Integrations > Manage${NC}"
    echo -e "    ${WHITE}2. Enable Radarr/Sonarr integrations${NC}"
    echo -e "    ${WHITE}3. Set up your Discord channel for notifications${NC}"
    echo ""
    echo -e "  ${GREEN}That's it! You'll now get Discord notifications!${NC}"

    press_enter

    write_banner
    echo -e "  ${GREEN}=============================================${NC}"
    echo -e "       ${WHITE}NOTIFIARR SETUP COMPLETE!${NC}"
    echo -e "  ${GREEN}=============================================${NC}"
    echo ""
    echo -e "  ${YELLOW}Notifiarr Web UI:${NC} ${CYAN}http://localhost:5454${NC}"
    echo ""
    echo -e "  ${WHITE}Configure notifications at: ${CYAN}https://notifiarr.com${NC}"
    echo ""
}

# --- Bonus: FlareSolverr Setup ---
setup_flaresolverr() {
    write_banner
    echo -e "  ${MAGENTA}BONUS: Cloudflare Bypass with FlareSolverr${NC}"
    echo -e "  ${DARKGRAY}-------------------------------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Some indexers are protected by Cloudflare anti-bot challenges.${NC}"
    echo -e "  ${WHITE}FlareSolverr runs a headless browser to solve these automatically,${NC}"
    echo -e "  ${WHITE}so Prowlarr can access protected indexers without manual intervention.${NC}"
    echo ""

    if ! ask_yes_no "Would you like to enable FlareSolverr?"; then
        echo ""
        write_info "Skipping FlareSolverr setup. You can enable it later!"
        echo ""
        echo -e "  ${GRAY}To enable later, run:${NC}"
        echo -e "    ${CYAN}docker compose --profile flaresolverr up -d${NC}"
        return 0
    fi

    echo ""
    write_step "1" "Starting FlareSolverr container..."
    cd "$SCRIPT_DIR" || exit 1
    docker compose --profile flaresolverr up -d </dev/null 2>&1 | sed 's/^/      /'

    echo ""
    write_success "FlareSolverr is running!"
    echo ""
    echo -e "  ${YELLOW}Configure FlareSolverr in Prowlarr:${NC}"
    echo -e "    ${WHITE}1. Open Prowlarr: ${CYAN}http://localhost:8181${NC}"
    echo -e "    ${WHITE}2. Go to: Settings > Indexers${NC}"
    echo -e "    ${WHITE}3. Click '+' under 'Indexer Proxies'${NC}"
    echo -e "    ${WHITE}4. Select 'FlareSolverr'${NC}"
    echo -e "    ${WHITE}5. Set Host to: ${CYAN}http://flaresolverr:8191${NC}"
    echo -e "    ${WHITE}6. Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${GREEN}Prowlarr will now automatically bypass Cloudflare challenges!${NC}"

    press_enter
}

# --- Bonus: SABnzbd Setup ---
setup_sabnzbd() {
    write_banner
    echo -e "  ${MAGENTA}BONUS: Usenet Downloads with SABnzbd${NC}"
    echo -e "  ${DARKGRAY}-------------------------------------${NC}"
    echo ""
    echo -e "  ${WHITE}SABnzbd is a Usenet download client — an alternative to torrents.${NC}"
    echo -e "  ${WHITE}Usenet downloads are SSL-encrypted and typically faster.${NC}"
    echo -e "  ${WHITE}You'll need a Usenet provider subscription (e.g., Newshosting, Eweka).${NC}"
    echo ""

    if ! ask_yes_no "Would you like to enable Usenet downloads (SABnzbd)?"; then
        echo ""
        write_info "Skipping SABnzbd setup. You can enable it later!"
        echo ""
        echo -e "  ${GRAY}To enable later, run:${NC}"
        echo -e "    ${CYAN}docker compose --profile sabnzbd up -d${NC}"
        return 0
    fi

    echo ""
    write_step "1" "Starting SABnzbd container..."
    cd "$SCRIPT_DIR" || exit 1
    docker compose --profile sabnzbd up -d </dev/null 2>&1 | sed 's/^/      /'

    echo ""
    write_success "SABnzbd is running!"

    press_enter

    write_banner
    echo -e "  ${MAGENTA}Configure SABnzbd${NC}"
    echo -e "  ${DARKGRAY}-----------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open SABnzbd in your browser...${NC}"
    read -r
    open_url "http://localhost:8085"
    echo ""
    echo -e "  ${WHITE}1. Follow the SABnzbd Quick-Start Wizard${NC}"
    echo ""
    echo -e "  ${YELLOW}2. Add your Usenet provider:${NC}"
    echo -e "     ${WHITE}- Host: ${CYAN}(from your Usenet provider, e.g., news.newshosting.com)${NC}"
    echo -e "     ${WHITE}- Port: ${CYAN}563${NC} ${GRAY}(SSL)${NC}"
    echo -e "     ${WHITE}- Username & Password: ${CYAN}(your Usenet account credentials)${NC}"
    echo -e "     ${WHITE}- SSL: ${CYAN}Yes${NC}"
    echo ""
    echo -e "  ${YELLOW}3. Use SABnzbd as a download client in Sonarr/Radarr/Lidarr:${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Download Clients${NC}"
    echo -e "     ${WHITE}- Click '+' and select 'SABnzbd'${NC}"
    echo -e "     ${WHITE}- Host: ${CYAN}sabnzbd${NC}"
    echo -e "     ${WHITE}- Port: ${CYAN}8080${NC}"
    echo -e "     ${WHITE}- API Key: ${CYAN}(from SABnzbd > Config > General)${NC}"
    echo -e "     ${WHITE}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${GREEN}SABnzbd is ready for Usenet downloads!${NC}"

    press_enter
}

# --- Bonus: Lidarr Setup ---
setup_lidarr() {
    write_banner
    echo -e "  ${MAGENTA}BONUS: Music Management with Lidarr${NC}"
    echo -e "  ${DARKGRAY}------------------------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Lidarr automatically finds, downloads, and organizes music.${NC}"
    echo -e "  ${WHITE}It works just like Sonarr/Radarr but for music albums and artists.${NC}"
    echo -e "  ${WHITE}Your music will be available in Jellyfin for streaming!${NC}"
    echo ""

    if ! ask_yes_no "Would you like to enable music management (Lidarr)?"; then
        echo ""
        write_info "Skipping Lidarr setup. You can enable it later!"
        echo ""
        echo -e "  ${GRAY}To enable later, run:${NC}"
        echo -e "    ${CYAN}docker compose --profile lidarr up -d${NC}"
        return 0
    fi

    echo ""
    write_step "1" "Starting Lidarr container..."
    cd "$SCRIPT_DIR" || exit 1
    docker compose --profile lidarr up -d </dev/null 2>&1 | sed 's/^/      /'

    echo ""
    write_success "Lidarr is running!"

    press_enter

    write_banner
    echo -e "  ${MAGENTA}Configure Lidarr${NC}"
    echo -e "  ${DARKGRAY}----------------${NC}"
    echo ""
    echo -e "  ${YELLOW}Press ENTER to open Lidarr in your browser...${NC}"
    read -r
    open_url "http://localhost:8686"
    echo ""
    echo -e "  ${WHITE}1. Create your admin account when prompted${NC}"
    echo ""
    echo -e "  ${YELLOW}2. Add Root Folder (where music is saved):${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Media Management${NC}"
    echo -e "     ${WHITE}- Scroll down and click 'Add Root Folder'${NC}"
    echo -e "     ${WHITE}- Enter path: ${CYAN}/data/media/music${NC}"
    echo -e "     ${WHITE}- Click 'OK'${NC}"
    echo ""
    echo -e "  ${YELLOW}3. Add Download Client:${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Download Clients${NC}"
    echo -e "     ${WHITE}- Click '+' and select 'qBittorrent'${NC}"
    echo -e "     ${WHITE}- Host: ${CYAN}qbittorrent${NC}"
    echo -e "     ${WHITE}- Port: ${CYAN}8080${NC}"
    echo -e "     ${WHITE}- Username: ${CYAN}admin${NC}"
    echo -e "     ${WHITE}- Password: ${CYAN}(your qBittorrent password)${NC}"
    echo -e "     ${WHITE}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${YELLOW}4. Copy your API Key (for Prowlarr):${NC}"
    echo -e "     ${WHITE}- Go to: Settings > General${NC}"
    echo -e "     ${WHITE}- Copy the 'API Key'${NC}"
    echo ""
    echo -e "  ${YELLOW}5. Connect in Prowlarr:${NC}"
    echo -e "     ${WHITE}- Open Prowlarr: ${CYAN}http://localhost:8181${NC}"
    echo -e "     ${WHITE}- Go to: Settings > Apps${NC}"
    echo -e "     ${WHITE}- Click '+' and select 'Lidarr'${NC}"
    echo -e "     ${WHITE}- Prowlarr Server: ${CYAN}http://prowlarr:9696${NC}"
    echo -e "     ${WHITE}- Lidarr Server: ${CYAN}http://lidarr:8686${NC}"
    echo -e "     ${WHITE}- API Key: ${CYAN}(paste the Lidarr API key)${NC}"
    echo -e "     ${WHITE}- Click 'Test' then 'Save'${NC}"
    echo ""
    echo -e "  ${GREEN}Lidarr is ready! Add artists and let it find your music.${NC}"

    press_enter
}

# --- Main Execution ---
main() {
    write_banner

    # Pre-flight checks
    if ! test_docker_installed; then
        press_enter
        exit 1
    fi

    if ! test_docker_running; then
        press_enter
        exit 1
    fi

    write_success "Pre-flight checks passed!"
    press_enter

    # Experience level selection
    get_experience_level
    show_arr_overview

    # Collect configuration
    get_timezone

    # Confirmation
    write_banner
    echo -e "  ${MAGENTA}CONFIGURATION SUMMARY${NC}"
    echo -e "  ${DARKGRAY}---------------------${NC}"
    echo ""
    echo -e "  ${WHITE}Install Path:    ${SCRIPT_DIR}${NC}"
    echo -e "  ${WHITE}Timezone:        ${TIMEZONE}${NC}"
    echo ""

    if ! ask_yes_no "Proceed with installation?"; then
        echo ""
        write_info "Installation cancelled."
        exit 0
    fi

    # Create directory structure
    write_banner
    echo -e "  ${MAGENTA}CREATING FILES${NC}"
    echo -e "  ${DARKGRAY}--------------${NC}"
    echo ""

    write_step "1" "Creating directories..."
    mkdir -p "$SCRIPT_DIR/config"
    mkdir -p "$SCRIPT_DIR/media/downloads"
    mkdir -p "$SCRIPT_DIR/media/tv"
    mkdir -p "$SCRIPT_DIR/media/movies"
    mkdir -p "$SCRIPT_DIR/media/music"
    write_success "Directories created"

    write_step "2" "Generating .env file..."
    create_env_file
    chmod 600 "$SCRIPT_DIR/.env"
    write_success ".env file created (permissions restricted)"

    press_enter

    # Launch
    if start_privacy_box; then
        press_enter
        show_setup_guide
        setup_notifiarr
        setup_flaresolverr
        setup_sabnzbd
        setup_lidarr
    else
        echo ""
        write_error "Setup failed. The containers did not all start."
        echo ""
        echo -e "  ${YELLOW}Common fixes:${NC}"
        echo -e "    ${WHITE}1. Check Docker is running and has enough disk space${NC}"
        echo -e "    ${WHITE}2. Make sure ports 8080, 8181, 8989, 7878, 8096 and 6881 are free${NC}"
        echo -e "    ${WHITE}3. See what went wrong: ${CYAN}docker compose logs --tail 50${NC}"
        echo ""
        echo -e "  ${GRAY}To retry, run this script again.${NC}"
    fi
}

# Run
main
