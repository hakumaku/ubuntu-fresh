#!/usr/bin/env bash
# Script for miscellaneous configurations

OS=$( cat /etc/os-release | sed -n 's/^NAME=//p' )
OS=${OS,,}
declare -A DIR=(
	["source"]="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
	["home"]="$( git rev-parse --show-toplevel )"
	["parent"]="${DIR[home]}/.."
	["dot"]="${DIR[home]}/dotfiles"
	["config"]="$HOME/.config"
)
# {{{ dotfiles
declare -A DOTFILES=(
	# ["local_totem"]="/usr/share/thumbnailers/totem.thumbnailer"
	# ["remote_totem"]="${DIR[dot]}/gif/totem.thumbnailer"
	# (remote, local) pair
	["vlc"]="${DIR[config]}/vlc/vlcrc,${DIR[dot]}/vlc/vlcrc"
	["vim"]="$HOME/.vimrc,${DIR[dot]}/vim/.vimrc"
	["st"]="${DIR[parent]}/st/config.h,${DIR[dot]}/st/config.h"
	# ["dmenu"]="${DIR[parent]}/dmenu/config.h,${DIR[dot]}/dmenu/config.h"
	["powerline"]="${DIR[config]}/powerline/config.json,`
		`${DIR[dot]}/powerline/config.json"
	["tmux"]="$HOME/.tmux.conf,${DIR[dot]}/tmux/.tmux.conf"
	["ranger"]="${DIR[config]}/ranger/rc.conf,${DIR[dot]}/ranger/rc.conf"
	["awesome"]="${DIR[config]}/awesome,${DIR[dot]}/awesome"
	["rofi"]="${DIR[config]}/rofi,${DIR[dot]}/rofi"
	["i3"]="${DIR[config]}/i3,${DIR[dot]}/i3"
	["bspwm"]="${DIR[config]}/bspwm,${DIR[dot]}/bspwm"
	["sxhkd"]="${DIR[config]}/sxhkd,${DIR[dot]}/sxhkd"
	["polybar"]="${DIR[config]}/polybar,${DIR[dot]}/polybar"
	["compton"]="${DIR[config]}/compton.conf,${DIR[dot]}/compton/compton.conf"
)
# }}}
# {{{ Arch Packages
AUR=(
	"ttf-d2coding" "ttf-unfonts-core-ibx"
	"stacer" "snapd" "humanity-icon-theme"
	"yaru"
)
ARCH_PACKAGE=(
	"xorg" "xorg-xinit" "base-devel" "gdm" "gnome" "gnome-tweaks"
	"networkmanager" "bluez" "bluez-utils" "lxappearance"
	"fcitx-im" "fcitx-hangul" "fcitx-configtool" "tar" "unzip"
	"adobe-source-han-sans-kr-fonts" "ttf-dejavu" "rofi" "most"
	"git" "gvim" "tmux" "wget" "curl" "valgrind" "htop" "neofetch"
	"gdb" "feh" "compton" "ffmpeg" "ffmpegthumbnailer" "w3m"
	"autogen" "ctags" "automake" "cmake" "gufw" "moreutils" "python-pip"
	"cmus" "sxiv" "exiv2" "imagemagick" "vlc" "cheese"
	"transmission-gtk" "transmission-cli" "transmission-remote-gtk"
	"nautilus" "firefox" "dnsutils"
)
install_arch_package () {
	local dir=""
	if sudo pacman -Syu && sudo pacman -Sq --noconfirm ${ARCH_PACKAGE[*]}; then
		for aur in "${AUR[@]}"; do
			dir="${DIR[parent]}/$aur"
			git clone "https://aur.archlinux.org/""$aur"".git" "$dir" &&
				( cd "$dir" && makepkg -sri --noconfirm )
		done
	else
		echo "Cannot execute 'pacman'."
		echo "Check the names of arch packages."
		exit 1
	fi
	local conf="/etc/locale.gen"
	sudo sed -Ei "s/^#(en_US.UTF-8)/\1/" "$conf" &&
		sudo sed -Ei "s/^#(ko_KR.UTF-8)/\1/" "$conf" && sudo locale-gen
	sudo systemctl enable bluetooth
	sudo systemctl enable Networkmanager
	sudo systemctl enable snap
	sudo systemctl enable gdm
	sudo systemctl enable --now snapd.socket
}
install_steam () {
	# Enable multilib
	local conf="/etc/pacman.conf"
	local pack=(
		"nvidia" "nvidia-utils" "lib32-nvidia-utils" "ttf-liberation" "steam"
	)
	sudo sed -Ei "/^#\[multilib\]/,/^#Include/ s/#(.*)/\1/" "$conf" &&
		sudo pacman -Syy && sudo pacman -Sq --noconfirm "${pack[@]}"
}
# }}}
# {{{ Ubuntu Packages
PPA=(
	# "ppa:nilarimogard/webupd8"			# gnome-twitch
	"ppa:graphics-drivers"				# nvidia graphics drivers
	"ppa:oguzhaninan/stacer"			# Stacer
)
UBUNTU_PACKAGE=(
	"git" "vim" "vim-gnome" "g++" "curl" "ctags"
	"valgrind" "htop" "tmux" "screenfetch" "autogen" "most"
	"automake" "cmake" "snap" "fcitx-hangul" "gufw"
	"cmus" "sxiv" "exiv2" "imagemagick" "ffmpeg" "ffmpegthumbnailer"
	"gnome-tweak-tool" "gnome-shell-extensions"
	"python3-dev" "python3-pip" "python-apt"
	"w3m-img" "compton" "feh" "moreutils" "rofi" "lxappearance"
	"vlc" "cheese" "transmission" "transmission-cli" "stacer"
	"steam" "steam-devices"
	"winbind"						# wine League of Legends

	# Suckless Terminal & Dmenu
	"libx11-dev" "libxext-dev" "libxft-dev"
	# "libfreetype6-dev"
	# "libxft2" "libfontconfig1-dev" "libpam0g-dev"
	# "libxrandr2" "libxss1"
	# Dwm
	"libxinerama-dev"

	# Google Chrome
	# "google-chrome-stable" "chrome-gnome-shell"

	# Twitch
	# "gnome-twitch"
	# "gnome-twitch-player-backend-gstreamer-cairo"
	# "gnome-twitch-player-backend-gstreamer-clutter"
	# "gnome-twitch-player-backend-gstreamer-opengl"
	# "gnome-twitch-player-backend-mpv-opengl"
)
install_ubuntu_package () {
	for ppa in ${PPA[@]}; do
		sudo add-apt-repository -n -y "$ppa"
	done
	UBUNTU_PACKAGE+=("$(check-language-support)")
	sudo apt -qq update && sudo ubuntu-drivers autoinstall &&
		sudo apt -qq -y --ignore-missing install ${UBUNTU_PACKAGE[*]}

}
# }}}

sync_dotfile () {
	IFS=','
	local arg=($1)
	unset IFS

	local machine="${arg[0]}"		# desktop dotfile
	local remote="${arg[1]}"		# github dotfile
	local filename="$(dirname "$machine")"
	filename="${filename##*/}/$(basename -- "$machine")"
	local dir=""

	# Copy a single file.
	if [ -f "$remote" ]; then
		# if empty then copy
		if [ ! -f "$machine" ]; then
			dir="${machine%/*}"
			mkdir -p $dir &&
				cp "$remote" "$machine"
			return 0
		fi
		# Synch
		if ! cmp -s "$machine" "$remote"; then
			cp "$machine" "$remote"
			printf "\e[4m* $filename\e[24m\n"
		else
			printf "  $filename\e[24m\n"
		fi

	# Copy multiple files in the directory.
	elif [ -d "$remote" ]; then
		# if empty then copy
		if [ ! -d "$machine" ]; then
			dir="$machine"
			cp -r "$remote" "$machine"
			return 0
		fi
		# Synch
		# Note that it does not handle if either the directory to the file or
		# the file contains white spaces.
		local type=""
		local file=""
		echo "  $(basename $machine)/"
		while read line; do
			type="${line: -1}"
			case "$type" in
				# identica'l'
				"l")
					file=$( sed -nE "s/Files (.*) and .*/\1/p" <<< "$line" )
					printf "\t  \"${file##*/}\"\n"
				;;
				# diffe'r': copy $machine to $remote
				"r")
					file=$( sed -nE "s/Files (.*) and .*/\1/p" <<< "$line" )
					file="${file##*/}"
					printf "\t* \e[4m\"$file\"\e[24m\n"
					cp "$machine/$file" "$remote"
				;;
				# Only in ...: ...
				# copy $machine to $remote
				# remove $remote
				*)
					file=$( sed -E "s/^(.*): //" <<< "$line" )
					if [ -f "$machine/$file" ]; then
						printf "\t\e[32m+ \"$file\"\e[39m\n"
						cp "$machine/$file" "$remote"
					elif [ -f "$remote/$file" ]; then
						printf "\t\e[31m- \"$file\"\e[39m\n"
						rm "$remote/$file"
					else
						exit 1
					fi
				;;
			esac
		done <<< "$( diff -rsq "$remote" "$machine" )"
		return 0

	else
		return 1
	fi
}

# {{{ Vim Vundle
install_vundle () {
	local url="https://github.com/VundleVim/Vundle.vim.git"
	git clone -q "$url" ~/.vim/bundle/Vundle.vim &&
		sync_dotfile "${DOTFILES[vim]}" && vim +PluginInstall +qall &&
		python3 ~/.vim/bundle/YouCompleteMe/install.py --all &> /dev/null
}
# }}}

# {{{ Tmux Theme
install_tmux_theme () {
	local url="https://github.com/jimeh/tmux-themepack.git"
	git clone -q "$url" ~/.tmux-themepack
}
# }}}

# {{{ Youtubedl
install_youtubedl () {
	local url="https://yt-dl.org/downloads/latest/youtube-dl"
	sudo wget "$url" -O /usr/local/bin/youtube-dl
	sudo chmod a+rx /usr/local/bin/youtube-dl
}
# }}}

# {{{ Suru++
install_suru () {
	local url="https://raw.githubusercontent.com/gusbemacbe/suru-plus/master/install.sh"
	{ wget -qO- $url | sh; } && { wget -qO- https://git.io/fhQdI | sh; } &&
		suru-plus-folders -C orange --theme Suru++
}
# }}}

# {{{ Polybar
install_polybar () {
	if [[ $OS == *"arch"* ]]; then
		local polybargit="https://aur.archlinux.org/polybar.git"
		local dir="${DIR[parent]}/polybar"
		git clone "$polybargit" "$dir" &&
			( cd "$dir" && makepkg -sri --noconfirm )

	elif [[ $OS == *"ubuntu"* ]]; then
		local url="https://github.com/jaagr/polybar.git"
		local dep=(
			"cmake" "cmake-data" "libcairo2-dev" "libxcb1-dev" "libxcb-ewmh-dev"
			"libxcb-icccm4-dev" "libxcb-image0-dev" "libxcb-randr0-dev"
			"libxcb-util0-dev" "libxcb-xkb-dev" "pkg-config" "python-xcbgen"
			"xcb-proto" "libxcb-xrm-dev" "libasound2-dev" "libmpdclient-dev"
			"libiw-dev" "libcurl4-openssl-dev" "libpulse-dev"
			"libxcb-composite0-dev" "xcb" "libxcb-ewmh2" "libanyevent-i3-perl"
			"libanyevent-perl" "libasync-interrupt-perl" "libcommon-sense-perl"
			"libev-perl" "libguard-perl" "libjson-xs-perl"
			"libtypes-serialiser-perl" "libjson-glib-dev"
		)
		sudo apt -qq -y install ${dep[*]} &&
			git clone -q "$url" "${DIR[parent]}/polybar" &&
			( cd "${DIR[parent]}/polybar" && ./build.sh )
	else
		exit 1
	fi
}
# }}}

# {{{ Lemonbar
install_lemonbar () {
	local dir="${DIR[parent]}""/lemonbar"
	local url="https://github.com/LemonBoy/bar.git"
	git clone "$url" "$dir" &&
		( cd "$dir" && make && sudo make install )
}
# }}}

# {{{ Nerd Font
install_nerdfont () {
	local fonts=(
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/SourceCodePro.zip"
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Inconsolata.zip"
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/UbuntuMono.zip"
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/Mononoki.zip"
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/AnonymousPro.zip"
	)
	local font_dir="$HOME/.local/share/fonts"
	mkdir -p $font_dir && {
	for font in "${fonts[@]}"; do
		wget -q "$font" -P "$font_dir" && {
		font=${font##*/}
		unzip -qq -d "$font_dir/${font%.zip}" "$font_dir/$font"
		rm "$font_dir/$font"
		}
	done
	} && fc-cache -fv
}
# }}}

# {{{ Ranger Devicons
install_ranger_devicons () {
	local url="https://github.com/alexanderjeurissen/ranger_devicons"
	IFS=','
	local config=(${DOTFILES[ranger]})
	unset IFS
	local to="${config[0]}"
	local from="${config[1]}"
	git clone -q "$url" "${DIR[parent]}/ranger_devicons" &&
		(cd "${DIR[parent]}/ranger_devicons" && make install) &&
		cp "$from" "$to" && ranger --copy-config=scope
}
# }}}

# {{{ Install Suckless Software
install_suckless () {
	# $1: install directory
	# $2: remote config.h
	# $3: url
	# $4: package
	local dir="$1"
	local config="$2"
	local url="$3"
	local package="$4"

	mkdir -p "$dir" &&
	wget -q "$url$package" -P "$dir" &&
	tar xf "$dir/$package" -C "$dir" --strip-components=1 &&
	cp $config $dir &&
	(cd "$dir" && make && sudo make install && make clean)
}

install_st_terminal () {
	IFS=','
	local arg=(${DOTFILES[st]})
	unset IFS
	local dir="${arg[0]/config.h}"
	local config="${arg[1]}"
	local url="https://dl.suckless.org/st/"
	local package="$(wget -q "$url" -O - | grep -o "st-\([0-9].\)*tar.gz" |
		sort -V | tail -1)"
	if [ -z "$package" ]; then
		echo "Cannot parse the link."
		return
	fi

	install_suckless "$dir" "$config" "$url" "$package" &&
	if [[ ! -d "$HOME/.local/share/applications" ]]; then
		mkdir -p "$HOME/.local/share/applications"
	fi
	cp "${DIR[dot]}/st/st.desktop" "$HOME/.local/share/applications"
}

install_dmenu () {
	IFS=','
	local arg=(${DOTFILES[dmenu]})
	unset IFS
	local dir="${arg[0]/config.h}"
	local config="${arg[1]}"
	local url="https://dl.suckless.org/tools/"
	local package="$(wget -q "$url" -O - | grep -o "dmenu-\([0-9].\)*tar.gz" |
		sort -V | tail -1)"
	if [ -z "$package" ]; then
		echo "Cannot parse the link."
		return
	fi

	install_suckless "$dir" "$config" "$url" "$package"
}
# }}}

# {{{ i3-gaps
install_i3gaps () {
	if [[ $OS == *"ubuntu"* ]]; then
		local dep=(
			"libxcb1-dev" "libxcb-keysyms1-dev" "libpango1.0-dev"
			"libxcb-util0-dev" "libxcb-icccm4-dev" "libyajl-dev"
			"libstartup-notification0-dev" "libxcb-randr0-dev" "libev-dev"
			"libxcb-cursor-dev" "libxcb-xinerama0-dev" "libxcb-xkb-dev"
			"libxkbcommon-dev" "libxkbcommon-x11-dev" "autoconf"
			"libxcb-xrm0" "libxcb-xrm-dev" "automake" "libxcb-shape0-dev"
		)

	cd /tmp && git clone https://www.github.com/Airblader/i3 i3-gaps &&
		cd i3-gaps && autoreconf --force --install && rm -rf build/ &&
		mkdir -p build && cd build/ &&
		../configure --prefix=/usr --sysconfdir=/etc --disable-sanitizers &&
		make && sudo make install
	elif [[ $OS == *"arch"* ]]; then
		sudo pacman -Sy i3-gaps
	else
		return 1
	fi
}
# }}}

# {{{ bspwm
install_bspwm () {
	local dep=()
	if [[ $OS == *"ubuntu"* ]]; then
		dep=(
			"libxcb-xinerama0-dev" "libxcb-icccm4-dev" "libxcb-randr0-dev"
			"libxcb-util0-dev" "libxcb-ewmh-dev" "libxcb-keysyms1-dev"
			"libxcb-shape0-dev"
		)
		sudo apt install -qq -y ${dep[@]}
	elif [[ $OS == *"arch"* ]]; then
		dep=(
			"libxcb" "xcb-util" "xcb-util-wm" "xcb-util-keysyms"
		)
		sudo pacman -S ${dep[@]}
	else
		return 1
	fi

	( cd ${DIR[parent]} &&
		git clone https://github.com/baskerville/bspwm.git &&
		git clone https://github.com/baskerville/sxhkd.git &&
		cd bspwm && make && sudo make install &&
		cd ../sxhkd && make && sudo make install &&
		mkdir -p ~/.config/{bspwm,sxhkd} &&
		cp "${DOTFILES[bspwm]}"  ~/.config/bspwm/ &&
		cp "${DOTFILES[sxhkd]}" ~/.config/sxhkd/ )
}
# }}}

# {{{ Unimatrix
install_unimatrix () {
	local url="https://raw.githubusercontent.com/will8211/`
		`unimatrix/master/unimatrix.py"
	sudo curl -L "$url" -o /usr/local/bin/unimatrix
	sudo chmod a+rx /usr/local/bin/unimatrix
}
# }}}

# {{{ Pip
install_pip () {
	local packages=(
		"virtualenv"
		"powerline-status"
		"ranger-fm"
	)
	for pack in ${packages[@]}; do
		pip3 install --user -q "$pack"
	done
}
# }}}

# {{{ fcitx config
fcitx_config () {
	local profile="$HOME/.config/fcitx/profile"
	local config="$HOME/.config/fcitx/config"
	sed -Ei "s/#(IMName=)/\1Hangul/" "$profile"
	sed -Ei "s/(hangul:)False/\1True/" "$profile"
	sed -Ei "s/#(TriggerKey=).*/\1HANGUL/" "$config"
	sed -Ei "s/#(SwitchKey=).*/\1Disabled/" "$config"
	sed -Ei "s/#(IMSwitchKey=).*/\1False/" "$config"
	if [[ $OS = *"arch"* ]]; then
		cat >> $HOME/.pam_environment <<- END
			GTK_IM_MODULE=fcitx
			QT_IM_MODULE=fcitx
			XMODIFIERS=@im=fcitx
		END
	elif [[ $OS = *"ubuntu"* ]]; then
		im-config -n fcitx
	else
		return 0
	fi
}
# }}}

disable_gnome_software () {
	if [[ $OS != *"ubuntu"* ]]; then
		return 1
	fi
	local src="/etc/xdg/autostart/gnome-software-service.desktop"
	local dest="$HOME/.config/autostart/""$(basename -- $src)"
	if [ ! -f $src ]; then
		return
	fi
	mkdir -p "$HOME/.config/autostart" && cp "$src" "$dest" &&
	echo "X-GNOME-Autostart-enabled=false" >> $dest
}

package_install () {
	while [[ $# -gt 0 ]]; do
		arg="${1,,}"
		case "$arg" in
			default)
				local default_packages=(
					"$OS" "pip" "st" "nerdfont" "vundle"
					"tmux_theme" "ranger_devicons"
					"suru" "youtubedl" "unimatrix" "fcitx" "git" "sync"
				)
				set ${default_packages[@]}
			;;
			*"arch"*)
				install_arch_package
				local nvidia=$( lspci | grep "NVIDIA" )
				if [[ $nvidia ]]; then
					install_steam
				fi
			;;
			*"ubuntu"*) install_ubuntu_package ;;
			# The rest must be called after
			pip)
				install_pip
				# Enable video option in ranger-fm
				if [[ -f "$HOME/.config/ranger/scope.sh" ]]; then
					sed -i '/# Video$/{
						n
						s/# //
						n
						s/# //
						n
						s/# //
						n
						s/# //
					}' "$HOME/.config/ranger/scope.sh"
				fi
			;;
			st|st_terminal) install_st_terminal ;;
			nerdfont|nerd|font) install_nerdfont ;;
			vundle|vim) install_vundle ;;
			tmux_theme|tmux) install_tmux_theme ;;
			ranger_devicons) install_ranger_devicons ;;
			suru) install_suru ;;
			youtubedl|youtube) install_youtubedl ;;
			polybar) install_polybar ;;
			lemonbar) install_lemonbar ;;
			i3-gaps) install_i3gaps ;;
			bspwm) install_bspwm ;;
			unimatrix) install_unimatrix ;;
			dmenu) install_dmenu ;;
			fcitx)
				if [[ ! -d "$HOME/.config/fcitx" ]]; then
					( exec fcitx -d & )
				fi
				fcitx_config
			;;
			git)
				git config --global user.email "gentlebuuny@gmail.com"
				git config --global user.name "hakumaku"
			;;
			thumbnailer)
				"${DIR[dot]}/gif/totem.thumbnailer"
				if [ -f "${DIR[dot]}/gif/totem.thumbnailer" ]; then
					sudo cp "${DIR[dot]}/gif/totem.thumbnailer" \
						"/usr/share/thumbnailers/totem.thumbnailer"
				fi
			;;
			gnome-extension)
				dir="/usr/share/gnome-shell/extensions"
				sudo rm -rf "$dir/screenshot-window-sizer"*
				sudo rm -rf "$dir/apps-menu"*
				sudo rm -rf "$dir/auto-move-window"*
				sudo rm -rf "$dir/ubuntu-dock"*
				sudo rm -rf "$dir/launch-new-instance"*
				sudo rm -rf "$dir/window-list"*
				sudo rm -rf "$dir/native-window-placement"*
				sudo rm -rf "$dir/windowsNavigator"*
				sudo rm -rf "$dir/places-menu"*
				sudo rm -rf "$dir/workspace-indicator"*
				shift
			;;
			sync)
				for i in "${!DOTFILES[@]}"; do
					sync_dotfile "${DOTFILES[$i]}"
				done
			;;
			*)
				echo "Unknown arguments: $arg"
			;;
		esac
		shift
	done
}

grub_config () {
	# sudo grub-mkfont --output=/boot/grub/fonts/DejaVuSansMono20.pf2 --size=20 /usr/share/fonts/TTF/dejavu/DejaVuSansMono.ttf
	local GRUB_FONT=/boot/grub/fonts/DejaVuSansMono18.pf2
	local custom="/etc/grub.d/40_custom"

	cat >> $custom <<- END
	menuentry "System shutdown" {
		echo "System shutting down..."
		halt
	}
	if [ ${grub_platform} == "efi" ]; then
		menuentry "Firmware setup" {
			fwsetup
		}
	fi
	END
}

package_install "$@"

