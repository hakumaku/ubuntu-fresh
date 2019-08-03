#!/usr/env/bin bash

DIR="$HOME/workspace/ubuntu-fresh"
keys=(
	"Shutdown, gnome-session-quit --power-off, <Super>Escape"
	"Gnome Tweaks, gnome-tweaks, <Super>U"
	"Calculator, gnome-calculator, <Super>C"
	"Simple Terminal, st, <Super>Return"
	"Ranger, st -e \'ranger\', <Super>R"
	"Web Browser, firefox, <Super>W"
	"Steam, steam, <Super>G"
	"Nvidia Dmenu, $DIR/nvidia.sh, <Super>Semicolon"
	"Nightlight, $DIR/nightlight.sh, <Super>Backslash"
	"System Monitor, gnome-system-monitor, <Primary><Shift>Tab"
	"Rofi, rofi -show drun, <Super>A"
	"Brightness up, $DIR/backlight.sh -i, <Super>9"
	"Brightness down, $DIR/backlight.sh -d, <Super>8"
)

gsettings_init () {
	keys=("$@")
	length=${#keys[@]}
	property="org.gnome.settings-daemon.plugins.media-keys custom-keybindings"

	array=()
	element="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom/"
	for ((i=0; i<$length; i++)); do
		array+=("'${element%*/}$i/',")
	done
	array[$length-1]=${array[$length-1]/%,/}

	# To circumvent bash expansion
	echo gsettings set $property '"[' ']"' | bash
	echo gsettings set $property '"[' ${array[@]} ']"' | bash
}

gsettings_assign () {
	keys=("$@")
	length=${#keys[@]}
	property="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"`
	`"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"`
	`"custom/"

	IFS=','
	for ((i=0; i<$length; i++)); do
		read -ra tuples <<< "${keys[i]}"
		name=$( echo ${tuples[0]} | xargs )
		cmd=$( echo ${tuples[1]} | xargs )
		binding=$( echo ${tuples[2]} | xargs )

		gsettings set "${property%*/}$i/" name "$name"
		gsettings set "${property%*/}$i/" command "$cmd"
		gsettings set "${property%*/}$i/" binding "$binding"
	done
	IFS=' '
}

gsettings_init "${keys[@]}"
gsettings_assign "${keys[@]}"
