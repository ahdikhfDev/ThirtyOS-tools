#!/bin/bash
# ============================================================
#  ThirtyOS - Image Customizer
#  Jalanin di laptop Linux (Kali/Ubuntu/Debian) sebagai ROOT
#  Usage: sudo bash customize-image.sh <path-to-armbian.img.gz>
# ============================================================

set -e

# ── Warna ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Banner ─────────────────────────────────────────────────
echo -e "${CYAN}"
cat << 'EOF'
  _____ _     _      _       ___  ____
 |_   _| |__ (_)_ __| |_ _  / _ \/ ___|
   | | | '_ \| | '__| __| || | | \___ \
   | | | | | | | |  | |_| || |_| |___) |
   |_| |_| |_|_|_|   \__|_| \___/|____/
  Custom Armbian for HG680P STB - by Thirty
EOF
echo -e "${NC}"

# ── Cek root ───────────────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Harus dijalanin sebagai root! (sudo bash $0)"

# ── Cek argument ───────────────────────────────────────────
INPUT_IMAGE="$1"
[[ -z "$INPUT_IMAGE" ]] && err "Usage: sudo bash customize-image.sh <armbian.img.gz>"
[[ ! -f "$INPUT_IMAGE" ]] && err "File tidak ditemukan: $INPUT_IMAGE"

# ── Config ─────────────────────────────────────────────────
VERSION="1.0.0"
OUTPUT_IMAGE="ThirtyOS_v${VERSION}_HG680P.img"
WORK_DIR="/home/thirty/thirtyos-build"
MOUNT_DIR="${WORK_DIR}/mount"
BOT_WA_REPO="https://github.com/ahdikhfDev/bot-wa"

# ── Buat working directory ────────────────────────────────
mkdir -p "$WORK_DIR"

# ── Cek dependencies ──────────────────────────────────────
info "Mengecek dependencies..."
for dep in losetup mount chroot qemu-aarch64-static parted resize2fs; do
    command -v $dep &>/dev/null || err "$dep tidak ditemukan. Install dulu: apt install qemu-user-static parted e2fsprogs"
done
log "Dependencies OK"

# ── Extract image ──────────────────────────────────────────
info "Mengekstrak image..."
if [[ "$INPUT_IMAGE" == *.gz ]]; then
    cp "$INPUT_IMAGE" "${WORK_DIR}/base.img.gz"
    gunzip -f "${WORK_DIR}/base.img.gz"
    BASE_IMG="${WORK_DIR}/base.img"
else
    BASE_IMG="$INPUT_IMAGE"
fi
cp "$BASE_IMG" "${WORK_DIR}/${OUTPUT_IMAGE}"
log "Image diekstrak: ${WORK_DIR}/${OUTPUT_IMAGE}"

# ── Fungsi cleanup ─────────────────────────────────────────
cleanup_mount() {
    info "Cleanup mount..."
    rm -f "$MOUNT_DIR/etc/resolv.conf" 2>/dev/null || true
    rm -f "$MOUNT_DIR/usr/bin/qemu-aarch64-static" 2>/dev/null || true
    umount -lf "$MOUNT_DIR/dev/pts" 2>/dev/null || true
    umount -lf "$MOUNT_DIR/dev"     2>/dev/null || true
    umount -lf "$MOUNT_DIR/proc"    2>/dev/null || true
    umount -lf "$MOUNT_DIR/sys"     2>/dev/null || true
    umount -lf "$MOUNT_DIR"         2>/dev/null || true
    losetup -d "$LOOP_DEV"          2>/dev/null || true
    info "Cleanup mount selesai."
}

# ── Mount image ────────────────────────────────────────────
info "Mounting image..."
LOOP_DEV=$(losetup -fP --show "${WORK_DIR}/${OUTPUT_IMAGE}")
log "Loop device: $LOOP_DEV"

# Deteksi partisi rootfs (partisi terakhir)
sleep 1
PART=$(lsblk -ln -o NAME,SIZE "$LOOP_DEV" | awk 'NR>1{print $1}' | tail -1)
ROOT_PART="/dev/${PART}"
ROOT_PART_NUM=$(echo "$ROOT_PART" | grep -oP '\d+$')
info "Rootfs partition: $ROOT_PART (partition #$ROOT_PART_NUM)"

# Mount
mkdir -p "$MOUNT_DIR"
mount "$ROOT_PART" "$MOUNT_DIR"
mount --bind /dev     "$MOUNT_DIR/dev"
mount --bind /proc    "$MOUNT_DIR/proc"
mount --bind /sys     "$MOUNT_DIR/sys"
mount --bind /dev/pts "$MOUNT_DIR/dev/pts"

