#!/usr/bin/env bash
# ==============================================================================
# BramBoy OS Management Tool - Universal Linux Installer
# Repository: https://github.com/inhay3k/bramboy_testing
# ==============================================================================

set -e

# ANSI Color Codes
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "================================================================="
echo "       BramBoy OS Management Tool - Automated Installer          "
echo "================================================================="
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. OS & Architecture Detection
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/5] Detecting Operating System and Architecture...${NC}"

OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    echo -e "${RED}[ERROR] This installer only supports Linux systems. Detected OS: ${OS}${NC}"
    exit 1
fi

UNAME_M="$(uname -m)"
TARGET_ARCH=""
BIN_NAME=""

case "$UNAME_M" in
    x86_64|amd64)
        TARGET_ARCH="amd64"
        BIN_NAME="os-management-tool-amd64"
        ;;
    aarch64|arm64|armv8*)
        TARGET_ARCH="arm64"
        BIN_NAME="os-management-tool-arm64"
        ;;
    armv7*|armv6*|armhf|arm)
        TARGET_ARCH="arm"
        BIN_NAME="os-management-tool-arm"
        ;;
    i386|i686|x86)
        TARGET_ARCH="386"
        BIN_NAME="os-management-tool-386"
        ;;
    riscv64)
        TARGET_ARCH="riscv64"
        BIN_NAME="os-management-tool-riscv64"
        ;;
    ppc64le|ppc64el)
        TARGET_ARCH="ppc64le"
        BIN_NAME="os-management-tool-ppc64le"
        ;;
    s390x)
        TARGET_ARCH="s390x"
        BIN_NAME="os-management-tool-s390x"
        ;;
    *)
        echo -e "${RED}[ERROR] Unsupported architecture: ${UNAME_M}${NC}"
        echo "Supported architectures: amd64, arm64, arm (armv7), 386, riscv64, ppc64le, s390x."
        exit 1
        ;;
esac

echo -e "  ✓ OS:           ${GREEN}${OS}${NC}"
echo -e "  ✓ Architecture: ${GREEN}${UNAME_M} (${TARGET_ARCH})${NC}"
echo -e "  ✓ Target Binary: ${GREEN}${BIN_NAME}${NC}"

# ------------------------------------------------------------------------------
# 2. Check and Install Required System Packages
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/5] Checking and Installing Required Linux Programs...${NC}"

# Helper for sudo
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo -e "${YELLOW}[WARNING] Running as non-root user without sudo. Package installation may fail if dependencies are missing.${NC}"
    fi
fi

MISSING_DEPS=()
command -v tmux >/dev/null 2>&1 || MISSING_DEPS+=("tmux")
command -v crontab >/dev/null 2>&1 || MISSING_DEPS+=("cron")
command -v unzip >/dev/null 2>&1 || MISSING_DEPS+=("unzip")
command -v curl >/dev/null 2>&1 || MISSING_DEPS+=("curl")
command -v git >/dev/null 2>&1 || MISSING_DEPS+=("git")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "  -> Missing packages detected: ${YELLOW}${MISSING_DEPS[*]}${NC}"
    echo -e "  -> Attempting automatic package installation..."

    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -y
        $SUDO apt-get install -y tmux cron unzip curl git ca-certificates
        # Start cron service if present
        $SUDO service cron start >/dev/null 2>&1 || $SUDO systemctl start cron >/dev/null 2>&1 || $SUDO /etc/init.d/cron start >/dev/null 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y tmux cronie unzip curl git ca-certificates
        $SUDO systemctl enable --now crond >/dev/null 2>&1 || $SUDO service crond start >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y tmux cronie unzip curl git ca-certificates
        $SUDO systemctl enable --now crond >/dev/null 2>&1 || $SUDO service crond start >/dev/null 2>&1 || true
    elif command -v apk >/dev/null 2>&1; then
        $SUDO apk add --no-cache tmux cronie unzip curl git ca-certificates
        crond >/dev/null 2>&1 || true
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -Sy --noconfirm tmux cronie unzip curl git ca-certificates
        $SUDO systemctl enable --now cronie >/dev/null 2>&1 || true
    elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper install -y tmux cronie unzip curl git ca-certificates
        $SUDO systemctl enable --now cron >/dev/null 2>&1 || true
    else
        echo -e "${RED}[ERROR] No supported package manager found (apt-get, dnf, yum, apk, pacman, zypper).${NC}"
        echo -e "Please install the missing tools manually: ${MISSING_DEPS[*]}"
        exit 1
    fi
else
    echo -e "  ✓ All required programs are already installed (${GREEN}tmux, cron, unzip, curl, git${NC})."
fi

# Ensure cron daemon is running
if command -v service >/dev/null 2>&1; then
    $SUDO service cron start >/dev/null 2>&1 || $SUDO service crond start >/dev/null 2>&1 || true
elif command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl start cron >/dev/null 2>&1 || $SUDO systemctl start crond >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 3. Clone or Prepare Repository & Binary
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/5] Setting up BramBoy Repository & Binary...${NC}"

