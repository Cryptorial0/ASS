#!/usr/bin/env bash

# ============================================
# Arch Setup Script (ASS)
# Made with ⏻ by Cryptorial
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# ============================================

set -euo pipefail

LOG_FILE="$HOME/ass-install.log"
LOCK_FILE="$HOME/.ass_done"

# Initialize log file with a starting timestamp banner
echo "================================================================" > "$LOG_FILE"
echo " Arch Setup Script (ASS) - Installation Log                      " >> "$LOG_FILE"
echo " Timestamp: $(date)                                             " >> "$LOG_FILE"
echo "================================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# -----------------------------
# Color definitions & Styling
# -----------------------------
NC='\033[0m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

# Foreground Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Bold Colors
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BMAGENTA='\033[1;35m'
BCYAN='\033[1;36m'
BWHITE='\033[1;37m'
BORANGE='\033[1;38;5;208m'

# -----------------------------
# TUI Printing Functions
# -----------------------------
print_header() {
    clear
    echo -e "${BCYAN}================================================================${NC}"
    echo -e " ${BMAGENTA}█████╗ ███████╗███████╗${NC}   ${BWHITE}Arch Setup Script (ASS)${NC}"
    echo -e " ${BMAGENTA}██╔══██╗██╔════╝██╔════╝${NC}   ${BBLUE}Made with ⏻ by Cryptorial${NC}"
    echo -e " ${BMAGENTA}███████║███████╗███████╗${NC}"
    echo -e " ${BMAGENTA}██╔══██║╚════██║╚════██║${NC}"
    echo -e " ${BMAGENTA}██║  ██║███████║███████║${NC}"
    echo -e " ${BMAGENTA}╚═╝  ╚═╝╚══════╝╚══════╝${NC}"
    echo -e "${BCYAN}================================================================${NC}"
    echo ""
}

print_step() {
    local title="$1"
    echo -e "\n${BCYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BCYAN}│${NC} ${BWHITE}⚡ ${title}${NC}"
    echo -e "${BCYAN}└──────────────────────────────────────────────────────────────┘${NC}\n"
    echo -e "\n--- STEP: ${title} ---" >> "$LOG_FILE"
}

print_success() {
    echo -e "${BGREEN}✔${NC} $1"
    echo "✔ $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${BYELLOW}⚠${NC} ${BOLD}WARNING:${NC} $1"
    echo "⚠ WARNING: $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${BRED}✖${NC} ${BOLD}ERROR:${NC} $1"
    echo "✖ ERROR: $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${BBLUE}ℹ${NC} $1"
    echo "ℹ $1" >> "$LOG_FILE"
}

# -----------------------------
# Initial Startup Banner
# -----------------------------
print_header

# -----------------------------
# Safety checks
# -----------------------------
if [ "$EUID" -eq 0 ]; then
    print_error "Do not run as root."
    exit 1
fi

if [ -f "$LOCK_FILE" ]; then
    print_warning "Setup already completed. Remove ~/.ass_done to rerun."
    exit 0
fi

