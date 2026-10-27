local mod = "SUPER"

local function current_monitor_group_offset()
    local monitors = hl.get_monitors()
    if #monitors < 2 then return 0 end
    table.sort(monitors, function(a, b)
        return a.position.x < b.position.x
    end)
    local active = hl.get_active_monitor()
    if active ~= nil and active.name ~= monitors[1].name then return 5 end
    return 0
end

hl.bind(mod .. " + TAB", function()
    PhantomOS.toggle_mode()
end)
hl.bind(mod .. " + D", hl.dsp.exec_cmd("phantomosctl menu"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("phantomosctl settings"))
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + TAB", hl.dsp.window.cycle_next())

for index = 1, 5 do
    local workspace_index = index
    local key = tostring(workspace_index)

    hl.bind(mod .. " + " .. key, function()
        local workspace = workspace_index + current_monitor_group_offset()
        if PhantomOS.mode() == "relax" then
            workspace = workspace > 5 and 6 or 1
        end
        hl.dispatch(hl.dsp.focus({ workspace = workspace }))
    end)

    hl.bind(mod .. " + SHIFT + " .. key, function()
        if PhantomOS.mode() == "work" then
            local workspace = workspace_index + current_monitor_group_offset()
            hl.dispatch(hl.dsp.window.move({ workspace = workspace, follow = false }))
        end
    end)
end

hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("phantomosctl power"))
hl.bind("PRINT", hl.dsp.exec_cmd("grim -g '$(slurp)' - | wl-copy"))
hl.bind(mod .. " + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"))