# ThirtyOS — Custom Armbian for HG680P STB

**ThirtyOS** is a customized Armbian-based OS for the **HG680P** Android TV box (Amlogic S905X), built for lightweight home server use: bots, AI coding assistant, media server, retro gaming, Cloudflare tunnel, and more.

> Created by [@ahdikhfDev](https://github.com/ahdikhfDev)

---

## Features

- **Lightweight** — stripped of bloat, optimized for 1.8 GB RAM
- **ZRAM swap** (lz4, 50% of RAM) — no swap file needed
- **tmpfs /tmp** — logs & temp in RAM, reduces SSD wear
- **System optimizations** — disables unused services (bluetooth, avahi, ModemManager, apt-daily)
- **Auto-update** — `thirtyos-install` updates itself from GitHub, no re-flash needed
- **AI stack** — 9Router + OpenCode headless with free AI providers ($0/month)
- **One CLI tool** — `thirtyos-install` manages everything

---

## Quick Start

### Option 1: Flash ThirtyOS Image (recommended)

```bash
# Download image from Releases
gunzip ThirtyOS_v1.0.0_HG680P.img.gz

# Flash to SD/USB/SSD
sudo dd if=ThirtyOS_v1.0.0_HG680P.img of=/dev/sdX bs=4M status=progress conv=fsync

# Resize partition after flash
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2
sudo resize2fs /dev/sdX2
```

> **Warning:** This erases ALL data on the target device.

### Option 2: One-Liner Install (any Armbian/Debian)

If you already have Armbian running on your HG680P:

```bash
sudo curl -fsSL -o /usr/local/bin/thirtyos-install https://raw.githubusercontent.com/ahdikhfDev/ThirtyOS-tools/main/thirtyos-install && sudo chmod +x /usr/local/bin/thirtyos-install
```

Then follow the first-boot guide below.

---

## First Boot

1. Boot from SD/USB/SSD on HG680P
2. Login (default: `root` / `1234`)
3. Create a user when prompted

```bash
# 1. First-time setup (hostname, timezone, user)
thirtyos-install setup

# 2. Install packages (Node.js, Docker, PM2)
thirtyos-install prepare

# 3. Optimize system (ZRAM, journal, swappiness, etc)
thirtyos-install optimize

# 4. Install services you want (see command reference below)
```

---

## Command Reference

### `thirtyos-install setup`
First-run wizard. Sets hostname, timezone, creates user.
```bash
thirtyos-install setup
```

### `thirtyos-install prepare`
Installs core packages: Node.js 20, Docker, PM2, build tools.
```bash
thirtyos-install prepare
```

### `thirtyos-install optimize`
8-step system optimization for low-RAM devices:
1. Fix & enable ZRAM swap (lz4, 50% RAM)
2. Move journal to RAM (volatile, 50 MB max)
3. Set swappiness to 10
4. Set IO scheduler to `none` (SSD)
5. Set CPU governor to `schedutil`
6. Optionally disable NetworkManager
7. Clean apt cache & orphan packages
8. Disable unused services (bluetooth, cups, avahi, etc)
```bash
thirtyos-install optimize
```

### `thirtyos-install ai`
AI coding assistant stack — **$0/month**. Installs 9Router (AI gateway) + OpenCode (headless AI agent).

Architecture:
```
Laptop/Phone
    ↓ SSH tunnel or Cloudflare
STB ThirtyOS
    ├── OpenCode (headless)
    │       ↓ localhost:20128/v1
    └── 9Router (AI Gateway)
            ↓ auto-fallback
    ┌──────────────────────────┐
    │ Kiro AI (Claude 4.5)     │ ← unlimited free
    │ OpenCode Free            │ ← no auth
    │ iFlow                    │ ← no auth
    │ Qwen                     │ ← no auth
    └──────────────────────────┘
```

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `ai setup` | Install & configure 9Router + OpenCode + systemd service |
| `ai status` | Show AI services status |
| `ai update` | Update 9Router & OpenCode to latest |
| `ai tunnel` | Expose AI dashboard via Cloudflare Tunnel |

**Usage:**
```bash
# Install everything
thirtyos-install ai setup

# Use on STB directly
opencode

# From laptop via SSH tunnel
ssh -L 20128:localhost:20128 thirty@<ip-stb>
# Open http://localhost:20128/dashboard

# From anywhere via Cloudflare
thirtyos-install ai tunnel
# Access https://ai.yourdomain.com/dashboard
```

### `thirtyos-install bot-wa`
Install or update WhatsApp bot (Baileys-based).
```bash
thirtyos-install bot-wa
```

### `thirtyos-install tunnel`
Setup Cloudflare Tunnel for remote access.
```bash
thirtyos-install tunnel
```

### `thirtyos-install panel`
Install web panel: CasaOS or Portainer.
```bash
thirtyos-install panel
```

### `thirtyos-install media`
Install Homeflix media server (stream movies/series).
```bash
thirtyos-install media
```

### `thirtyos-install retro`
Install RetroArch with emulator cores (NES, SNES, PS1, N64, etc).
```bash
thirtyos-install retro
```

### `thirtyos-install wifi`
Scan and connect to WiFi networks (uses NMCLI).
```bash
thirtyos-install wifi
```

### `thirtyos-install update`
Update everything — APT packages, NPM globals, thirtyos-install itself.
```bash
thirtyos-install update
```

No re-flash needed. `thirtyos-install` auto-downloads the latest version from GitHub.

### `thirtyos-install status`
Show system & service status overview.
```bash
thirtyos-install status
```

### `thirtyos-install uninstall`
Remove installed services (bot-wa, panel, media, etc).
```bash
thirtyos-install uninstall
```

### `thirtyos-install version`
Show ThirtyOS version info.
```bash
thirtyos-install version
```

---

## Build Your Own Image

### Prerequisites (on Kali/Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y qemu-user-static parted e2fsprogs curl
```

### Build

```bash
git clone https://github.com/ahdikhfDev/ThirtyOS-tools.git
cd ThirtyOS-tools

# Download Armbian base image:
# https://www.armbian.com/amlogic-s905x/

sudo bash customize-image.sh Armbian_*.img.gz
```

Output: `ThirtyOS_v1.0.0_HG680P.img.gz`

### Customize the Build

Edit `customize-image.sh` to add/remove packages or change configs, then rebuild.

---

## Repository Structure

```
ThirtyOS-tools/
├── customize-image.sh    # Build script (run on laptop/PC)
├── thirtyos-install      # CLI tool (runs on STB, bundled in image)
└── README.md             # This file
```

---

## License

MIT License

Copyright (c) 2026 Ahdi Khalida Fathir

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

## Credits

- [Armbian](https://www.armbian.com/) — base OS
- [Homeflix](https://github.com/xebadir/homeflix) — media server
- [RetroArch](https://www.retroarch.com/) — emulator
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) — secure tunneling
- [9Router](https://www.npmjs.com/package/9router) — AI gateway
- [OpenCode](https://opencode.ai/) — AI coding agent

---

## Issues & Feedback

Report issues at: https://github.com/ahdikhfDev/ThirtyOS-tools/issues
