#!/usr/bin/env bash

###############################################################################
# CrunchBang/BunsenLabs-Style Desktop Setup Script for Ubuntu 24.04 Server
# Author: ChatGPT for user
# Date: 2025-04-15
# This script transforms a minimal Ubuntu install into a fully themed Openbox DE
###############################################################################

set -euo pipefail

# === Logging and error handling ===
log_file="cb_setup.log"
exec > >(tee -a "$log_file") 2>&1

trap 'handle_error $LINENO "$BASH_COMMAND"' ERR

function handle_error() {
    local lineno="$1"
    local cmd="$2"
    echo ""
    echo "🔥 ERROR: Command '${cmd}' failed at line ${lineno}."
    echo "Check the log file: $log_file for full output."
    echo "Stack trace:"
    i=0
    while caller $i; do ((i++)); done
    exit 1
}

echo "🏁 Starting system transformation to CrunchBang/BunsenLabs style..."
sleep 1

###############################################################################
# 1. Update and upgrade system
###############################################################################
echo "🔧 Updating package lists and upgrading system..."
sudo apt update && sudo apt upgrade -y

###############################################################################
# 2. Install X11, Openbox, and basic desktop environment components
###############################################################################
echo "📦 Installing X11, Openbox, and core lightweight desktop tools..."

sudo apt install -y \
    xorg xserver-xorg xinit x11-xserver-utils \
    openbox obconf \
    tint2 conky nitrogen picom lxappearance \
    thunar thunar-archive-plugin thunar-volman gvfs gvfs-backends \
    lightdm lightdm-gtk-greeter lxpolkit

###############################################################################
# 3. Install fonts, themes, and icon packs
###############################################################################
echo "🎨 Installing themes, fonts, and icon sets..."

sudo apt install -y \
    arc-theme papirus-icon-theme \
    fonts-dejavu fonts-noto fonts-ubuntu

###############################################################################
# 4. Setup Openbox config directories
###############################################################################
echo "🗂 Creating configuration directories for Openbox and related tools..."

mkdir -pv ~/.config/{openbox,tint2,conky,autostart,gtk-3.0,gtk-4.0,rofi}
touch ~/.xinitrc
echo "exec openbox-session" > ~/.xinitrc

###############################################################################
# 5. Fetch sample configuration from BunsenLabs repository
###############################################################################
echo "📥 Cloning BunsenLabs configuration files for base setup..."

if [ -d "bunsen-configs" ]; then
    rm -rf bunsen-configs
fi

git clone https://github.com/BunsenLabs/bunsen-configs.git
cp -r bunsen-configs/skel/.config/* ~/.config/
cp bunsen-configs/skel/.gtkrc-2.0 ~/
cp bunsen-configs/skel/.Xresources ~/

###############################################################################
# 6. Setup Openbox autostart
###############################################################################
echo "⚙️ Configuring Openbox autostart with essential components..."

cat > ~/.config/openbox/autostart <<EOF
#!/bin/bash
numlockx on &
lxpolkit &
nitrogen --restore &
picom --config ~/.config/picom/picom.conf &
tint2 &
conky &
EOF

chmod +x ~/.config/openbox/autostart

###############################################################################
# 7. Install additional useful applications
###############################################################################
echo "🧰 Installing CrunchBang-style default applications..."

sudo apt install -y \
    firefox geany mousepad scrot lxterminal galculator viewnior \
    gparted synaptic neofetch htop xfce4-taskmanager \
    qutebrowser rofi oblogout numlockx network-manager network-manager-gnome

###############################################################################
# 8. Enable LightDM and NetworkManager
###############################################################################
echo "🔌 Enabling system services..."

sudo systemctl enable lightdm
sudo systemctl enable NetworkManager

###############################################################################
# 9. Wallpaper and compositor configuration
###############################################################################
echo "🖼 Setting default wallpaper and Picom config..."

# Create a basic picom.conf
cat > ~/.config/picom/picom.conf <<EOF
shadow = true;
fading = true;
backend = "glx";
vsync = true;
opacity-rule = [
  "90:class_g = 'URxvt'",
  "90:class_g = 'XTerm'"
];
EOF

# Download wallpaper (replace with your own or bundle one)
wget -O ~/wallpaper.jpg https://wallpapercave.com/wp/wp6599737.jpg || true
nitrogen --set-auto ~/wallpaper.jpg --save

###############################################################################
# 10. Set GTK theme and icon theme via settings.ini
###############################################################################
echo "🧑‍🎨 Applying GTK theme and icons..."

mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus
gtk-font-name=Ubuntu 11
EOF

###############################################################################
# 11. Finishing up
###############################################################################
echo "✅ Setup complete! You can now reboot into your new lightweight Openbox desktop."

read -rp "Do you want to reboot now? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "You can reboot later using 'sudo reboot'"
fi
