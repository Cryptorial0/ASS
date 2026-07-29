#!/usr/bin/env bash

# If launched from GUI desktop/file-manager without a tty, relaunch inside terminal
if [ ! -t 0 ]; then
    if command -v konsole &>/dev/null; then
        konsole -e "$0" "$@"
        exit 0
    elif command -v gnome-terminal &>/dev/null; then
        gnome-terminal -- "$0" "$@"
        exit 0
    elif command -v x-terminal-emulator &>/dev/null; then
        x-terminal-emulator -e "$0" "$@"
        exit 0
    elif command -v xterm &>/dev/null; then
        xterm -e "$0" "$@"
        exit 0
    fi
fi

echo -e "\033[0;36m=== Vencord Installer & Updater ===\033[0m"
curl -sSL https://raw.githubusercontent.com/Cryptorial0/ASS/master/vencord-updater | bash

echo ""
read -p "Press Enter to exit..." unused
