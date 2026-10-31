#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$DATA_HOME/phantomos/backups"
NO_PACKAGES=0
RESET_LAYOUT=0

usage() {
    cat <<'EOF'
PhantomOS Plasma setup for Arch Linux
Usage: ./install.sh [--no-packages] [--reset-layout]
  --no-packages  Skip pacman/AUR packages; install user configuration only.
  --reset-layout Rebuild the PhantomOS Plasma panels and wallpaper.
  -h, --help     Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --no-packages) NO_PACKAGES=1 ;;
        --reset-layout) RESET_LAYOUT=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ $EUID -eq 0 ]]; then
    printf 'Run as your regular user; the installer calls sudo when needed.\n' >&2
    exit 1
fi
if [[ ! -f "$ROOT_DIR/bin/phantom" || ! -f "$ROOT_DIR/desktop-flavor" ]]; then
    printf 'Run install.sh from the PhantomOS project directory.\n' >&2
    exit 1
fi

if ((NO_PACKAGES == 0)); then
    command -v pacman >/dev/null 2>&1 || { echo 'This installer expects Arch Linux and pacman.' >&2; exit 1; }
    command -v sudo >/dev/null 2>&1 || { echo 'Install sudo, then rerun ./install.sh.' >&2; exit 1; }
    packages=(
        plasma-meta plasma-workspace plasma-nm plasma-pa plasma-browser-integration sddm-kcm kdialog
        kde-gtk-config kscreen sddm dolphin konsole spectacle ark kate gtk3 python-gobject qt6-tools
        wezterm fish starship yazi micro python git btop code
        audacious haruna xdg-utils
        pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber easyeffects lsp-plugins-lv2 pavucontrol
        networkmanager bluez bluez-utils blueman
        xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-gtk
        grim slurp wl-clipboard imagemagick
        papirus-icon-theme ttf-jetbrains-mono-nerd ttf-font-awesome noto-fonts noto-fonts-emoji
        adw-gtk-theme breeze-gtk desktop-file-utils
    )
    printf 'Installing the Plasma desktop and PhantomOS applications. NVIDIA drivers and bootloader settings are left untouched.\n'
    sudo pacman -S --needed "${packages[@]}"

    # Polonium is an AUR KWin script. Install it only through the user's existing AUR helper.
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed kwin-polonium || printf 'WARNING: Polonium installation failed; automatic tiling will stay disabled.\n' >&2
    elif command -v paru >/dev/null 2>&1; then
        paru -S --needed kwin-polonium || printf 'WARNING: Polonium installation failed; automatic tiling will stay disabled.\n' >&2
    else
        printf 'WARNING: No AUR helper found. Install kwin-polonium with yay or paru to enable automatic tiling.\n' >&2
    fi

    sudo install -D -o root -g root -m 0755 "$ROOT_DIR/bin/phantomos-sddm-autologin" /usr/lib/phantomos/phantomos-sddm-autologin
    sudo install -D -o root -g root -m 0644 "$ROOT_DIR/assets/sddm/phantomos/Main.qml" /usr/share/sddm/themes/phantomos/Main.qml
    sudo install -D -o root -g root -m 0644 "$ROOT_DIR/assets/sddm/phantomos/metadata.desktop" /usr/share/sddm/themes/phantomos/metadata.desktop
    sudo install -D -o root -g root -m 0644 "$ROOT_DIR/assets/sddm/phantomos/theme.conf" /usr/share/sddm/themes/phantomos/theme.conf
    sudo install -D -o root -g root -m 0644 "$ROOT_DIR/assets/sddm/90-phantomos-theme.conf" /etc/sddm.conf.d/90-phantomos-theme.conf
    if command -v systemctl >/dev/null 2>&1; then
        if ! systemctl is-enabled --quiet display-manager.service; then
            sudo systemctl enable sddm.service
        else
            printf 'An existing display manager is enabled; SDDM is installed but not selected.\n'
        fi
        if ! systemctl is-active --quiet bluetooth.service; then sudo systemctl enable --now bluetooth.service; fi
        if ! systemctl is-active --quiet NetworkManager.service; then
            active_network=0
            for service in systemd-networkd.service iwd.service dhcpcd.service; do
                if systemctl is-active --quiet "$service" || systemctl is-enabled --quiet "$service"; then active_network=1; break; fi
            done
            if ((active_network == 0)); then sudo systemctl enable --now NetworkManager.service; fi
        fi
    fi
fi

POLONIUM_AVAILABLE=0
if command -v pacman >/dev/null 2>&1 && pacman -Qq kwin-polonium >/dev/null 2>&1; then POLONIUM_AVAILABLE=1; fi