# Copy qemu untuk ARM64 chroot
cp /usr/bin/qemu-aarch64-static "$MOUNT_DIR/usr/bin/" 2>/dev/null || true

# Setup resolv.conf
rm -f "$MOUNT_DIR/etc/resolv.conf" 2>/dev/null || true
cp /etc/resolv.conf "$MOUNT_DIR/etc/resolv.conf"

log "Image ter-mount di $MOUNT_DIR"

trap cleanup_mount EXIT

# ── Download thirtyos-install dari GitHub ─────────────────
info "Download thirtyos-install dari GitHub..."
THIRTYOS_INSTALL_URL="https://raw.githubusercontent.com/ahdikhfDev/ThirtyOS-tools/main/thirtyos-install"
if curl -fsSL "$THIRTYOS_INSTALL_URL" -o "$MOUNT_DIR/usr/local/bin/thirtyos-install" 2>/dev/null; then
    chmod +x "$MOUNT_DIR/usr/local/bin/thirtyos-install"
    log "thirtyos-install terdownload dari GitHub"
else
    # Fallback ke local
    warn "Download gagal, coba dari lokal..."
    SCRIPT_DIR="$(dirname "$(realpath "$0")")"
    if [[ -f "$SCRIPT_DIR/thirtyos-install" ]]; then
        cp "$SCRIPT_DIR/thirtyos-install" "$MOUNT_DIR/usr/local/bin/thirtyos-install"
        chmod +x "$MOUNT_DIR/usr/local/bin/thirtyos-install"
        log "thirtyos-install tersalin dari lokal"
    else
        warn "thirtyos-install tidak ditemukan, skip."
    fi
fi

# ── Chroot & Modifikasi ────────────────────────────────────
info "Masuk chroot dan melakukan modifikasi..."
echo "Catatan: semua package install akan dilakukan di first-boot via thirtyos-install"

# Fix DNS di chroot
rm -f "$MOUNT_DIR/etc/resolv.conf"
echo "nameserver 8.8.8.8" > "$MOUNT_DIR/etc/resolv.conf"
echo "nameserver 1.1.1.1" >> "$MOUNT_DIR/etc/resolv.conf"

if ! chroot "$MOUNT_DIR" /bin/bash << 'CHROOT_EOF'
set -e

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

echo "--- Konfigurasi tmpfs /tmp ---"
if ! grep -q "tmpfs /tmp" /etc/fstab; then
    echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,size=256M 0 0" >> /etc/fstab
fi

echo "--- Disable service yang tidak diperlukan ---"
for svc in bluetooth avahi-daemon ModemManager apt-daily apt-daily-upgrade; do
    systemctl disable $svc 2>/dev/null || true
    systemctl mask $svc 2>/dev/null || true
done

echo "--- Set timezone Asia/Jakarta ---"
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
echo "Asia/Jakarta" > /etc/timezone

echo "--- Set hostname ---"
echo "thirtyos" > /etc/hostname
if grep -q '127.0.1.1' /etc/hosts; then
    sed -i 's/127.0.1.1.*/127.0.1.1\tthirtyos/' /etc/hosts
else
    echo "127.0.1.1 thirtyos" >> /etc/hosts
fi

