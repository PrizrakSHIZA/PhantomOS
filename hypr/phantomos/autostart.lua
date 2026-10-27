local HOME_DIR = os.getenv("HOME") or ""
local ctl = HOME_DIR .. "/.local/bin/phantomosctl"

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(ctl .. " refresh-panels")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("swaync")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)