# -----------------------------
# Helper function for installing
# -----------------------------
run_install() {
    if [ "$#" -eq 0 ]; then return 0; fi
    echo -e "\n--- Installing packages: $@ ---" >> "$LOG_FILE"
    
    # Try to install all packages together first for efficiency
    if yay -S --needed --noconfirm --cleanmenu=false --diffmenu=false "$@" 2>&1 | tee -a "$LOG_FILE"; then
        return 0
    fi
    
    # If batch installation fails, fall back to installing individually
    print_warning "Batch installation failed. Attempting to install packages individually..."
    local failed_pkgs=()
    for pkg in "$@"; do
        print_info "Installing $pkg..."
        if ! yay -S --needed --noconfirm --cleanmenu=false --diffmenu=false "$pkg" 2>&1 | tee -a "$LOG_FILE"; then
            print_error "Failed to install $pkg"
            failed_pkgs+=("$pkg")
        fi
    done
    
    if [ ${#failed_pkgs[@]} -gt 0 ]; then
        print_warning "The following packages failed to install: ${failed_pkgs[*]}"
        return 1
    fi
    return 0
}

# -----------------------------
# Base setup & Repositories
# -----------------------------
print_step "Configuring Repositories"

# 1. Enable multilib
if grep -q "#\[multilib\]" /etc/pacman.conf; then
    print_info "Enabling [multilib] repository..."
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    print_success "[multilib] repository enabled."
else
    print_info "[multilib] repository is already active or not found."
fi

# 2. Speed Optimizations: Parallel Downloads & Multi-Core Compiling
if grep -q "#ParallelDownloads" /etc/pacman.conf; then
    print_info "Enabling parallel downloads in pacman.conf..."
    sudo sed -i 's/#ParallelDownloads = .*/ParallelDownloads = 10/' /etc/pacman.conf
    print_success "Parallel downloads enabled (set to 10 concurrent streams)."
elif grep -q "ParallelDownloads" /etc/pacman.conf; then
    print_info "Optimizing parallel downloads to 10 streams..."
    sudo sed -i 's/ParallelDownloads = .*/ParallelDownloads = 10/' /etc/pacman.conf
    print_success "Parallel downloads optimized."
fi

if [ -f /etc/makepkg.conf ] && grep -q "#MAKEFLAGS=" /etc/makepkg.conf; then
    cores=$(nproc)
    print_info "Configuring compiler to use all $cores CPU threads..."
    sudo sed -i "s/#MAKEFLAGS=.*/MAKEFLAGS=\"-j$cores\"/" /etc/makepkg.conf
    print_success "Compilation flags optimized for multi-threading (-j$cores)."
fi

# 3. Enable chaotic-aur
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    print_info "Configuring [chaotic-aur] repository..."
    print_info "Importing and signing chaotic-aur keys..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    print_info "Installing keyring and mirrorlist..."
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    print_info "Adding chaotic-aur to /etc/pacman.conf..."
    sudo bash -c 'cat >> /etc/pacman.conf <<EOF

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF'
    print_success "[chaotic-aur] repository added successfully."
else
    print_info "[chaotic-aur] repository is already active."
fi

print_info "Synchronizing package databases..."
sudo pacman -Sy 2>&1 | tee -a "$LOG_FILE"

print_step "Installing Base System Tools"
print_info "Installing git, base-devel, curl, wget, unzip, tar..."
sudo pacman -Syu --needed git base-devel curl wget unzip tar 2>&1 | tee -a "$LOG_FILE"

if ! command -v yay &> /dev/null; then
    print_info "Installing yay AUR helper..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm 2>&1 | tee -a "$LOG_FILE"
    cd ~
    print_success "yay installed successfully."
else
    print_info "yay is already installed."
fi

# -----------------------------
# GPU selection
# -----------------------------
print_step "GPU Driver Selection"
echo -e "${BWHITE}Select your GPU driver:${NC}"
echo -e "  ${BCYAN}1)${NC} AMD Radeon"
echo -e "  ${BCYAN}2)${NC} NVIDIA"
echo -e "  ${BCYAN}3)${NC} Intel (Integrated/Arc)"
echo -e "  ${BCYAN}4)${NC} Skip"
echo ""
read -p "  Your Choice [1-4]: " gpu_choice

gpu_pkgs=()
gpu="skip"

case "$gpu_choice" in
    1|amd|AMD)
        gpu="amd"
        gpu_pkgs=(vulkan-radeon lib32-vulkan-radeon mesa lib32-mesa)
        print_success "Selected AMD Radeon drivers."
        ;;
    2|nvidia|NVIDIA)
        gpu="nvidia"
        gpu_pkgs=(nvidia-settings)
        if pacman -Qq nvidia-utils &>/dev/null; then
            print_info "NVIDIA drivers (nvidia-utils) already detected. Skipping kernel module package to avoid conflicts."
            gpu_pkgs+=(lib32-nvidia-utils)
        else
            gpu_pkgs+=(nvidia nvidia-utils lib32-nvidia-utils)
        fi
        print_success "Selected NVIDIA proprietary drivers."
        ;;
    3|intel|Intel|INTEL)
        gpu="intel"
        gpu_pkgs=(vulkan-intel lib32-vulkan-intel mesa lib32-mesa intel-media-driver)
        print_success "Selected Intel drivers."
        ;;
    *)
        print_info "Skipping GPU driver installation."
        ;;
