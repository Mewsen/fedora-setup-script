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
curl -L https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm -o /tmp/docker-desktop.rpm
sudo dnf install /tmp/docker-desktop.rpm -y

# Install Yubico Authenticator
echo "Installing Yubico Authenticator..."
curl -L https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz -o /tmp/yubi-auth.tar.gz
mkdir -p $HOME/.local/bin/
tar -xvf /tmp/yubi-auth.tar.gz --directory=$HOME/.local/bin/
pushd $HOME/.local/bin/yubico-authenticator-7.1.1-linux
./desktop_integration.sh
popd


# Apply custom configurations
echo "Applying configurations..."
mkdir -p "$HOME/.config"

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
for i in {1..6}; do 
    gsettings set "org.gnome.shell.keybindings" "switch-to-application-${i}" "[]"
    gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-${i}" "['<Super>${i}']"
    gsettings set "org.gnome.desktop.wm.keybindings" "move-to-workspace-${i}" "['<Super><Shift>${i}']"
done

array=( https://extensions.gnome.org/extension/3193/blur-my-shell/
https://extensions.gnome.org/extension/517/caffeine/
https://extensions.gnome.org/extension/615/appindicator-support/
https://extensions.gnome.org/extension/16/auto-move-windows/ )

for i in "${array[@]}"
do
    EXTENSION_ID=$(curl -s $i | grep -oP 'data-uuid="\K[^"]+')
    VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=$EXTENSION_ID" | jq '.extensions[0] | .shell_version_map | map(.pk) | max')
    curl -L "https://extensions.gnome.org/download-extension/${EXTENSION_ID}.shell-extension.zip?version_tag=$VERSION_TAG" -o ${EXTENSION_ID}.zip
    gnome-extensions install --force ${EXTENSION_ID}.zip
    if ! gnome-extensions list | grep --quiet ${EXTENSION_ID}; then
        busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s ${EXTENSION_ID}
    fi
    gnome-extensions enable ${EXTENSION_ID}
    rm ${EXTENSION_ID}.zip
done

# Install Adwaita GTK3 theme and configure it
echo "Installing Adwaita GTK3 theme..."
flatpak install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark -y
sudo dnf install adw-gtk3-theme -y

echo "Configuring GTK theme and color scheme..."
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Prompt to install intlde keyboard-layout
read -p "Install intlde keyboard-layout? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing intlde keyboard layout..."
    sudo ./intlde-install.py
fi

echo "Installation and setup complete!"

