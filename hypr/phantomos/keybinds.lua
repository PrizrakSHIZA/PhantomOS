local mod = "SUPER"
local HOME_DIR = os.getenv("HOME") or ""
local CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (HOME_DIR .. "/.config")
local overrides = {}
local override_file = io.open(CONFIG_HOME .. "/hypr/phantomos/keybindings.conf", "r")
if override_file ~= nil then
    for line in override_file:lines() do
        local action, chord = line:match("^([%w_]+)=([%w_+]+)$")
        if action ~= nil and chord ~= nil then overrides[action] = chord:gsub("%+", " + ") end
    end
    override_file:close()
end

local function bind(action, default, callback)
    local chord = overrides[action] or default
    hl.bind(chord, callback)
end

local function current_monitor_group_offset()
    local monitors = hl.get_monitors()
    if #monitors < 2 then return 0 end
    table.sort(monitors, function(a, b) return a.position.x < b.position.x end)
    local active = hl.get_active_monitor()
    if active ~= nil and active.name ~= monitors[1].name then return 5 end
    return 0
end

bind("toggle_mode", mod .. " + TAB", function() PhantomOS.toggle_mode() end)
bind("menu", mod .. " + D", hl.dsp.exec_cmd("phantomosctl menu"))
bind("settings", mod .. " + I", hl.dsp.exec_cmd("phantomosctl settings"))
bind("terminal", mod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
bind("close_window", mod .. " + Q", hl.dsp.window.close())
bind("toggle_float", mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind("cycle_window", "ALT + TAB", hl.dsp.window.cycle_next())

for index = 1, 5 do
    local workspace_index = index
    bind("workspace_" .. index, mod .. " + " .. index, function()
        local workspace = workspace_index + current_monitor_group_offset()
        if PhantomOS.mode() == "relax" then workspace = workspace > 5 and 6 or 1 end
        hl.dispatch(hl.dsp.focus({ workspace = workspace }))
    end)
    bind("move_workspace_" .. index, mod .. " + SHIFT + " .. index, function()
        if PhantomOS.mode() == "work" then
            local workspace = workspace_index + current_monitor_group_offset()
            hl.dispatch(hl.dsp.window.move({ workspace = workspace, follow = false }))
        end
    end)
end

for _, direction in ipairs({ {"left", "H", "l"}, {"down", "J", "d"}, {"up", "K", "u"}, {"right", "L", "r"} }) do
    local id, key, vector = direction[1], direction[2], direction[3]
    bind("focus_" .. id, mod .. " + " .. key, hl.dsp.focus({ direction = vector }))
    bind("move_" .. id, mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = vector }))
end

bind("fullscreen", mod .. " + F", hl.dsp.window.fullscreen())
bind("power", mod .. " + SHIFT + E", hl.dsp.exec_cmd("phantomosctl power"))
bind("screenshot_region", "PRINT", hl.dsp.exec_cmd("grim -g '$(slurp)' - | wl-copy"))
bind("screenshot_screen", mod .. " + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"))