esac

# -----------------------------
# Browser selection
# -----------------------------
print_step "Browser Selection"
echo -e "${BWHITE}Select web browser to install:${NC}"
echo -e "  ${BCYAN}1)${NC} Vivaldi ${BGREEN}[Recommended]${NC}"
echo -e "  ${BCYAN}2)${NC} Firefox ${BYELLOW}[Furry/Gay]${NC}"
echo -e "  ${BCYAN}3)${NC} Google Chrome ${BRED}[حلتيتة]${NC}"
echo -e "  ${BCYAN}4)${NC} Opera GX ${BMAGENTA}[Extremely Gay]${NC}"
echo -e "  ${BCYAN}5)${NC} Microsoft Edge ${BBLUE}[Virgin]${NC}"
echo -e "  ${BCYAN}6)${NC} Brave ${BORANGE}[For Pussies]${NC}"
echo -e "  ${BCYAN}7)${NC} Skip"
echo ""
read -p "  Your Choice [1-7]: " browser_choice

browser_pkg=()

case "$browser_choice" in
    1) browser_pkg=(vivaldi) ;;
    2) browser_pkg=(firefox) ;;
    3) browser_pkg=(google-chrome) ;;
    4) browser_pkg=(opera-gx) ;;
    5) browser_pkg=(microsoft-edge-stable-bin) ;;
    6) browser_pkg=(brave-bin) ;;
    *) print_info "Skipping browser installation." ;;
esac

# -----------------------------
# Emulator selection
# -----------------------------
print_step "Emulator Selection"
echo -e "${BWHITE}Select emulators to install (enter numbers separated by spaces, or 'all', or 'none'):${NC}"
echo -e "  ${BCYAN}1)${NC} PCSX2 ${BWHITE}(PS2)${NC}"
echo -e "  ${BCYAN}2)${NC} RPCS3 ${BWHITE}(PS3)${NC}"
echo -e "  ${BCYAN}3)${NC} Dolphin ${BWHITE}(GameCube/Wii)${NC}"
echo -e "  ${BCYAN}4)${NC} PPSSPP ${BWHITE}(PSP)${NC}"
echo -e "  ${BCYAN}5)${NC} RetroArch ${BWHITE}(Multi-system)${NC}"
echo -e "  ${BCYAN}6)${NC} MAME ${BWHITE}(Arcade)${NC}"
echo -e "  ${BCYAN}7)${NC} DuckStation ${BWHITE}(PS1)${NC}"
echo -e "  ${BCYAN}8)${NC} Eden-git ${BWHITE}(Switch)${NC}"
echo ""
read -p "  Selection [1-8, all, none]: " emu_choice

emu_pkgs=()

case "${emu_choice,,}" in
    none|"")
        print_info "Skipping emulators..."
        ;;
    all)
        emu_pkgs=(pcsx2 rpcs3 dolphin-emu ppsspp retroarch mame duckstation-bin eden-git)
        print_success "Selected all emulators."
        ;;
    *)
        for choice in $emu_choice; do
            case "$choice" in
                1) emu_pkgs+=(pcsx2) ;;
                2) emu_pkgs+=(rpcs3) ;;
                3) emu_pkgs+=(dolphin-emu) ;;
                4) emu_pkgs+=(ppsspp) ;;
                5) emu_pkgs+=(retroarch) ;;
                6) emu_pkgs+=(mame) ;;
                7) emu_pkgs+=(duckstation-bin) ;;
                8) emu_pkgs+=(eden-git) ;;
                *) print_warning "Invalid choice: $choice, skipping..." ;;
            esac
        done
        print_success "Selected emulators: ${emu_pkgs[*]:-None}"
        ;;
esac

# -----------------------------
# Workstation packages
# -----------------------------
print_step "Workstation Packages"