echo "--- Custom MOTD ---"
rm -f /etc/update-motd.d/*
cat > /etc/update-motd.d/00-thirtyos << 'MOTDEOF'
#!/bin/bash

c_art='\033[38;5;51m'
c_sep='\033[1;30m'
c_lbl='\033[38;5;39m'
c_val='\033[0m'
c_warn='\033[38;5;214m'
c_rst='\033[0m'

os_val=$(grep -m1 'PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')
[ -z "$os_val" ] && os_val="Armbian 26.2.1 noble"
host_val=$(hostname)
ip_val=$(hostname -I | awk '{print $1}')
up_val=$(uptime -p | sed 's/up //')
ram_val=$(free -m | awk '/Mem/{printf "%dMB / %dMB", $3, $2}')
disk_val=$(df -h / | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')
cpu_val="4xCortex-A53"

echo ""
printf "${c_art}%-48s${c_sep}│  ${c_lbl}%-5s: ${c_val}%s\n" '   __  __    _      __           ____  _____ ' 'OS' "$os_val"
printf "${c_art}%-48s${c_sep}│  ${c_lbl}%-5s: ${c_val}%s\n" '  / /_/ /_  (_)____/ /_ __  __  / __ \/ ___/ ' 'Host' "${host_val} (${ip_val})"
printf "${c_art}%-48s${c_sep}│  ${c_lbl}%-5s: ${c_val}%s\n" ' / __/ __ \/ / ___/ __// / / / / / / /\__ \  ' 'Up' "$up_val"
printf "${c_art}%-48s${c_sep}│  ${c_lbl}%-5s: ${c_val}%s\n" '/ /_/ / / / / /  / /_ / /_/ / / /_/ /___/ /  ' 'RAM' "$ram_val"
printf "${c_art}%-48s${c_sep}│  ${c_lbl}%-5s: ${c_val}%s\n" '\__/_/ /_/_/_/   \__/ \__, /  \____//____/   ' 'Disk' "$disk_val"
printf "${c_art}%-48s${c_sep}│  ${c_lbl}%-5s: ${c_val}%s\n" '                     /____/                  ' 'CPU' "$cpu_val"
echo ""
echo -e "  ${c_warn}Jalankan 'thirtyos-install' untuk setup layanan.${c_rst}"
echo ""
MOTDEOF
chmod +x /etc/update-motd.d/00-thirtyos

echo "--- Regenerasi MOTD untuk saat ini ---"
bash /etc/update-motd.d/00-thirtyos | tee /etc/motd > /dev/null

echo "--- Systemd service regenerate MOTD tiap boot ---"
cat > /etc/systemd/system/thirtyos-motd.service << 'SVC'
[Unit]
Description=Regenerate ThirtyOS MOTD at boot
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/etc/update-motd.d/00-thirtyos | tee /etc/motd > /dev/null'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVC
systemctl enable thirtyos-motd.service 2>/dev/null || true

# Disable PAM motd (biar gak dobel tampil)
if grep -q "^session    optional     pam_motd.so" /etc/pam.d/sshd; then
    sed -i 's/^session    optional     pam_motd.so/#session    optional     pam_motd.so/' /etc/pam.d/sshd
    echo "PAM motd dinonaktifkan"
fi

# Aktifkan PrintMotd di SSH
if grep -q "^PrintMotd no" /etc/ssh/sshd_config; then
    sed -i 's/^PrintMotd no/PrintMotd yes/' /etc/ssh/sshd_config
    echo "PrintMotd diaktifkan"
fi

echo "--- ZRAM boot service ---"
cat > /etc/systemd/system/zram-swap.service << 'ZRAMSVC'
[Unit]
Description=ZRAM swap setup
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if ! grep -q zram /proc/swaps 2>/dev/null; then modprobe zram 2>/dev/null; echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null; total=$(awk "/MemTotal/{print \$2}" /proc/meminfo 2>/dev/null || echo 0); [ "$total" -gt 0 ] && size=$((total * 50 / 100 * 1024)) || size=512M; echo "$size" > /sys/block/zram0/disksize 2>/dev/null; mkswap /dev/zram0 2>/dev/null; swapon /dev/zram0 2>/dev/null; fi'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
ZRAMSVC
systemctl enable zram-swap.service 2>/dev/null || true

echo "--- Buat file versi ThirtyOS ---"
cat > /etc/thirtyos-release << RELEASE
THIRTYOS_VERSION="1.0.0"
THIRTYOS_CODENAME="Satu"
THIRTYOS_BUILD_DATE="$(date +%Y-%m-%d)"
THIRTYOS_ARCH="arm64"
THIRTYOS_BOARD="HG680P"
THIRTYOS_BASE="Armbian Ubuntu Noble"
RELEASE

echo "=== Modifikasi chroot selesai ==="
CHROOT_EOF
then
    log "Chroot modifikasi selesai"
else
    warn "Beberapa step chroot mungkin ada warning, lanjut..."
fi

# ── Repack image ───────────────────────────────────────────
info "Repack image..."
trap - EXIT
cleanup_mount

# Compress
info "Mengompresi image (ini butuh waktu)..."
gzip -9 "${WORK_DIR}/${OUTPUT_IMAGE}"
cp "${WORK_DIR}/${OUTPUT_IMAGE}.gz" "./${OUTPUT_IMAGE}.gz"

# Cleanup kerjaan
rm -rf "$WORK_DIR"

echo ""
echo -e "${GREEN}${BOLD}============================================${NC}"
echo -e "${GREEN}${BOLD}  ThirtyOS berhasil dibuat!${NC}"
echo -e "${GREEN}${BOLD}============================================${NC}"
echo -e "  Output : ${CYAN}./${OUTPUT_IMAGE}.gz${NC}"
echo -e "  Flash  : ${YELLOW}gunzip ${OUTPUT_IMAGE}.gz && dd if=${OUTPUT_IMAGE} of=/dev/sdX bs=4M status=progress${NC}"
echo ""
