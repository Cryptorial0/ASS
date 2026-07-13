# ASS: Arch Setup Script

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

```
█████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔════╝
███████║███████╗███████╗
██╔══██║╚════██║╚════██║
██║  ██║███████║███████║
╚═╝  ╚═╝╚══════╝╚══════╝
```

A post-installation setup script to configure a fresh Arch Linux installation. 

Developed by Cryptorial.

---

## Features

*   **GPU Driver Setup:** Queries and installs drivers and Vulkan configurations based on your hardware (AMD, NVIDIA, Intel).
*   **Browser Selection:** Prompts to install Vivaldi, Firefox, Google Chrome, Opera GX, Edge, or Brave.
*   **TUI Interface:** A clean terminal user interface with step headers and status indicators for readability.
*   **Emulator Stack:** Choose which emulators to install (PS1, PS2, PS3, GameCube/Wii, PSP, Switch, Arcade, RetroArch) or skip entirely.
*   **Repository Configuration:** Enables the `[multilib]` repository and configures `[chaotic-aur]` for pre-compiled AUR packages.
*   **Desktop Environment Detection:** Detects KDE Plasma (including Garuda Mokka) or Cinnamon and loads DE-specific system integrations.
*   **Installation Modes:**
    *   **Default Suite:** Installs a predefined collection of apps for gaming, development, and media (Steam, Discord, Docker, Neovim, Spotify, etc.).
    *   **Pick & Choose:** Select specific suites or standalone applications to deploy.
*   **Logging:** Outputs installation logs to `~/ass-install.log`.

---

## Repositories & Packages

### Configured Repositories
*   **`[multilib]`**: Enabled to support 32-bit applications and libraries.
*   **`[chaotic-aur]`**: Speeds up installation of AUR software by using pre-compiled binaries.

### Yay / AUR Packages
The script can install the following AUR packages via `yay`/`chaotic-aur`:
*   `spotify` — Desktop music client.
*   `stremio` — Streaming media hub.
*   `losslesscut-bin` — Lossless video and audio editor.
*   `protonplus-bin` — Proton compatibility tool manager.
*   `proton-ge-custom-bin` — Custom GE-Proton build.
*   `mangojuice` — MangoHud companion and launcher helper.
*   `hydra-launcher-bin` — Gaming client and library manager.
*   `portproton` — Interface for launching Windows games using Proton.
*   `lact-bin` — Linux AMDGPU Controller tool.
*   `parabolic` — Media downloader for web videos and audio files.
*   `iriunwebcam-bin` — Smartphone webcam application.
*   `localsend-bin` — Local network file sharing utility.
*   `cemu` / `decaf-emu-git` — Wii U game emulation.
*   `r2modman-bin` — Mod manager for games like Risk of Rain 2.
*   `zapzap` — Native WhatsApp client.
*   `rootapp-bin` — Discord alternative.
*   `vice-clipper-bin` — Clipboard manager.
*   `pascube` — Vulkan spinning cube benchmark tool.
*   `ventoy-bin` — Multi-boot USB solution.
*   `duckstation-bin` — PlayStation 1 emulator.
*   `eden-git` — Switch emulator.
*   `google-chrome` — Web browser.
*   `microsoft-edge-stable-bin` — Web browser.

### Flatpak Packages
*   `com.dec05eba.gpu_screen_recorder` — Desktop screen recorder.

### Custom CLI Commands
*   **`vencord`** — A shortcut script placed in `/usr/local/bin` to run the official Vencord installer.

---

## Quick Start

### Option 1: One-Line Run (Recommended)
Open a terminal and run:
```bash
curl -sL https://raw.githubusercontent.com/Cryptorial0/ASS/master/ASS.sh -o /tmp/ASS.sh && bash /tmp/ASS.sh
```

### Option 2: Manual Clone & Run
1. Clone the repository:
   ```bash
   git clone https://github.com/Cryptorial0/ASS.git
   cd ASS
   ```

2. Make the script executable:
   ```bash
   chmod +x ASS.sh
   ```

3. Run it:
   ```bash
   ./ASS.sh
   ```

---

## Under The Hood

*   **Safety Lock:** Creates a `~/.ass_done` file upon completion to prevent accidental double-executions. Delete this file to rerun the script.
*   **AUR Integration:** Checks for `yay` and automatically installs it if missing.
*   **System Tweaks:** Enables the Feral Interactive GameMode daemon (`gamemoded`).

---

## License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.