# Define app names and package identifiers
app_names=(
    "Steam" "Goverlay" "Gamescope" "ProtonPlus" "ProtonUp-Qt" "Winetricks"
    "Protontricks" "vkBasalt" "MangoJuice" "MangoHud" "Hydra Launcher"
    "PortProton" "r2modman" "Prism Launcher" "CoreCtrl" "LACT (AMDGPU)"
    "OpenRGB" "pascube" "Vivaldi Browser" "Discord" "ZapZap (WhatsApp)"
    "Root App" "Vice Clipper" "Baobab" "Flatseal" "Ventoy USB" "KDE Connect"
    "LocalSend" "Iriun Webcam" "PCSX2 Emulator" "Decaf Emulator (Wii U)" "DuckStation Emulator"
    "VLC Media Player" "qBittorrent" "Stremio" "Parabolic" "Spotify"
    "LosslessCut" "Songrec (Shazam)" "btop" "fastfetch" "bazaar"
)

app_pkgs=(
    "steam" "goverlay" "gamescope" "protonplus" "protonup-qt" "winetricks"
    "protontricks" "vkbasalt" "mangojuice" "mangohud" "hydra-launcher-bin"
    "portproton" "r2modman-bin" "prismlauncher" "corectrl" "lact"
    "openrgb" "pascube" "vivaldi" "discord" "zapzap"
    "rootapp-bin" "vice-clipper" "baobab" "flatseal" "ventoy-bin" "kdeconnect"
    "localsend-bin" "iriunwebcam-bin" "pcsx2" "decaf-emu-git" "duckstation-bin"
    "vlc" "qbittorrent" "stremio" "parabolic" "spotify"
    "losslesscut-bin" "songrec" "btop" "fastfetch" "bazaar"
)

# Initialize all selections to 1 (checked) by default
num_apps=${#app_names[@]}
selections=()
for ((i=0; i<num_apps; i++)); do
    selections+=(1)
done

is_first_prompt=1

while true; do
    # Clear screen for subsequent prompts to look super clean
    if [ "$is_first_prompt" -eq 0 ]; then
        clear
        print_header
        print_step "Workstation Packages"
    fi
    is_first_prompt=0

    echo -e "${BWHITE}Select workstation packages to install:${NC}"
    echo -e "  - ${BGREEN}[✔]${NC} indicates the package is selected."
    echo -e "  - Enter numbers (separated by spaces) to ${BOLD}toggle${NC} checkmarks (e.g. 1 14 32)."
    echo -e "  - Type ${BCYAN}0${NC} to deselect ALL packages (None)."
    echo -e "  - Press ${BCYAN}[Enter]${NC} (empty input) to confirm and continue (default is all checked)."
    echo ""

    # Print selection menu in 2 columns
    half=$(( (num_apps + 1) / 2 ))
    for ((i=0; i<half; i++)); do
        # Column 1
        idx1=$i
        num1=$((idx1 + 1))
        char1=" "
        [ "${selections[idx1]}" -eq 1 ] && char1="${BGREEN}✔${NC}"
        col1_text=$(printf "%2d) [%b] %-25s" "$num1" "$char1" "${app_names[idx1]}")
        
        # Column 2
        idx2=$((i + half))
        if [ "$idx2" -lt "$num_apps" ]; then
            num2=$((idx2 + 1))
            char2=" "
            [ "${selections[idx2]}" -eq 1 ] && char2="${BGREEN}✔${NC}"
            col2_text=$(printf "%2d) [%b] %s" "$num2" "$char2" "${app_names[idx2]}")
            echo -e "  $col1_text    $col2_text"
        else
            echo -e "  $col1_text"
        fi
    done

    echo ""
    read -p "  Selection_Input (0=None, Empty=Default/Confirm): " selection_input

    # Empty input -> confirm selections and continue
    if [ -z "$selection_input" ]; then
        break
    fi

    # 0 -> deselect all
    if [ "$selection_input" = "0" ]; then
        for ((i=0; i<num_apps; i++)); do
            selections[i]=0
        done
        continue
    fi

    # Toggle checkmarks for numbers entered
    for val in $selection_input; do
        if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -ge 1 ] && [ "$val" -le "$num_apps" ]; then
            idx=$((val - 1))
            if [ "${selections[idx]}" -eq 1 ]; then
                selections[idx]=0
            else
                selections[idx]=1
            fi
        else
            print_warning "Invalid number: $val. Skipping..."
            sleep 1
        fi
    done
