local homeDir = os.getenv("HOME") or ""
local currentPath = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
hl.env("PATH", homeDir .. "/.local/bin:" .. currentPath)
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

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
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
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
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, curve = "phantomSoft", style = "slidefade 18%" })