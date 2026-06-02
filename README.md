<div align="center">
    <img src="_assets/readme/TSP-Logo.png">
    
_Get the best from your TrimUI Smart Pro_  
</div>


<div align="center">
  <a href="https://github.com/pietrondo/CrossMix-OS/releases/latest">
    <img src="_assets/readme/download.png" alt="Download" style="width: 300px;">
  </a>
</div>

&nbsp;<br/>



<p>&nbsp;</p>

![bar](https://github.com/user-attachments/assets/730a4dd6-5f33-4274-9959-b188f3013142)

<p>&nbsp;</p>

<p align="center"><img src="https://github.com/user-attachments/assets/2339e8fd-cdac-4d2b-938b-edae23facb82" width="200"></p>

&nbsp;<br/>


# Introduction

CrossMix-OS, the OS which elevates your TrimUI Smart Pro to new heights. 

CrossMix-OS uses TrimUI Stock user interface with refined configurations, new features, new emulators and new apps. There are so many differences that CrossMix can be considered an dédicated OS in its own right.

Designed with the community in mind, CrossMix-OS caters to developers and creators alike. It supports a wide range of customizations, including themes, icon packs, background packs, templates for "Best" collections, and automatic overlay configurations.

As a completely free and open-source platform, CrossMix-OS invites you to explore, contribute, and customize to your heart's content.

&nbsp;<br/>&nbsp;<br/>


![bar](https://github.com/user-attachments/assets/730a4dd6-5f33-4274-9959-b188f3013142)

&nbsp;<br/>

# Getting Started

First take a look to CrossMix Wiki, below are the different sections:

&nbsp;<br/>

## 🏠[Home](https://github.com/pietrondo/CrossMix-OS/wiki/Home)

## 🛠️ [Installation](https://github.com/pietrondo/CrossMix-OS/wiki/Installation)

## 🎮 [Emulators](https://github.com/pietrondo/CrossMix-OS/wiki/Emulators)

## <img src="https://avatars.githubusercontent.com/u/96267164?s=200&v=4" width="20"> [PortMaster](https://github.com/pietrondo/CrossMix-OS/wiki/PortMaster)

## :iphone: [Apps](https://github.com/pietrondo/CrossMix-OS/wiki/apps)

## ⌨️ [Shortcuts](https://github.com/pietrondo/CrossMix-OS/wiki/shortcuts)

## ❔ [FAQ](https://github.com/pietrondo/CrossMix-OS/wiki/FAQ)

## 🔄 [Updating CrossMix-OS](https://github.com/pietrondo/CrossMix-OS/wiki/Updating)

Three ways to get the latest version:

1. **Updates App** (SD card, no WiFi needed): Download `CrossMix-OS_v*.zip` from [Releases](https://github.com/pietrondo/CrossMix-OS/releases/latest) on your PC, copy to SD root, then open **Apps > Updates** on your device. The update is verified with SHA256 before installation, and automatically rolls back if something goes wrong.
2. **OTA Update** (WiFi required): Connect to WiFi, then open **Apps > OTA update**.
3. **Auto-detection at boot**: If a `CrossMix-OS_v*.zip` is on the SD root, the system prompts to install at boot.

## 🔧 [Advanced Guides](https://github.com/pietrondo/CrossMix-OS/wiki/Advanced-Guides)

## 🛈 [About](https://github.com/pietrondo/CrossMix-OS/wiki/About)

## 🎁 [Contributing](https://github.com/pietrondo/CrossMix-OS/wiki/Contributing)

&nbsp;<br/>

## 📋 Changelog

### v1.6.0 - CrossMix-Pit Edition
- **Firmware 1.1.1**: piena compatibilita' con l'ultimo TrimUI stock firmware
- **8 nuovi core**: bsnes, doukutsu_rs, emuscv, mednafen_psx_hw, smsplus, onsyuri, libgametank, puzzlescript
- **SMS (Sega Master System)**: nuovo emulatore con core smsplus
- **19 core grandi**: scaricati automaticamente da upstream nella release zip (MAME, Flycast, FB Neo, etc.)
- **`make_release.ps1`**: script PowerShell per costruire lo zip release con tutti i core
- **`download_cores.sh`**: script on-device per aggiornare i core
- **Test automatizzati**: `tests/run_tests.sh` per verifica funzioni critiche
- Rimossi emulatori non richiesti (Apple II, J2ME, Vircon32)

### v1.5.0
- Rollback automatico, SHA256 verification, progress bar durante estrazione
- CI/CD: checksum SHA256 generato per ogni release

### v1.4.0
- Apps/Updates, sicurezza TLS, SHA1 verification, set -u, env.sh centralizzato
- 132 core RetroArch aggiornati da upstream aarch64

&nbsp;<br/>&nbsp;<br/>

![bar](https://github.com/user-attachments/assets/730a4dd6-5f33-4274-9959-b188f3013142)

<p>&nbsp;</p>

# Some words from the author

I'm Cizia, a passionate retrogamer. I love the TrimUI Smart Pro, but I felt it deserved a more mature OS, better configured, and with more options. I worked tirelessly to create an image that meets my standards, and today, I'm sharing it with you.

There are some features I'm particularly proud of, such as:

- **Background and icon selectors**: it completes well the native theme selector.
- **Overlay selector**: Configure your default display ratio and overlay in one click for all platforms, plus new dedicated overlays.
- **SwanStation 16/9 mode launcher**.
- **Extensive work on emulator launchers and configuration**.
- **Default customization of the OS**: custom theme, icons and backgrounds, Polish language added and many new tools.
- **Firmware Update Wizard**: an automatic guide to help user to update if necessary.
- **Best packs standardization**: generic launcher, game shortcuts support and images on folders.

I would also like to extend a warm thank you to Kloptops for [PortMaster and his tools](https://github.com/kloptops/TRIMUI_EX) which are deeply used in CrossMix-OS.

Thanks to Schmurtzm for his numerous scripts, I have revised and integrated them into CrossMix-OS, which have greatly enhanced the available features:
- [PSX Analog Detector](https://github.com/schmurtzm/TrimUI-Smart-Pro/blob/main/SystemTools/Apps/SystemTools/Menu/EMULATORS/PSX%20Analog%20Detector.sh): Detects PSX games compatible with analog sticks and automatically sets the correct controller configuration.
- [BootLogo](https://github.com/schmurtzm/TrimUI-Smart-Pro/tree/main/Bootlogo): An app for easy boot logo flashing on TrimUI Smart Pro.
- [EmuCleaner](https://github.com/schmurtzm/TrimUI-Smart-Pro/tree/main/EmuCleaner): An app to display only emulators with ROMs installed.
- [System Tools](https://github.com/schmurtzm/TrimUI-Smart-Pro/tree/main/SystemTools): An app to centralize different apps/scripts in one place.
- [Resume at Boot](https://github.com/schmurtzm/TrimUI-Smart-Pro/tree/main/ResumeAtBoot): A set of scripts to add a resume game on startup feature.
- [Subfolder config override finder](https://github.com/libretro/RetroArch/issues/12021#issuecomment-2107300989) is also used in CrossMix-OS.
- [Scraper](https://github.com/schmurtzm/TrimUI-Smart-Pro/tree/main/Scraper): an app to automatically download boxarts.


I hope CrossMix-OS will become a reference among OSes based on the stock OS and continue to improve with community support.

&nbsp;<br/>&nbsp;<br/>

![bar](https://github.com/user-attachments/assets/730a4dd6-5f33-4274-9959-b188f3013142)

<p>&nbsp;</p>

## Help the CrossMix-OS project

I have more ideas and improvements for this project, and you might have some too. Don't hesitate to share them!

Contribute to this repo by making a Pull Request. If you have an improvement to propose and don't know how to use GitHub, send me a message!

Feel free to reach out to me to report bugs, request features, or just chat on **[Discord](https://discord.gg/Jd2azKX)** or on **[Github Issues](https://github.com/pietrondo/CrossMix-OS/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc)**

If you enjoy my work and want to support the countless hours/days invested, here are my sponsors:

- [![Patreon](_assets/readme/patreon.png)](https://patreon.com/Cizia)
- [![Buy Me a Coffee](_assets/readme/bmc.png)](https://www.buymeacoffee.com/cizia)
- [![ko-fi](_assets/readme/ko-fi.png)](https://ko-fi.com/H2H7YPH3H)