done

# Assemble main_pkgs based on final checkmarks
main_pkgs=()
for ((i=0; i<num_apps; i++)); do
    if [ "${selections[i]}" -eq 1 ]; then
        main_pkgs+=("${app_pkgs[i]}")
    fi
done

print_success "Selected workstation packages."

# -----------------------------
# Desktop Environment Auto-Detection
# -----------------------------
print_step "Desktop Environment Auto-Detection"
print_info "Detecting Desktop Environment..."
DE="unknown"

if [[ "${XDG_CURRENT_DESKTOP,,}" == *"kde"* ]]; then
    DE="kde"
    print_success "Detected KDE Plasma (or Garuda Mokka)"
elif [[ "${XDG_CURRENT_DESKTOP,,}" == *"cinnamon"* ]]; then
    DE="cinnamon"
    print_success "Detected Cinnamon"
else
    DE="other"
    print_info "Detected other DE or TTY: ${XDG_CURRENT_DESKTOP:-None}"
fi

core_pkgs=(
    gamemode lib32-gamemode
    mangohud lib32-mangohud
    vulkan-tools
    libdrm lib32-libdrm
    pipewire pipewire-alsa pipewire-pulse wireplumber
    flatpak
)

if [[ "$DE" == "kde" ]]; then
    core_pkgs+=(plasma-browser-integration)
fi

