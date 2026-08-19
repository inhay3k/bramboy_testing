# BramBoy OS Management Tool

A fast, lightweight, browser-based operating system management tool designed for Debian, Ubuntu, and all major Linux distributions. Built with Go, BramBoy provides real-time system monitoring, file management, terminal multiplexing, cron persistence, and API gateway access control without heavy dependencies or container runtimes.

---

## 🚀 Quick Install (Recommended One-Liner)

Install and run BramBoy on any supported Linux system with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/inhay3k/bramboy_testing/main/install.sh | bash
```

### What the installer automatically does:
1. **Detects CPU Architecture**: Inspects system architecture (`amd64`, `arm64`, `arm`, `386`, `riscv64`, `ppc64le`, `s390x`).
2. **Installs Missing Packages**: Auto-detects your package manager (`apt-get`, `dnf`, `yum`, `apk`, `pacman`, `zypper`) and installs required utilities (`tmux`, `cron`, `unzip`, `curl`, `git`).
3. **Configures Permissions**: Makes binaries executable and sets up the `os-management-tool` symlink.
4. **Registers Auto-Persistence**: Automatically schedules `@reboot` in `crontab` so BramBoy starts automatically whenever the server boots.
5. **Launches BramBoy**: Runs the daemon in the background on port `5003` (`http://localhost:5003`).

---

## 📦 Manual Installation Options

### Option 1: Clone Repository & Run Installer
```bash
# 1. Clone the repository
git clone https://github.com/inhay3k/bramboy_testing.git
cd bramboy_testing

# 2. Make installer executable and run
chmod +x install.sh
./install.sh
```

### Option 2: Run Target Binary Directly
If you already have required system packages (`tmux`, `cron`, `unzip`) installed:

```bash
# 1. Clone or download repository
git clone https://github.com/inhay3k/bramboy_testing.git
cd bramboy_testing

# 2. Make the binary for your architecture executable:
# For Intel / AMD 64-bit:
chmod +x os-management-tool-amd64
./os-management-tool-amd64

# For ARM 64-bit (Raspberry Pi 4/5, AWS Graviton, Apple Silicon VMs):
chmod +x os-management-tool-arm64
./os-management-tool-arm64

# For ARM 32-bit (Raspberry Pi 2/3 32-bit):
chmod +x os-management-tool-arm
./os-management-tool-arm
```

---

## 🖥️ Supported CPU Architectures

All binaries are compiled statically (`CGO_ENABLED=0`) with embedded UI assets and zero runtime shared-library dependencies.

| Architecture | Platform / Hardware | Binary Name |
| :--- | :--- | :--- |
| **x86_64 / amd64** | Intel / AMD 64-bit servers, PCs, VMs | `os-management-tool` / `os-management-tool-amd64` |
| **aarch64 / arm64** | ARM 64-bit (AWS Graviton, Raspberry Pi 4/5 64-bit, Apple Silicon Docker) | `os-management-tool-arm64` |
| **armv7 / armhf / arm** | ARM 32-bit (Raspberry Pi 2/3 32-bit, embedded Linux) | `os-management-tool-arm` |
| **i386 / i686 / x86** | Legacy Intel / AMD 32-bit x86 | `os-management-tool-386` |
| **riscv64** | RISC-V 64-bit (SiFive, StarFive, Milk-V) | `os-management-tool-riscv64` |
| **ppc64le** | OpenPOWER / PowerPC 64-bit Little Endian | `os-management-tool-ppc64le` |
| **s390x** | IBM Z / LinuxONE 64-bit Mainframes | `os-management-tool-s390x` |

---

## 🛠️ System Requirements & Backend Dependencies

BramBoy uses standard open-source Linux utilities. The installer automatically installs any missing dependencies:

| Tool | Purpose |
| :--- | :--- |
| **`tmux`** | Multiplexing background terminal sessions & PTY streaming |
| **`cron` / `cronie`** | System `@reboot` auto-persistence & cronjob management |
| **`unzip`** | In-place archive extraction in the web File Explorer |
| **`curl`** | Network communications |
| **`git`** | Repository cloning & updates |

---

## 🌐 First-Launch Setup

1. **Access Web UI**: Open `http://<your-server-ip>:5003` (or `http://localhost:5003`) in your browser.
2. **Step 1 - API Key Verification**: Enter your BramBoy API Key.
3. **Step 2 - Passkey Setup**: Choose and confirm your master access passkey.
4. **Dashboard**: Manage system resources, open terminal sessions, edit files, and schedule cronjobs.

---

## ⚙️ Configuration & Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PORT` | `5003` | HTTP listening port (e.g. `PORT=8080 ./os-management-tool`) |

---

## 🔧 Managing the BramBoy Service

```bash
# Check if BramBoy is running
ps aux | grep os-management-tool

# View live application logs
tail -f app.log

# Verify @reboot auto-start entry in crontab
crontab -l

# Stop BramBoy
pkill -f os-management-tool

# Start BramBoy in the background manually
nohup ./os-management-tool > app.log 2>&1 &
```
