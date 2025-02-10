#!/bin/bash

read -p "Using Fedora? (y/n)" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 

	read -p "install base packages? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		sudo dnf install nvim tldr git zsh gnome-tweaks gnome-extensions-app python3 chromium go rustup openssl openssl-devel
		sudo dnf groupinstall "Development Tools" -y
		sudo dnf install nodejs npm -y
	fi

	read -p "Add atim/lazygit copr repo and install lazygit? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		sudo dnf copr enable atim/lazygit -y
		sudo dnf install lazygit -y
	fi

	read -p "Add RPMFusion? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
		sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
	fi

	read -p "Install docker? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		sudo dnf -y install dnf-plugins-core
		sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
		sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
		sudo systemctl enable --now docker
		wget https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm --output-document /tmp/docker-desktop.rpm
		sudo dnf install /tmp/docker-desktop.rpm -y
	fi

	read -p "Switch to Non-Free Multimedia Codecs? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		sudo dnf swap ffmpeg-free ffmpeg --allowerasing
		sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
		sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
		sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld
		sudo dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686
		sudo dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686
	fi

	read -p "Install yadm? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		wget https://download.opensuse.org/repositories/home:/TheLocehiliosan:/yadm/Fedora_41/noarch/yadm-3.3.0-75.1.noarch.rpm --output-document /tmp/yadm.rpm
		sudo dnf install /tmp/yadm.rpm -y
	fi


	read -p "Install software for Yubikey? (y/n) " answer
	if [ "$answer" != "${answer#[Yy]}" ] ;then 
		sudo dnf install \
			gnupg2 dirmngr cryptsetup gnupg2-smime \
			pcsc-tools opensc pcsc-lite \
			pgp-tools yubikey-personalization-gui
					wget  --output-document /tmp/yubi-auth.tar.gz https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz
					mkdir $HOME/yubi
					tar -xvf /tmp/yubi-auth.tar.gz --directory=$HOME/
	fi




fi


read -p "Install intlde keyboard-layout? (y/n) (requires python3 to install) " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
	./intlde-install.py
fi



read -p "Set I3wm/Sway like keybindings for switchting workspaces etc. ? (y/n) " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
	gsettings set org.gnome.mutter dynamic-workspaces false
	gsettings set org.gnome.desktop.wm.preferences num-workspaces 9
	gsettings set "org.gnome.desktop.wm.keybindings" "close" "['<Shift><Super>q']"
	gsettings set "org.gnome.desktop.wm.keybindings" "toggle-maximized" "['<Super>f']"

  gsettings set "org.gnome.shell.extensions.dash-to-dock" "app-hotkey-${0}" "[]"
	for i in {1..9}; do 
	  gsettings set "org.gnome.shell.keybindings" "switch-to-application-${i}" "[]"
	  gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-${i}" "['<Super>${i}']"
	  gsettings set "org.gnome.desktop.wm.keybindings" "move-to-workspace-${i}" "['<Super><Shift>${i}']"
	  gsettings set "org.gnome.shell.extensions.dash-to-dock" "app-ctrl-hotkey-${i}" "[]"
	  gsettings set "org.gnome.shell.extensions.dash-to-dock" "app-hotkey-${i}" "[]"
	done

fi


read -p "Clone dotfiles with yadm? (y/n) " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
	yadm clone https://github.com/mewsen/dotfiles
	if [ -e $HOME/.config/yadm/xkb ] ;then
		sudo python3 $HOME/.config/yadm/xkb/arch-linux-auto-install.py
	fi
fi

read -p "npm set config prefix to ~/.local/ (y/n) " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
	npm config set prefix '~/.local/'
fi

read -p "Better Gnome defaults? (y/n) " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
	gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
	gsettings set "org.gnome.shell" "favorite-apps" []
	gsettings set "org.gnome.desktop.peripherals.touchpad" "tap-to-click" false
	gsettings set "org.gnome.desktop.peripherals.mouse" "accel-profile" "flat"
fi



read -p "Install cheat.sh? (y/n)" answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
	curl -s https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh && sudo chmod +x /usr/local/bin/cht.sh
fi

read -p "setup zsh? (y/n) " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
	git clone https://github.com/sindresorhus/pure.git "$HOME/.config/zsh/pure"
	git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.config/zsh/zsh-autosuggestions"
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.config/zsh/zsh-syntax-highlighting"
fi
