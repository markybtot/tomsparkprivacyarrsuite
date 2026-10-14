#!/bin/bash
# ============================================================
# PRIVACY BOX - Web Installer for Mac/Linux
# Created by Tom Spark | https://youtube.com/@TomSparkReviews
#
# No-VPN edition. Run with:
#   curl -fsSL https://raw.githubusercontent.com/markybtot/tomsparkprivacyarrsuite/main/install.sh | bash
#
# To install from a different repo or branch without editing this file:
#   curl -fsSL <url-to-this-file> | PRIVACYBOX_REPO=owner/repo PRIVACYBOX_BRANCH=main bash
# ============================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

REPO="${PRIVACYBOX_REPO:-markybtot/tomsparkprivacyarrsuite}"
BRANCH="${PRIVACYBOX_BRANCH:-main}"
REPO_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.zip"
INSTALL_DIR="$HOME/Desktop/PrivacyServer"

echo ""
echo -e "${CYAN}=====================================================${NC}"
echo -e "${WHITE}       PRIVACY BOX - Web Installer${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo -e "${YELLOW}       Created by TOM SPARK${NC}"
echo -e "${WHITE}       No-VPN edition${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo ""

# Check for required tools
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo -e "${YELLOW}[!]${NC} curl or wget is required. Please install one first."
    exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}[!]${NC} unzip is required. Please install it first."
    echo "    Ubuntu/Debian: sudo apt install unzip"
    echo "    macOS: brew install unzip (or it should be pre-installed)"
    exit 1
fi

# Create Desktop directory if it doesn't exist (some Linux distros)
mkdir -p "$HOME/Desktop"

# Download
echo -e "${WHITE}[1/4]${NC} Downloading Privacy Box..."
TEMP_ZIP=$(mktemp)
if command -v curl &> /dev/null; then
    curl -fsSL "$REPO_URL" -o "$TEMP_ZIP"
else
    wget -q "$REPO_URL" -O "$TEMP_ZIP"
fi

# Extract
echo -e "${WHITE}[2/4]${NC} Extracting files..."
TEMP_DIR=$(mktemp -d)
unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"

# Move to final location
echo -e "${WHITE}[3/4]${NC} Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR" 2>/dev/null || true
EXTRACTED_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
if [[ -z "$EXTRACTED_DIR" || ! -f "$EXTRACTED_DIR/setup.sh" ]]; then
    echo -e "${YELLOW}[!]${NC} Download did not contain setup.sh. Check the repo: ${REPO} (${BRANCH})"
    exit 1
fi
mv "$EXTRACTED_DIR" "$INSTALL_DIR"

# Cleanup
rm -f "$TEMP_ZIP"
rm -rf "$TEMP_DIR"

# Make setup script executable
chmod +x "$INSTALL_DIR/setup.sh"

echo -e "${WHITE}[4/4]${NC} Done!"
echo ""
echo -e "${GREEN}=====================================================${NC}"
echo -e "${WHITE}       Installation Complete!${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo ""
echo -e "${WHITE}To start the setup, run:${NC}"
echo ""
echo -e "    ${CYAN}cd ~/Desktop/PrivacyServer && ./setup.sh${NC}"
echo ""
echo -e "${YELLOW}Or I can start it for you now.${NC}"
echo ""

# Ask to run setup
read -p "Start setup now? (Y/n): " -n 1 -r </dev/tty
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cd "$INSTALL_DIR"
    ./setup.sh </dev/tty
fi
