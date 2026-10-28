# PhantomOS Plasma

PhantomOS is a themed Arch Linux desktop setup built around KDE Plasma 6 on Wayland. The `plasma` branch is a separate desktop flavor; it does not install or configure Hyprland.

## Install

Install Arch and Git, then run these commands as your regular user:

```sh
git clone --branch plasma https://github.com/PrizrakSHIZA/PhantomOS.git
cd PhantomOS
bash install.sh
```

The installer uses `sudo` for system packages and SDDM files. Do not run it with `sudo`. It installs Plasma, SDDM, Dolphin, Konsole, Spectacle, Kitty, micro, VS Code, btop, media players, audio tools, and networking utilities. Existing display manager selection is kept. NVIDIA drivers and boot settings are left alone. Configuration files that it replaces are backed up under `~/.local/share/phantomos/backups/`.

Automatic tiling uses Polonium, a KWin script available from the AUR. If `yay` is installed, the installer installs it with `yay -S --needed kwin-polonium`; otherwise install that package with your AUR helper. Polonium supports Plasma Wayland 6.4 and newer. After installation, log out, select **Plasma (Wayland)** at SDDM, and log in again so KWin loads the scripts.

For systems where the applications and desktop are already installed, use `bash install.sh --no-packages`.

## Included setup

- PhantomOS dark blue-violet KDE color scheme, plus Tokyo Night and Dracula palettes in `plasma/`.
- Polonium Binary Tree tiling and KWin floating layouts, with Meta+Tab toggle.
- Meta+Q opens Konsole; Meta+E opens Dolphin.
- Ctrl+Shift switches between US and Russian keyboard layouts.
- SDDM login theme and Plasma-aware autologin helper.
- `phantom settings` opens a PhantomOS menu with shortcuts to display, sound/equalizer, appearance, keyboard layouts, global shortcuts, mouse, network, login, startup apps, and user settings. The individual pages are KDE modules so their controls remain fully functional.
- Dolphin is the file manager; Haruna is the video player and Audacious is the music player.
- Spectacle captures directly to the clipboard: Print for all displays, Alt+Print for the active window, and Meta+Shift+S for a selected region.
- Kitty uses Ctrl+Alt+C/V for terminal copy and paste, leaving Ctrl+Shift available for layout switching.

## Commands

`phantom help` lists available actions. `phantom update` fetches the branch matching `~/.local/share/phantomos/desktop-flavor` and applies it without reinstalling packages. The updater does not update Arch packages; use `sudo pacman -Syu` for that. `phantom setup` reapplies the current checkout's user configuration.

`phantom work` and `phantom relax` select Polonium's Binary Tree or KWin engine for the current desktop/output. Meta+Tab toggles between them. Polonium retains its own per-desktop/output layout settings. KWin controls panel placement, virtual desktops, window decorations, animation, input, and display settings through KDE settings modules launched from the PhantomOS settings menu.

## Current Plasma scope

Polonium stores its tiling engine per virtual desktop and output. The current mode action changes the active desktop/output; synchronizing the mode across every monitor still needs a KWin integration pass. Plasma virtual desktops are shared by the display setup, so Relax mode does not yet reduce the system to one desktop per monitor. The panel profile moves existing Plasma panels and toggles their task manager widget; it does not create a missing panel on a monitor.

## Source layout

- `plasma/` contains the KDE color schemes and KWin mode-toggle script.
- `bin/` contains the `phantom` command and Plasma helpers.
- `assets/sddm/` contains the SDDM theme.
- `install.sh` is the Arch post-install setup.
- `packaging/aur/` is a local PKGBUILD draft for `phantomos-plasma-git`.

The Hyprland configuration remains in the repository for the separate `main` flavor. Do not run its installer on Plasma.