mkdir -p "$CONFIG_HOME/wezterm" "$CONFIG_HOME/fish" "$CONFIG_HOME" "$DATA_HOME/color-schemes" "$DATA_HOME/applications" \
    "$DATA_HOME/icons/hicolor/scalable/apps" \
    "$HOME/.local/bin" "$HOME/.local/share/phantomos/wallpapers" "$STATE_HOME/phantomos"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_and_install() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname -- "$dst")"
    if [[ -e "$dst" ]] && ! cmp -s -- "$src" "$dst"; then
        local backup="$BACKUP_ROOT/$timestamp${dst#"$HOME"}"
        mkdir -p "$(dirname -- "$backup")"
        cp -a -- "$dst" "$backup"
        printf 'Backed up %s -> %s\n' "$dst" "$backup"
    fi
    install -m 0644 -- "$src" "$dst"
}

backup_and_install "$ROOT_DIR/plasma/PhantomOS.colors" "$DATA_HOME/color-schemes/PhantomOS.colors"
backup_and_install "$ROOT_DIR/plasma/PhantomOS-Dracula.colors" "$DATA_HOME/color-schemes/PhantomOS-Dracula.colors"
backup_and_install "$ROOT_DIR/assets/icons/hicolor/scalable/apps/phantomos.svg" "$DATA_HOME/icons/hicolor/scalable/apps/phantomos.svg"
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 --type KWin/Script --upgrade "$ROOT_DIR/plasma/PhantomOSToggle" >/dev/null 2>&1 || \
        kpackagetool6 --type KWin/Script --install "$ROOT_DIR/plasma/PhantomOSToggle"