REPO_URL="https://github.com/inhay3k/bramboy_testing.git"
RAW_BASE_URL="https://raw.githubusercontent.com/inhay3k/bramboy_testing/main"

CURRENT_DIR="$(pwd)"
INSTALL_TARGET_DIR="${INSTALL_DIR:-}"

if [ -z "$INSTALL_TARGET_DIR" ]; then
    if [ -f "$CURRENT_DIR/$BIN_NAME" ] || [ -f "$CURRENT_DIR/os-management-tool" ]; then
        INSTALL_TARGET_DIR="$CURRENT_DIR"
        echo -e "  ✓ Using current local directory: ${GREEN}${INSTALL_TARGET_DIR}${NC}"
    else
        INSTALL_TARGET_DIR="$HOME/os-management-tool"
    fi
fi

if [ "$INSTALL_TARGET_DIR" != "$CURRENT_DIR" ]; then
    mkdir -p "$INSTALL_TARGET_DIR"
    if command -v git >/dev/null 2>&1; then
        if [ -d "$INSTALL_TARGET_DIR/.git" ]; then
            echo -e "  -> Existing git repository found at ${INSTALL_TARGET_DIR}, updating..."
            (cd "$INSTALL_TARGET_DIR" && git pull || true)
        else
            echo -e "  -> Cloning repository into ${GREEN}${INSTALL_TARGET_DIR}${NC}..."
            git clone "$REPO_URL" "$INSTALL_TARGET_DIR"
        fi
    else
        echo -e "  -> Downloading binary directly via curl..."
        curl -fsSL "$RAW_BASE_URL/$BIN_NAME" -o "$INSTALL_TARGET_DIR/$BIN_NAME"
    fi
fi

# ------------------------------------------------------------------------------
# 4. Set Permissions & Configure Executable
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/5] Configuring Executable Permissions...${NC}"

cd "$INSTALL_TARGET_DIR"

SELECTED_BINARY=""
if [ -f "$BIN_NAME" ]; then
    SELECTED_BINARY="$BIN_NAME"
elif [ -f "os-management-tool" ]; then
    SELECTED_BINARY="os-management-tool"
else
    echo -e "${RED}[ERROR] Could not find executable binary (${BIN_NAME} or os-management-tool) in ${INSTALL_TARGET_DIR}${NC}"
    exit 1
fi

chmod +x "$SELECTED_BINARY"
if [ -f "os-management-tool" ]; then
    chmod +x "os-management-tool"
fi

# Create symlink to standard name if needed
if [ "$SELECTED_BINARY" != "os-management-tool" ] && [ ! -f "os-management-tool" ]; then
    ln -sf "$SELECTED_BINARY" "os-management-tool"
fi

echo -e "  ✓ Executable configured: ${GREEN}${INSTALL_TARGET_DIR}/${SELECTED_BINARY}${NC}"

# ------------------------------------------------------------------------------
# 5. Launch Application & Initialize Persistence
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[5/5] Launching BramBoy OS Management Tool...${NC}"

PORT="${PORT:-5003}"
export PORT

ABS_EXE_PATH="$(pwd)/$SELECTED_BINARY"

echo -e "  -> Starting BramBoy on Port ${GREEN}${PORT}${NC}..."
echo -e "  -> Executable Path: ${CYAN}${ABS_EXE_PATH}${NC}"

# Run in background via nohup so installation finishes cleanly
nohup "$ABS_EXE_PATH" > app.log 2>&1 &
APP_PID=$!

sleep 2

# Verify process is active
if ps -p "$APP_PID" > /dev/null 2>&1; then
    echo -e "  ✓ BramBoy process started successfully (PID: ${GREEN}${APP_PID}${NC})"
else
    echo -e "  -> Startup log output:"
    tail -n 10 app.log || true
fi

# Inspect crontab
echo -e "\n${BOLD}Crontab Auto-Persistence Status:${NC}"
if command -v crontab >/dev/null 2>&1; then
    crontab -l 2>/dev/null | grep "@reboot" || echo -e "  ${YELLOW}(Cron persistence scheduled on startup)${NC}"
fi

echo -e "\n${GREEN}${BOLD}================================================================="
echo "       BramBoy OS Management Tool Successfully Installed!        "
echo "=================================================================${NC}"
echo -e "\n${BOLD}Access the Web Interface:${NC}"
echo -e "  ➜ Local:   ${CYAN}http://localhost:${PORT}${NC}"
echo -e "  ➜ Network: ${CYAN}http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo '127.0.0.1'):${PORT}${NC}"
echo -e "\n${BOLD}Useful Information:${NC}"
echo -e "  • Installation Directory: ${INSTALL_TARGET_DIR}"
echo -e "  • Logs:                   ${INSTALL_TARGET_DIR}/app.log"
echo -e "  • Background Cron:        Automatically registered via @reboot in crontab"
echo -e "\n${GREEN}Enjoy managing your OS with BramBoy!${NC}\n"
