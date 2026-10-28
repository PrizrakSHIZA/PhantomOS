#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$DATA_HOME/phantomos/backups"
NO_PACKAGES=0

usage() {
    cat <<'EOF'
PhantomOS Plasma setup for Arch Linux
Usage: ./install.sh [--no-packages]
  --no-packages  Skip pacman/AUR packages; install user configuration only.
  -h, --help     Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --no-packages) NO_PACKAGES=1 ;;
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
        kde-gtk-config kscreen sddm dolphin konsole spectacle ark kate
        kitty micro python python-gobject git btop code
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
        yay -S --needed kwin-polonium || {
            printf 'Polonium was not installed. Install kwin-polonium from the AUR to enable automatic tiling.\n' >&2
        }
    else
        printf 'Automatic tiling requires kwin-polonium (AUR). Install it with your AUR helper, for example: yay -S kwin-polonium\n'
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

mkdir -p "$CONFIG_HOME" "$CONFIG_HOME/kitty" "$DATA_HOME/color-schemes" "$DATA_HOME/applications" \
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
backup_and_install "$ROOT_DIR/assets/icons/hicolor/scalable/apps/phantomos.svg" "$DATA_HOME/icons/hicolor/scalable/apps/phantomos.svg"
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 --type KWin/Script --upgrade "$ROOT_DIR/plasma/PhantomOSToggle" >/dev/null 2>&1 || \
        kpackagetool6 --type KWin/Script --install "$ROOT_DIR/plasma/PhantomOSToggle"
fi
backup_and_install "$ROOT_DIR/kitty/kitty.conf" "$CONFIG_HOME/kitty/phantomos.conf"
backup_and_install "$ROOT_DIR/bin/phantomosctl" "$HOME/.local/bin/phantomosctl"
backup_and_install "$ROOT_DIR/bin/phantomos-settings" "$HOME/.local/bin/phantomos-settings"
backup_and_install "$ROOT_DIR/autostart/phantomos-work-mode.desktop" "$CONFIG_HOME/autostart/phantomos-work-mode.desktop"
if [[ "${PHANTOMOS_PACKAGE_MODE:-0}" != 1 ]]; then backup_and_install "$ROOT_DIR/bin/phantom" "$HOME/.local/bin/phantom"; fi
backup_and_install "$ROOT_DIR/assets/phantomos-night.png" "$HOME/.local/share/phantomos/wallpapers/phantomos-night.png"
backup_and_install "$ROOT_DIR/desktop-flavor" "$DATA_HOME/phantomos/desktop-flavor"
for desktop in "$ROOT_DIR"/applications/*.desktop; do
    backup_and_install "$desktop" "$DATA_HOME/applications/$(basename "$desktop")"
done
if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database "$DATA_HOME/applications"; fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then gtk-update-icon-cache -f "$DATA_HOME/icons/hicolor" >/dev/null 2>&1 || true; fi
chmod 0755 "$HOME/.local/bin/phantomosctl" "$HOME/.local/bin/phantomos-settings"
if [[ "${PHANTOMOS_PACKAGE_MODE:-0}" != 1 ]]; then chmod 0755 "$HOME/.local/bin/phantom"; fi

if [[ ! -e "$CONFIG_HOME/kitty/kitty.conf" ]]; then
    printf 'include phantomos.conf\n' >"$CONFIG_HOME/kitty/kitty.conf"
elif ! grep -Fq 'include phantomos.conf' "$CONFIG_HOME/kitty/kitty.conf"; then
    cp -a "$CONFIG_HOME/kitty/kitty.conf" "$BACKUP_ROOT/$timestamp/kitty.conf"
    printf '\n# PhantomOS theme\ninclude phantomos.conf\n' >>"$CONFIG_HOME/kitty/kitty.conf"
fi

# KDE's native color scheme is applied without replacing the user's panel layout.
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme PhantomOS || printf 'Color scheme installed; select PhantomOS in System Settings > Colors.\n'
fi
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme PhantomOS
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
    kwriteconfig6 --file kwinrc --group Effect-Blur --key BlurEnabled true
    kwriteconfig6 --file kwinrc --group Plugins --key poloniumEnabled true
    kwriteconfig6 --file kwinrc --group Script-polonium --key EngineType 0
    kwriteconfig6 --file kwinrc --group Script-polonium --key Borders 4
    kwriteconfig6 --file kwinrc --group Script-polonium --key TiledWindowsBelow true
    kwriteconfig6 --file kwinrc --group Plugins --key phantomos-toggleEnabled true
    kwriteconfig6 --file kwinrc --group Desktops --key Number 5
    kwriteconfig6 --file kwinrc --group Desktops --key Rows 1
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Walk Through Windows" "none,none,Walk Through Windows"
    for desktop in 1 2 3 4 5; do
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop $desktop" "Meta+$desktop,none,Switch to Desktop $desktop"
        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch Window to Desktop $desktop" "Meta+Shift+$desktop,none,Switch Window to Desktop $desktop"
    done
    kwriteconfig6 --file kxkbrc --group Layout --key Use true
    kwriteconfig6 --file kxkbrc --group Layout --key LayoutList "us,ru"
    kwriteconfig6 --file kxkbrc --group Layout --key Options grp:ctrl_shift_toggle
fi

if [[ ! -e "$STATE_HOME/phantomos/mode" ]]; then printf 'work\n' >"$STATE_HOME/phantomos/mode"; fi
printf '\nPhantomOS Plasma setup is installed. Log out and select Plasma (Wayland) at SDDM.\n'
printf 'Use Super+Tab to switch PhantomOS modes. Settings are available in System Settings and the PhantomOS launcher.\n'
printf 'Project: %s\nBackups: %s\n' "$ROOT_DIR" "$BACKUP_ROOT"
