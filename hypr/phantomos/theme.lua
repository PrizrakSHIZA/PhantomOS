local homeDir = os.getenv("HOME") or ""
local currentPath = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
hl.env("PATH", homeDir .. "/.local/bin:" .. currentPath)
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

local configHome = os.getenv("XDG_CONFIG_HOME") or (homeDir .. "/.config")
local settingsDir = configHome .. "/phantomos/settings"

local function read_setting(name, fallback)
    local file = io.open(settingsDir .. "/" .. name, "r")
    if file == nil then return fallback end
    local value = file:read("*l")
    file:close()
    return value or fallback
end

local keyboard_layouts = read_setting("keyboard-layouts", "us,ru")
local mouse_sensitivity = tonumber(read_setting("mouse-sensitivity", "0")) or 0

hl.config({
    general = {
        gaps_in = 7,
        gaps_out = 12,
        border_size = 2,
        layout = "dwindle",
        resize_on_border = true,
        ["col.active_border"] = "rgb(7aa2f7)",
        ["col.inactive_border"] = "rgb(3b4261)",
    },
    decoration = {
        rounding = 9,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(080b18cc)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            xray = true,
        },
    },
    input = {
        kb_layout = keyboard_layouts,
        kb_options = "grp:ctrl_shift_toggle",
        follow_mouse = 1,
        sensitivity = mouse_sensitivity,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

hl.curve("phantomSoft", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.3, 1.0 } },
})
hl.animation({ leaf = "global", enabled = true, speed = 5, curve = "phantomSoft" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, curve = "phantomSoft", style = "popin 92%" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, curve = "phantomSoft", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, curve = "phantomSoft", style = "slidefade 18%" })