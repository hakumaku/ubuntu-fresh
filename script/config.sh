#!/usr/bin/env bash

# Script for miscellaneous configurations

LOCAL_TOTEM="/usr/share/thumbnailers/totem.thumbnailer"
REMOTE_TOTEM="$HOME"`
	`"/workspace/ubuntu-fresh/dotfiles/gif/totem.thumbnailer"

LOCAL_SMPLAYER="$HOME/.config/smplayer/smplayer.ini"
REMOTE_SMPLAYER="$HOME"`
	`"/workspace/ubuntu-fresh/dotfiles/smplayer/smplayer.ini"

smplayer () {
	[ -f $REMOTE_SMPLAYER ] && mkdir -p $HOME/.config/smplayer &&
	cp "$REMOTE_SMPLAYER" "$LOCAL_SMPLAYER"
}

thumbnailer () {
	[ -f $TOTEM_SOURCE ] && sudo cp "$REMOTE_TOTEM" "$LOCAL_TOTEM"
}

git_config () {
	git config --global user.email "gentlebuuny@gmail.com"
	git config --global user.name "hakumaku"
}

clear_unwanted_extension () {
	local dir="/usr/share/gnome-shell/extensions"
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
	sudo rm -rf "$dir/drive-menu"*
}

while getopts "is" opt; do
	case "$opt" in
		"i")
			smplayer
			thumbnailer
			git_config
			clear_unwanted_extension
			break;;
		"s")
			# import sync_dotfile ()
			source "$(dirname "$0")""/sync.sh"
			sync_dotfile "$LOCAL_TOTEM" "$REMOTE_TOTEM"
			sync_dotfile "$LOCAL_SMPLAYER" "$REMOTE_SMPLAYER"
			break;;
		*)
			break;;
	esac
done

