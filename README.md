# ThirtyOS — Custom Armbian for HG680P STB 🚀

**ThirtyOS** is a customized Armbian-based operating system for the **HG680P** Android TV box (Amlogic S905X).  
Built for lightweight server use: bots, tunnels, media servers, retro emulation, and more.

> Created by [@ahdikhfDev](https://github.com/ahdikhfDev)

---

## 📦 Features

- **Lightweight** — stripped of bloat, optimized for RAM & storage
- **ZRAM swap** (lz4, 50% of RAM) — no swap file needed
- **tmpfs /tmp** — logs & temp in RAM, reduces SSD wear
- **Systemd optimizations** — disables unused services (bluetooth, avahi, ModemManager, apt-daily)
- **Timezone Asia/Jakarta** — preset, changeable via `thirtyos-install setup`
- **Custom MOTD** — shows system info on login

### Built-in CLI: `thirtyos-install`

| Command | Description |
|---------|-------------|
| `setup` | First-run wizard (hostname, IP, user) |
| `prepare` | Install Node.js, Docker, PM2, system deps |
| `optimize` | One-click system optimization |
| `wifi` | Scan & connect WiFi networks |
| `bot-wa` | Install/update WhatsApp bot |
| `tunnel` | Setup Cloudflare Tunnel |
| `panel` | Install CasaOS or Portainer |
| `media` | Install Homeflix media server |
| `retro` | Install RetroArch + emulator cores |
| `update` | Full system + tool update |
| `status` | Show system & service status |
| `uninstall` | Remove installed services |
| `version` | Show ThirtyOS version info |

---

## 🔧 Build Your Own Image

### Prerequisites (on Kali/Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y qemu-user-static parted e2fsprogs curl
```

### Build

```bash
git clone https://github.com/ahdikhfDev/ThirtyOS-tools.git
cd ThirtyOS-tools

# Download Armbian image for S905X:
# https://www.armbian.com/amlogic-s905x/

sudo bash customize-image.sh Armbian_*.img.gz
```

Output: `ThirtyOS_v1.0.0_HG680P.img.gz`

### Flash to SD/USB/SSD

```bash
gunzip ThirtyOS_v1.0.0_HG680P.img.gz
# Find your device: lsblk
sudo dd if=ThirtyOS_v1.0.0_HG680P.img of=/dev/sdX bs=4M status=progress conv=fsync
```

> **⚠️ Warning:** This erases ALL data on the target device.

### Resize partition (after flash)

```bash
sudo parted /dev/sdX resizepart 2 100%
sudo e2fsck -f /dev/sdX2
sudo resize2fs /dev/sdX2
```

---

## 🚀 First Boot on HG680P

1. Insert SD/USB/SSD into the HG680P box
2. Boot from USB (may need reset button or multi-boot tool)
3. Login (default Armbian credentials: `root` / `1234`)

Then run:

```bash
# 1. First-time setup
thirtyos-install setup

# 2. Install all packages (Node.js, Docker, PM2, bot-wa)
thirtyos-install prepare

# 3. Optimize system
thirtyos-install optimize

# 4. Install services you need
thirtyos-install bot-wa       # WhatsApp bot
thirtyos-install tunnel       # Cloudflare tunnel
thirtyos-install panel        # CasaOS / Portainer
thirtyos-install media        # Homeflix
thirtyos-install retro        # RetroArch
```

---

## 🔄 Updating

### Update ThirtyOS system & tools

```bash
thirtyos-install update
```

This updates:
- APT packages
- NPM global packages
- WhatsApp bot (if installed)
- **thirtyos-install itself** (auto-downloads from GitHub)

No re-flash needed!

---

## 🧰 Customization

### Modify the image

Edit `customize-image.sh` to add/remove packages, change configs, or install custom tools. Then rebuild:

```bash
sudo bash customize-image.sh Armbian_*.img.gz
```

### Add your own commands

Edit `thirtyos-install`, add a new function, push to GitHub:

```bash
git add thirtyos-install
git commit -m "Add my custom command"
git push
```

Then on your STB:

```bash
thirtyos-install update
```

---

## 📁 Repository Structure

```
ThirtyOS-tools/
├── customize-image.sh    # Build script (run on laptop)
├── thirtyos-install      # CLI tool (bundled in image)
└── README.md             # This file
```

---

## 📄 License

MIT License

Copyright (c) 2026 Ahdi Khalida Fathir

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## 🙏 Credits

- [Armbian](https://www.armbian.com/) — base OS
- [Homeflix](https://github.com/xebadir/homeflix) — media server
- [RetroArch](https://www.retroarch.com/) — emulator
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) — secure tunneling
- [Calamares](https://calamares.io/) — installer framework (inspiration)

---

## 🐛 Issues & Feedback

Report issues at: https://github.com/ahdikhfDev/ThirtyOS-tools/issues
