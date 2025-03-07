#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Prevent errors in pipelines from being masked

# Check if running Fedora 41
if ! grep -q "^ID=fedora" /etc/os-release || ! grep -q "^VERSION_ID=41" /etc/os-release; then
    echo "This script is intended for Fedora 41 only. Exiting."
    exit 1
fi

# List of packages to install
PACKAGES=(
    go
    neovim
    tldr
    python3
    gnome-tweaks
    npm
    nodejs
    jq

    # For yubikey
    gnupg2
    dirmngr
    cryptsetup
    gnupg2-smime
    pcsc-tools
    opensc
    pcsc-lite
    pgp-tools
    yubikey-personalization-gui
)

echo "Updating system..."
sudo dnf update -y

echo "Installing RPM Fusion repositories..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                     https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


echo "Installing packages..."
sudo dnf install -y "${PACKAGES[@]}"
npm config set prefix '~/.local/'

git config --global user.name "Michael Tews"
git config --global user.email michael@tews.dev
git config --global user.gpgsign true
git config --global commit.gpgsign true
git config --global user.signingkey 0512FA62963CFD20

echo "Optimizing multimedia support..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
sudo dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
sudo dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
sudo dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Install Docker and related tools
echo "Installing Docker..."
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
wget https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm --output-document /tmp/docker-desktop.rpm
sudo dnf install /tmp/docker-desktop.rpm -y

# Install Yubico Authenticator
echo "Installing Yubico Authenticator..."
wget --output-document /tmp/yubi-auth.tar.gz https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz
mkdir -p $HOME/yubi
tar -xvf /tmp/yubi-auth.tar.gz --directory=$HOME/.local/share/

# Apply custom configurations
echo "Applying configurations..."
mkdir -p "$HOME/.config"

echo "alias ll='ls -la'" >> "$HOME/.bashrc"

echo "Configuring GNOME settings..."
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
gsettings set "org.gnome.shell" "favorite-apps" []
gsettings set "org.gnome.desktop.peripherals.touchpad" "tap-to-click" false
gsettings set "org.gnome.desktop.peripherals.mouse" "accel-profile" "flat"
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6
gsettings set "org.gnome.desktop.wm.keybindings" "close" "['<Shift><Super>q']"
gsettings set "org.gnome.desktop.wm.keybindings" "toggle-maximized" "['<Super>f']"

echo "Configuring workspace and application keybindings..."
gsettings set "org.gnome.shell.extensions.dash-to-dock" "app-hotkey-${0}" "[]"
for i in {1..6}; do 
    gsettings set "org.gnome.shell.keybindings" "switch-to-application-${i}" "[]"
    gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-${i}" "['<Super>${i}']"
    gsettings set "org.gnome.desktop.wm.keybindings" "move-to-workspace-${i}" "['<Super><Shift>${i}']"
    gsettings set "org.gnome.shell.extensions.dash-to-dock" "app-ctrl-hotkey-${i}" "[]"
    gsettings set "org.gnome.shell.extensions.dash-to-dock" "app-hotkey-${i}" "[]"
done


# Prompt to install intlde keyboard-layout
read -p "Install intlde keyboard-layout? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing intlde keyboard layout..."
    ./intlde-install.py
fi

# Install Adwaita GTK3 theme and configure it
echo "Installing Adwaita GTK3 theme..."
flatpak install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark -y
sudo dnf install adw-gtk3-theme -y

echo "Configuring GTK theme and color scheme..."
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Install YADM
echo "Installing YADM..."
wget https://download.opensuse.org/repositories/home:/TheLocehiliosan:/yadm/Fedora_41/noarch/yadm-3.3.0-75.1.noarch.rpm --output-document /tmp/yadm.rpm
sudo dnf install /tmp/yadm.rpm -y

echo "Installation and setup complete!"

