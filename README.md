# PhantomOS Plasma

PhantomOS is a themed Arch Linux desktop setup built around KDE Plasma 6 on Wayland. The `plasma` branch is a separate desktop flavor; it does not install or configure Hyprland.

## Install

Install Arch and Git, then run these commands as your regular user:

```sh
git clone --branch plasma https://github.com/PrizrakSHIZA/PhantomOS.git
cd PhantomOS
bash install.sh
```

The installer uses `sudo` for system packages and SDDM files. Do not run it with `sudo`. It installs Plasma, SDDM, Dolphin, Konsole, Spectacle, WezTerm, Fish, Starship, Yazi, micro, VS Code, btop, media players, audio tools, and networking utilities. Existing display manager selection is kept. NVIDIA drivers and boot settings are left alone. Replaced user files and the original Plasma panel layout are backed up under `~/.local/share/phantomos/backups/`.

Automatic tiling uses Polonium, a KWin script available from the AUR. If `yay` or `paru` is installed, the installer installs it with that helper. Without Polonium, PhantomOS reports that tiling is unavailable instead of pretending to switch modes. Polonium supports Plasma Wayland 6.4 and newer. Sign out and back in after the first install so Plasma reloads the keyboard and global shortcuts.

For systems where the applications and desktop are already installed, use `bash install.sh --no-packages`. Run this from a Plasma session to apply the initial PhantomOS panel layout and wallpaper. Existing panels are backed up and replaced with PhantomOS panels. `phantom setup` reapplies that layout; `phantom update` leaves a customized layout alone.

## Included setup

- PhantomOS dark blue-violet KDE color scheme, plus Tokyo Night and Dracula palettes in `plasma/`.
- Polonium Binary Tree tiling and KWin floating layouts, with Meta+Tab toggle.
- In tiled mode Meta+Arrow switches focus, Meta+Shift+Arrow moves a window through the layout, and Meta+Ctrl+Arrow resizes tiles. Meta+Alt+Arrow quick-tiles floating windows.
- Meta+Tab toggles Work and Relax modes. Work mode places compact panels at the top without a window list. Relax mode moves each panel to the outside edge of its monitor and shows open windows there.
- Meta+Enter opens WezTerm; Meta+E opens Dolphin.
- The Kickoff Start menu uses the PhantomOS icon and includes PhantomOS Settings, mode actions, btop, Dolphin, and WezTerm. Papirus-Dark icons and the PhantomOS wallpaper are applied with the Tokyo Night color scheme.
- WezTerm runs Fish with a Tokyo Night palette and Starship prompt. Starship shows the directory path; Yazi provides a multi-pane file browser in the terminal. Ctrl+Alt+C/V copies and pastes so Ctrl+Shift can switch keyboard layouts.
- Ctrl+Shift switches between US and Russian keyboard layouts.
- SDDM login theme and Plasma-aware autologin helper.
- `phantom settings` opens the PhantomOS Settings Center: a blue-violet dashboard with Work/Relax controls, Tokyo Night and Dracula palettes, and shortcuts to display, sound/equalizer, keyboard layouts, global shortcuts, mouse, network, login, startup apps, and user settings. The individual pages use KDE's native modules.
- Dolphin is the file manager; Haruna is the video player and Audacious is the music player.
- Spectacle captures directly to the clipboard: Print for all displays, Alt+Print for the active window, and Meta+Shift+S for a selected region.

## Commands

`phantom help` lists available actions. `phantom update` fetches the branch matching `~/.local/share/phantomos/desktop-flavor` and applies it without reinstalling packages. The updater does not update Arch packages; use `sudo pacman -Syu` for that. `phantom setup` reapplies the current checkout's user configuration and rebuilds the PhantomOS panels from the current Plasma session.

`phantom work` and `phantom relax` select Polonium's Binary Tree or KWin engine for the current desktop/output. Meta+Tab toggles between them. Polonium retains its own per-desktop/output layout settings. KWin controls panel placement, virtual desktops, window decorations, animation, input, and display settings through KDE settings modules launched from the PhantomOS Settings Center.

## Current Plasma scope

Polonium stores its tiling engine per virtual desktop and output. The current mode action changes the active desktop/output; synchronizing the mode across every monitor still needs a KWin integration pass. Plasma virtual desktops are shared across displays, so Relax mode does not yet reduce the desktop count to one per monitor. Initial panel creation supports Plasma 6.3 and newer. The panel file is backed up before the PhantomOS layout is applied.

## Source layout

- `plasma/` contains KDE color schemes, the initial Plasma layout, WezTerm/Fish configuration, and the KWin mode-toggle script.
- `bin/` contains the `phantom` command and Plasma helpers.
- `assets/sddm/` contains the SDDM theme.
- `install.sh` is the Arch post-install setup.
- `packaging/aur/` is a local PKGBUILD draft for `phantomos-plasma-git`.

The Hyprland configuration remains in the repository for the separate `main` flavor. Do not run its installer on Plasma.
