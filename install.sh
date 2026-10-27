#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$HOME/.local/share/phantomos/backups"
MANAGED_MARK="$CONFIG_HOME/hypr/.phantomos-managed"
NO_PACKAGES=0

usage() {
    cat <<'EOF'
PhantomOS Arch post-install setup
Usage: ./install.sh [--no-packages]
  --no-packages  Skip pacman and only install user configuration.
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
    printf 'Run this script as your regular user; it calls sudo for pacman.\n' >&2
    exit 1
fi
if [[ ! -f "$ROOT_DIR/hypr/hyprland.lua" || ! -f "$ROOT_DIR/bin/phantomosctl" ]]; then
    printf 'Run install.sh from the PhantomOS project directory.\n' >&2
    exit 1
fi

if ((NO_PACKAGES == 0)); then
    command -v pacman >/dev/null 2>&1 || { echo 'This installer expects Arch Linux and pacman.' >&2; exit 1; }
    command -v sudo >/dev/null 2>&1 || { echo 'Install sudo, then rerun ./install.sh.' >&2; exit 1; }

    packages=(
        hyprland waybar rofi-wayland kitty micro python code gtk3 python-gobject git
        hyprpaper hyprlock swaync polkit-gnome pavucontrol easyeffects lsp-plugins-lv2
        nwg-displays nwg-look qt6ct kvantum zenity adw-gtk-theme pipewire pipewire-audio pipewire-alsa pipewire-pulse wireplumber
        networkmanager network-manager-applet bluez bluez-utils blueman thunar
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        grim slurp wl-clipboard
        papirus-icon-theme ttf-jetbrains-mono-nerd ttf-font-awesome
        noto-fonts noto-fonts-emoji
    )
    printf 'Installing packages. NVIDIA drivers and system boot settings are left untouched.\n'
    sudo pacman -S --needed "${packages[@]}"
    if command -v systemctl >/dev/null 2>&1; then
        if ! systemctl is-active --quiet bluetooth.service; then
            sudo systemctl enable --now bluetooth.service
        fi

        if ! systemctl is-active --quiet NetworkManager.service; then
            existing_network_manager=0
            for service in systemd-networkd.service iwd.service dhcpcd.service; do
                if systemctl is-active --quiet "$service" || systemctl is-enabled --quiet "$service"; then
                    existing_network_manager=1
                    break
                fi
            done
            if ((existing_network_manager == 0)); then
                sudo systemctl enable --now NetworkManager.service
            else
                printf 'Keeping the existing network service; NetworkManager was not enabled.\n'
            fi
        fi
    fi
fi

version_output="$(hyprland --version 2>/dev/null | head -n 1 || true)"
version_number="$(sed -nE 's/.* ([0-9]+)\.([0-9]+)\.([0-9]+).*/\1 \2 \3/p' <<<"$version_output")"
if [[ -z "$version_number" ]]; then
    printf 'Could not read the Hyprland version. Install/update Hyprland, then rerun.\n' >&2
    exit 1
fi
read -r version_major version_minor version_patch <<<"$version_number"
if ((version_major == 0 && version_minor < 55)); then
    printf 'PhantomOS needs Hyprland 0.55+ for Lua configuration; found %s.\n' "$version_output" >&2
    printf 'Update Arch fully, then rerun ./install.sh.\n' >&2
    exit 1
fi

mkdir -p "$CONFIG_HOME/hypr" "$CONFIG_HOME/waybar" "$CONFIG_HOME/rofi" "$CONFIG_HOME/kitty"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/phantomos/wallpapers" "$STATE_HOME/phantomos"

timestamp="$(date +%Y%m%d-%H%M%S)"
if [[ ! -e "$MANAGED_MARK" ]] && { [[ -e "$CONFIG_HOME/hypr/hyprland.lua" ]] || [[ -e "$CONFIG_HOME/hypr/hyprland.conf" ]]; }; then
    backup_dir="$BACKUP_ROOT/$timestamp"
    mkdir -p "$backup_dir/hypr"
    cp -a "$CONFIG_HOME/hypr/." "$backup_dir/hypr/"
    printf 'Backed up existing Hyprland configuration to %s\n' "$backup_dir/hypr"
fi

backup_and_install() {
    local source_file="$1"
    local target_file="$2"
    mkdir -p "$(dirname -- "$target_file")"
    if [[ -e "$target_file" ]] && ! cmp -s -- "$source_file" "$target_file"; then
        local backup_file="$BACKUP_ROOT/$timestamp${target_file#"$HOME"}"
        mkdir -p "$(dirname -- "$backup_file")"
        cp -a -- "$target_file" "$backup_file"
        printf 'Backed up %s to %s\n' "$target_file" "$backup_file"
    fi
    install -m 0644 -- "$source_file" "$target_file"
}

backup_and_install "$ROOT_DIR/hypr/hyprland.lua" "$CONFIG_HOME/hypr/hyprland.lua"
mkdir -p "$CONFIG_HOME/hypr/phantomos"
while IFS= read -r -d '' source_file; do
    relative_file="${source_file#"$ROOT_DIR/hypr/phantomos/"}"
    backup_and_install "$source_file" "$CONFIG_HOME/hypr/phantomos/$relative_file"
done < <(find "$ROOT_DIR/hypr/phantomos" -type f -print0)
touch "$MANAGED_MARK"

backup_and_install "$ROOT_DIR/waybar/style.css" "$CONFIG_HOME/waybar/phantomos.css"
backup_and_install "$ROOT_DIR/rofi/phantomos.rasi" "$CONFIG_HOME/rofi/phantomos.rasi"
backup_and_install "$ROOT_DIR/kitty/kitty.conf" "$CONFIG_HOME/kitty/phantomos.conf"
backup_and_install "$ROOT_DIR/bin/phantomosctl" "$HOME/.local/bin/phantomosctl"
backup_and_install "$ROOT_DIR/bin/phantomos-settings" "$HOME/.local/bin/phantomos-settings"
backup_and_install "$ROOT_DIR/bin/phantom" "$HOME/.local/bin/phantom"
backup_and_install "$ROOT_DIR/hypr/hyprpaper.conf" "$CONFIG_HOME/hypr/hyprpaper.conf"
backup_and_install "$ROOT_DIR/hypr/hyprlock.conf" "$CONFIG_HOME/hypr/hyprlock.conf"
backup_and_install "$ROOT_DIR/assets/phantomos-night.png" "$HOME/.local/share/phantomos/wallpapers/phantomos-night.png"
backup_and_install "$ROOT_DIR/applications/phantomos-settings.desktop" "$HOME/.local/share/applications/phantomos-settings.desktop"
backup_and_install "$ROOT_DIR/applications/phantomos-power.desktop" "$HOME/.local/share/applications/phantomos-power.desktop"
chmod 0755 "$HOME/.local/bin/phantomosctl"
chmod 0755 "$HOME/.local/bin/phantomos-settings"
chmod 0755 "$HOME/.local/bin/phantom"

if [[ ! -e "$CONFIG_HOME/kitty/kitty.conf" ]]; then
    printf 'include phantomos.conf\n' >"$CONFIG_HOME/kitty/kitty.conf"
elif ! grep -Fq 'include phantomos.conf' "$CONFIG_HOME/kitty/kitty.conf"; then
    kitty_backup="$BACKUP_ROOT/$timestamp/kitty/kitty.conf"
    mkdir -p "$(dirname -- "$kitty_backup")"
    cp -a "$CONFIG_HOME/kitty/kitty.conf" "$kitty_backup"
    printf '\n# PhantomOS theme\ninclude phantomos.conf\n' >>"$CONFIG_HOME/kitty/kitty.conf"
fi
if [[ ! -e "$STATE_HOME/phantomos/mode" ]]; then
    printf 'work\n' >"$STATE_HOME/phantomos/mode"
fi

printf '\nPhantomOS is installed. Restart Hyprland and use Super+Tab to switch modes.\n'
printf 'Project: %s\nBackups: %s\n' "$ROOT_DIR" "$BACKUP_ROOT"
