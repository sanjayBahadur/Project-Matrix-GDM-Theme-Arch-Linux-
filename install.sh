#!/bin/bash
# Project Matrix - GDM + Plymouth Theming Installer
# Author: Sunjay
# License: MIT

set -e
LOGFILE="/tmp/matrix_install.log"

# Colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

BACKUP_DIR="/var/lib/matrix_gdm_backup"
GDM_THEME_DIR="/usr/share/gnome-shell"
GDM_THEME_SRC="gdm"
PLYMOUTH_DIR="/usr/share/plymouth/themes/sematrix"

# Ensure root
if [[ $EUID -ne 0 ]]; then
  echo -e "$RED[ERROR] Please run as root.$RESET"
  exit 1
fi

# Logging
log() {
  echo -e "$1" | tee -a "$LOGFILE"
}

install_deps() {
  log "$GREEN[+] Installing dependencies...$RESET"
  pacman -Sy --noconfirm python python-pillow gdm plymouth glib2
  pip install --quiet pillow || true
}

generate_assets() {
  log "$GREEN[+] Generating Matrix background and animation frames...$RESET"
  python3 <<EOF
from PIL import Image, ImageDraw, ImageFont
import random, os

os.makedirs("gdm", exist_ok=True)
os.makedirs("plymouth", exist_ok=True)

font = ImageFont.load_default()
width, height = 1920, 1080
chars = "01ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# GDM background
bg = Image.new("RGB", (width, height), "black")
d = ImageDraw.Draw(bg)
for _ in range(1500):
    x = random.randint(0, width)
    y = random.randint(0, height)
    c = random.choice(chars)
    d.text((x, y), c, fill=(0, 255, 0), font=font)
bg.save("gdm/matrix-bg.png")

# Plymouth frames
for i in range(1, 7):
    frame = Image.new("RGB", (640, 480), "black")
    d = ImageDraw.Draw(frame)
    for _ in range(500):
        x = random.randint(0, 640)
        y = random.randint(0, 480)
        c = random.choice(chars)
        d.text((x, y), c, fill=(0, 255, 0), font=font)
    frame.save(f"plymouth/{i}.png")
EOF
}

apply_gdm_theme() {
  log "$GREEN[+] Applying Matrix GDM theme...$RESET"
  mkdir -p "$BACKUP_DIR"
  cp "$GDM_THEME_DIR/gnome-shell-theme.gresource" "$BACKUP_DIR" || true
  cp gdm/matrix-bg.png "$GDM_THEME_DIR/matrix-bg.png"

  cat > gdm/gnome-shell-theme.gresource.xml <<XML
<?xml version='1.0' encoding='UTF-8'?>
<gresources>
  <gresource prefix="/org/gnome/shell/theme">
    <file preprocess="to-pixdata">matrix-bg.png</file>
    <file>matrix-gdm.css</file>
  </gresource>
</gresources>
XML

  cat > gdm/matrix-gdm.css <<CSS
#lockDialogGroup {
  background: black url(resource:///org/gnome/shell/theme/matrix-bg.png);
  background-size: cover;
}

#loginDialog, #unlockDialog {
  color: #00FF00;
  font-family: monospace;
}
CSS

  glib-compile-resources gdm/gnome-shell-theme.gresource.xml --target="$GDM_THEME_DIR/gnome-shell-theme.gresource" --sourcedir=gdm/
  systemctl restart gdm
}

setup_plymouth() {
  log "$GREEN[+] Installing Matrix Plymouth theme...$RESET"
  mkdir -p "$PLYMOUTH_DIR"

  cat > "$PLYMOUTH_DIR/sematrix.plymouth" <<PLY
[Plymouth Theme]
Name=SeMatrix
Description=Matrix Boot Theme
ModuleName=script
Animation=sematrix
PLY

  cat > "$PLYMOUTH_DIR/sematrix.script" <<SCRIPT
wallpaper_image = Image("1.png");
message_position = TOP;
message_color = "#00FF00";
SCRIPT

  for i in {1..6}; do cp "plymouth/$i.png" "$PLYMOUTH_DIR/$i.png"; done

  plymouth-set-default-theme -R sematrix
  dracut -f || mkinitcpio -P
}

revert_all() {
  log "$RED[!] Reverting GDM and Plymouth changes...$RESET"
  if [[ -f "$BACKUP_DIR/gnome-shell-theme.gresource" ]]; then
    cp "$BACKUP_DIR/gnome-shell-theme.gresource" "$GDM_THEME_DIR/gnome-shell-theme.gresource"
  fi
  rm -rf "$PLYMOUTH_DIR"
  plymouth-set-default-theme -R bgrt || true
  dracut -f || mkinitcpio -P
  systemctl restart gdm
}

uninstall_all() {
  log "$RED[-] Uninstalling Project Matrix...$RESET"
  revert_all
  rm -rf gdm plymouth "$BACKUP_DIR"
  pip uninstall -y pillow || true
}

case "$1" in
  --install)
    install_deps
    generate_assets
    apply_gdm_theme
    setup_plymouth
    ;;
  --revert)
    revert_all
    ;;
  --uninstall)
    uninstall_all
    ;;
  *)
    echo -e "$GREEN[Usage]$RESET sudo ./install.sh --install | --revert | --uninstall"
    ;;
esac
