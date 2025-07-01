# 📷 YADCapture - Advanced Screen Capture Tool [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**A lightweight screenshot, GIF, and screen recording tool** with multi-language support for Linux.

![Captura de YAD](https://i.postimg.cc/NfV0S8hX/YADCapture.png)

![Screen Recorder](https://i.postimg.cc/1zM1hPgd/screen-recorder.png)

## ✨ Features

- 🖥️ All-in-One Capture:

    📸 Screenshots (PNG) - Fullscreen/window/region

    🎞️ GIF recordings - Custom duration & framerate

    🎥 Screen recordings (MP4) - With audio support

    Real-time preview with auto-detected players (mpv/mplayer/ffplay)

    Global keyboard shortcuts (Ctrl+F to pause, Ctrl+S to stop)

    System tray integration with status icons

🌍 Multi-language UI (ES, EN, FR, DE, IT, PT, RU, JA, ZH, and more)

- ⚙️ Customizable:

  - Countdown timer

  - GIF quality settings

  - Video resolution options

  - Output filename templates

  - xbindkeys configuration for custom shortcuts

## 🚀 Quick Start

### Dependencies
```bash
# Debian
sudo apt install yad ffmpeg scrot noto-fonts-emoji xbindkeys mpv

# Arch
sudo pacman -S yad ffmpeg scrot noto-fonts-emoji xbindkeys mpv

# Void
sudo xbps-install -Su yad ffmpeg scrot noto-fonts-emoji xbindkeys mpv