fi
backup_and_install "$ROOT_DIR/plasma/wezterm.lua" "$CONFIG_HOME/wezterm/wezterm.lua"
backup_and_install "$ROOT_DIR/plasma/starship.toml" "$CONFIG_HOME/starship.toml"
backup_and_install "$ROOT_DIR/plasma/config.fish" "$CONFIG_HOME/fish/config.fish"
backup_and_install "$ROOT_DIR/bin/phantomosctl" "$HOME/.local/bin/phantomosctl"
backup_and_install "$ROOT_DIR/bin/phantomos-settings" "$HOME/.local/bin/phantomos-settings"
backup_and_install "$ROOT_DIR/autostart/phantomos-work-mode.desktop" "$CONFIG_HOME/autostart/phantomos-work-mode.desktop"
if [[ "${PHANTOMOS_PACKAGE_MODE:-0}" != 1 ]]; then backup_and_install "$ROOT_DIR/bin/phantom" "$HOME/.local/bin/phantom"; fi
backup_and_install "$ROOT_DIR/assets/phantomos-night.png" "$HOME/.local/share/phantomos/wallpapers/phantomos-night.png"
backup_and_install "$ROOT_DIR/desktop-flavor" "$DATA_HOME/phantomos/desktop-flavor"
for desktop in "$ROOT_DIR"/applications/*.desktop; do
    destination="$DATA_HOME/applications/$(basename "$desktop")"
    if grep -Eq '@(PHANTOMOS_SETTINGS|PHANTOMOSCTL)@' "$desktop"; then
        rendered_desktop="$(mktemp)"
        sed \
            -e "s|@PHANTOMOS_SETTINGS@|$HOME/.local/bin/phantomos-settings|g" \
            -e "s|@PHANTOMOSCTL@|$HOME/.local/bin/phantomosctl|g" \
            "$desktop" >"$rendered_desktop"
        backup_and_install "$rendered_desktop" "$destination"
        rm -f -- "$rendered_desktop"
    else
        backup_and_install "$desktop" "$destination"
    fi
done
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database "$DATA_HOME/applications"; fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then gtk-update-icon-cache -f "$DATA_HOME/icons/hicolor" >/dev/null 2>&1 || true; fi
chmod 0755 "$HOME/.local/bin/phantomosctl" "$HOME/.local/bin/phantomos-settings"
if [[ "${PHANTOMOS_PACKAGE_MODE:-0}" != 1 ]]; then chmod 0755 "$HOME/.local/bin/phantom"; fi

appearance_revision=2
current_appearance="$(cat "$STATE_HOME/phantomos/appearance-revision" 2>/dev/null || true)"
if [[ "$current_appearance" != "$appearance_revision" ]]; then
    if command -v plasma-apply-colorscheme >/dev/null 2>&1 && plasma-apply-colorscheme PhantomOS; then
        kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark 2>/dev/null || true
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze 2>/dev/null || true
        printf '%s\n' "$appearance_revision" >"$STATE_HOME/phantomos/appearance-revision"
    else
        printf 'PhantomOS color scheme is installed; select it in System Settings > Colors.\n'
    fi
fi
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication wezterm
    kwriteconfig6 --file kdeglobals --group General --key TerminalService org.wezfurlong.wezterm.desktop
    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled true
    kwriteconfig6 --file kwinrc --group Effect-Blur --key BlurStrength 5
    kwriteconfig6 --file kwinrc --group Plugins --key poloniumEnabled true
    kwriteconfig6 --file kwinrc --group Script-polonium --key EngineType 0
    kwriteconfig6 --file kwinrc --group Script-polonium --key Borders 4
    kwriteconfig6 --file kwinrc --group Script-polonium --key TiledWindowsBelow true
    kwriteconfig6 --file kwinrc --group Plugins --key phantomos-toggleEnabled true
    kwriteconfig6 --file kwinrc --group Script-phantomos-toggle --key PoloniumAvailable "$([[ $POLONIUM_AVAILABLE == 1 ]] && printf true || printf false)"
    kwriteconfig6 --file kwinrc --group Desktops --key Number 5
    kwriteconfig6 --file kwinrc --group Desktops --key Rows 1
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows" "none,none,Walk Through Windows"
    for direction in Left Right Up Down; do
        polonium_direction="$direction"
        case "$direction" in Up) polonium_direction=Above ;; Down) polonium_direction=Below ;; esac
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "PoloniumActivate$polonium_direction" "Meta+$direction,none,Polonium: Activate $polonium_direction"
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "PoloniumPlace$polonium_direction" "Meta+Shift+$direction,none,Polonium: Place Window $polonium_direction"
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "PoloniumResize$direction" "Meta+Ctrl+$direction,none,Polonium: Resize Tile $direction"
    done
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Left" "Meta+Alt+Left,none,Quick Tile Window to the Left"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Right" "Meta+Alt+Right,none,Quick Tile Window to the Right"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Top" "Meta+Alt+Up,none,Quick Tile Window to the Top"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Bottom" "Meta+Alt+Down,none,Quick Tile Window to the Bottom"
    for direction in Left Right Up Down; do
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "MoveZoom$direction" "none,none,Move Zoomed Area $direction"
    done
    for desktop in 1 2 3 4 5; do
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop $desktop" "Meta+$desktop,none,Switch to Desktop $desktop"
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch Window to Desktop $desktop" "Meta+Shift+$desktop,none,Switch Window to Desktop $desktop"
    done
    kwriteconfig6 --file kxkbrc --group Layout --key Use true
    kwriteconfig6 --file kxkbrc --group Layout --key LayoutList "us,ru"
    kwriteconfig6 --file kxkbrc --group Layout --key Options grp:ctrl_shift_toggle
    kwriteconfig6 --file kglobalshortcutsrc --group services --group phantomos-terminal.desktop --key _launch "Meta+Return,,Open PhantomOS Terminal"
    kwriteconfig6 --file kglobalshortcutsrc --group services --group phantomos-files.desktop --key _launch "Meta+E,,Open PhantomOS Files"
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then kbuildsycoca6 --noincremental >/dev/null 2>&1 || true; fi
if command -v qdbus6 >/dev/null 2>&1; then qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true; fi

layout_marker="$STATE_HOME/phantomos/plasma-layout-initialized"
if [[ ! -e "$layout_marker" || $RESET_LAYOUT == 1 ]]; then
if command -v qdbus6 >/dev/null 2>&1 && qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1; then
    panel_config="$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
    if [[ -f "$panel_config" ]]; then
        mkdir -p "$BACKUP_ROOT/$timestamp$CONFIG_HOME"
        cp -a -- "$panel_config" "$BACKUP_ROOT/$timestamp$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
        printf 'Backed up your existing Plasma panels to %s\n' "$BACKUP_ROOT/$timestamp$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
    fi
    wallpaper_uri="$(python -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$HOME/.local/share/phantomos/wallpapers/phantomos-night.png")"
    layout_script="$(sed "s|__PHANTOM_WALLPAPER_URI__|$wallpaper_uri|g" "$ROOT_DIR/plasma/apply-layout.js")"
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$layout_script" >/dev/null
    : >"$layout_marker"
    printf 'Applied PhantomOS wallpaper, Start menu, and top panel layout.\n'
else
    printf 'Plasma shell is not running; run phantom setup from a Plasma session to apply the PhantomOS panels and wallpaper.\n'
fi
fi

if [[ ! -e "$STATE_HOME/phantomos/mode" ]]; then printf 'work\n' >"$STATE_HOME/phantomos/mode"; fi
printf '\nPhantomOS Plasma setup is installed. Sign out and back in once to reload keyboard and global shortcuts.\n'
printf 'Use Super+Tab to switch PhantomOS modes and Super+Enter to open WezTerm.\n'
if ((POLONIUM_AVAILABLE == 0)); then printf 'Automatic tiling is disabled until kwin-polonium is installed from the AUR.\n' >&2; fi
printf 'Project: %s\nBackups: %s\n' "$ROOT_DIR" "$BACKUP_ROOT"