# -----------------------------
# Summary of packages to install
# -----------------------------
print_step "Installation Summary"
echo -e "${BCYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BCYAN}│${NC}               ${BWHITE}INSTALLATION PLAN SUMMARY${NC}                      ${BCYAN}│${NC}"
echo -e "${BCYAN}└──────────────────────────────────────────────────────────────┘${NC}"
echo -e " ${BOLD}The script will install the following components:${NC}"
echo ""
echo -e "  ${BWHITE}• GPU Drivers:${NC}  ${BMAGENTA}${gpu:-skip}${NC} (${gpu_pkgs[*]:-None})"
echo -e "  ${BWHITE}• Browser:${NC}      ${BCYAN}${browser_pkg[*]:-None}${NC}"
echo -e "  ${BWHITE}• Core System:${NC}  ${BWHITE}${core_pkgs[*]}${NC}"
echo -e "  ${BWHITE}• Main Apps:${NC}     ${BWHITE}${main_pkgs[*]:-None}${NC}"
if [ ${#emu_pkgs[@]} -gt 0 ]; then
echo -e "  ${BWHITE}• Emulators:${NC}     ${BWHITE}${emu_pkgs[*]}${NC}"
else
echo -e "  ${BWHITE}• Emulators:${NC}     ${BRED}None${NC}"
fi
echo ""
echo -e "${BCYAN}├──────────────────────────────────────────────────────────────┤${NC}"
echo -e "  ${BMAGENTA}YAY / AUR PACKAGES TO BE INSTALLED:${NC}"
echo -e "${BCYAN}├──────────────────────────────────────────────────────────────┤${NC}"
yay_install_list=()
for pkg in "${browser_pkg[@]}" "${emu_pkgs[@]}" "${main_pkgs[@]}"; do
    case "$pkg" in
        google-chrome|microsoft-edge-stable-bin|brave-bin|eden-git|protonplus|mangojuice|stremio|losslesscut-bin|spotify|hydra-launcher-bin|portproton|parabolic|iriunwebcam-bin|localsend-bin|decaf-emu-git|r2modman-bin|zapzap|rootapp-bin|vice-clipper|pascube|ventoy-bin|opera-gx|duckstation-bin)
            yay_install_list+=("$pkg")
            ;;
    esac
done
if [ ${#yay_install_list[@]} -gt 0 ]; then
    for y_pkg in "${yay_install_list[@]}"; do
        echo -e "  ${BGREEN}•${NC} ${BWHITE}$y_pkg${NC} (AUR / Chaotic-AUR)"
    done
else
    echo -e "  ${BYELLOW}•${NC} None"
fi

echo ""
echo -e "${BCYAN}├──────────────────────────────────────────────────────────────┤${NC}"
echo -e "  ${BMAGENTA}FLATPAK PACKAGES TO BE INSTALLED:${NC}"
echo -e "${BCYAN}├──────────────────────────────────────────────────────────────┤${NC}"
echo -e "  ${BGREEN}•${NC} ${BWHITE}com.dec05eba.gpu_screen_recorder${NC}"
echo -e "${BCYAN}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""
read -p "Press [Enter] to begin installation or [Ctrl+C] to abort..."

# -----------------------------
# Install everything
# -----------------------------
print_step "Starting Installation"

print_info "Installing core system and drivers..."
run_install "${core_pkgs[@]}" "${gpu_pkgs[@]}" || print_warning "Core installation had errors."

if [ ${#browser_pkg[@]} -gt 0 ]; then
    print_info "Installing browser..."
    b_pkg="${browser_pkg[0]}"
    print_info "Attempting to install $b_pkg via pacman/yay..."
    if ! run_install "$b_pkg"; then
        print_warning "$b_pkg installation via pacman/yay failed. Falling back to Flatpak..."
        
        # Ensure flatpak flathub repository is registered
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
        
        # Map to Flatpak ID
        flatpak_id=""
        case "$b_pkg" in
            vivaldi) flatpak_id="com.vivaldi.Vivaldi" ;;
            firefox) flatpak_id="org.mozilla.firefox" ;;
            google-chrome) flatpak_id="com.google.Chrome" ;;
            opera-gx) flatpak_id="com.opera.GX" ;;
            microsoft-edge-stable-bin) flatpak_id="com.microsoft.Edge" ;;
        esac
        
        if [ -n "$flatpak_id" ]; then
            print_info "Installing $flatpak_id via Flathub..."
            if flatpak install -y flathub "$flatpak_id" 2>&1 | tee -a "$LOG_FILE"; then
                print_success "Installed $b_pkg successfully via Flatpak ($flatpak_id)."
            else
                print_error "Failed to install $b_pkg via both native and Flatpak channels."
            fi
        else
            print_error "No Flatpak fallback found for browser: $b_pkg"
        fi
    else
        print_success "Installed $b_pkg successfully."
    fi
fi

if [ ${#main_pkgs[@]} -gt 0 ]; then
    print_info "Installing main workstation packages..."
    run_install "${main_pkgs[@]}" || print_warning "Workstation installation had errors."
fi

if [ ${#emu_pkgs[@]} -gt 0 ]; then
    print_info "Installing emulators..."
    run_install "${emu_pkgs[@]}" || print_warning "Some emulators failed to install."
fi

# -----------------------------
# Extras
# -----------------------------
print_step "Applying Extras & Finalizing"

print_info "Adding Flathub remote to Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>&1 | tee -a "$LOG_FILE" || true

print_info "Installing GPU Screen Recorder via Flatpak..."
flatpak install -y flathub com.dec05eba.gpu_screen_recorder 2>&1 | tee -a "$LOG_FILE" || true

print_info "Enabling GameMode user service..."
systemctl --user enable --now gamemoded || true

print_info "Creating vencord installer command..."
sudo bash -c 'cat > /usr/local/bin/vencord <<EOF
#!/bin/sh
sh -c "\$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
EOF'
sudo chmod +x /usr/local/bin/vencord
print_success "Created executable vencord helper in /usr/local/bin/vencord"


# -----------------------------
# Finish
# -----------------------------
touch "$LOCK_FILE"

print_step "Setup Complete!"
print_success "All requested packages and configurations have been deployed."
print_info "Log file saved to: ${BWHITE}$LOG_FILE${NC}"
print_info "A system reboot is highly recommended."
echo ""
