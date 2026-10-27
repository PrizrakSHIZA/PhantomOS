local HOME_DIR = os.getenv("HOME") or ""
local STATE_HOME = os.getenv("XDG_STATE_HOME") or (HOME_DIR .. "/.local/state")
local MODE_FILE = STATE_HOME .. "/phantomos/mode"
local WORKSPACES_FILE = STATE_HOME .. "/phantomos/workspaces-before-relax"
local tiled_tag = "phantomos_tiled"

local function read_mode()
    local file = io.open(MODE_FILE, "r")
    if file == nil then return "work" end
    local value = file:read("*l")
    file:close()
    return value == "relax" and "relax" or "work"
end

local function write_mode(value)
    local file = io.open(MODE_FILE, "w")
    if file ~= nil then
        file:write(value, "\n")
        file:close()
    end
end

local function tags_of(window)
    return window.tags or {}
end

local function find_workspace_tag(window)
    for _, tag in ipairs(tags_of(window)) do
        local id = tag:match("^phantomos_ws_(%d+)$")
        if id ~= nil then return tonumber(id) end
    end
    return nil
end

local function has_tag(window, value)
    for _, tag in ipairs(tags_of(window)) do
        if tag == value then return true end
    end
    return false
end

local function monitor_count()
    return #hl.get_monitors()
end

local function ordered_monitors()
    local monitors = hl.get_monitors()
    table.sort(monitors, function(a, b)
        return a.position.x < b.position.x
    end)
    return monitors
end

local function save_visible_workspaces()
    local file = io.open(WORKSPACES_FILE, "w")
    if file == nil then return end

    for _, monitor in ipairs(ordered_monitors()) do
        local workspace = monitor.active_workspace
        local workspace_id = workspace and workspace.id or 0
        file:write(tostring(workspace_id), "\n")
    end
    file:close()
end

local function read_visible_workspaces()
    local result = {}
    local file = io.open(WORKSPACES_FILE, "r")
    if file == nil then return result end

    for line in file:lines() do
        result[#result + 1] = tonumber(line)
    end
    file:close()
    return result
end

local function show_relax_workspaces()
    local monitors = ordered_monitors()
    if #monitors == 0 then return end
    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
    if #monitors > 1 then hl.dispatch(hl.dsp.focus({ workspace = 6 })) end
end

local function restore_visible_workspaces()
    local monitors = ordered_monitors()
    local saved = read_visible_workspaces()
    for index, _ in ipairs(monitors) do
        local workspace_id = saved[index]
        if workspace_id == nil or workspace_id <= 0 then
            workspace_id = index == 1 and 1 or 6
        end
        hl.dispatch(hl.dsp.focus({ workspace = workspace_id }))
    end
end

local function relax_workspace_for(window)
    local workspace = window.workspace
    local workspace_id = workspace and workspace.id or 1
    if monitor_count() < 2 or workspace_id <= 5 then return 1 end
    return 6
end

local function remember_and_float(window)
    if window == nil or find_workspace_tag(window) ~= nil then return end

    local workspace = window.workspace
    local workspace_id = workspace and workspace.id or 1
    hl.dispatch(hl.dsp.window.tag({
        tag = "+phantomos_ws_" .. tostring(workspace_id),
        window = window,
    }))

    if not window.floating then
        hl.dispatch(hl.dsp.window.tag({ tag = "+" .. tiled_tag, window = window }))
    end

    local destination = relax_workspace_for(window)
    if workspace_id ~= destination then
        hl.dispatch(hl.dsp.window.move({ workspace = destination, follow = false, window = window }))
    end
    hl.dispatch(hl.dsp.window.float({ action = "set", window = window }))
end

local function restore_window(window)
    local workspace_id = find_workspace_tag(window)
    if workspace_id == nil then return end

    hl.dispatch(hl.dsp.window.move({ workspace = workspace_id, follow = false, window = window }))
    if has_tag(window, tiled_tag) then
        hl.dispatch(hl.dsp.window.float({ action = "unset", window = window }))
        hl.dispatch(hl.dsp.window.tag({ tag = "-" .. tiled_tag, window = window }))
    end
    hl.dispatch(hl.dsp.window.tag({
        tag = "-phantomos_ws_" .. tostring(workspace_id),
        window = window,
    }))
end

local function apply_visual_profile(value)
    if value == "relax" then
        hl.config({
            general = { gaps_in = 10, gaps_out = 16, border_size = 1 },
            decoration = { rounding = 17, rounding_power = 2.6 },
        })
        hl.animation({ leaf = "windows", enabled = true, speed = 7, curve = "phantomSoft", style = "popin 88%" })
        hl.animation({ leaf = "workspaces", enabled = true, speed = 8, curve = "phantomSoft", style = "slidefade 24%" })
    else
        hl.config({
            general = { gaps_in = 7, gaps_out = 12, border_size = 2, layout = "dwindle" },
            decoration = { rounding = 9, rounding_power = 2 },
        })
        hl.animation({ leaf = "windows", enabled = true, speed = 5, curve = "phantomSoft", style = "popin 92%" })
        hl.animation({ leaf = "workspaces", enabled = true, speed = 6, curve = "phantomSoft", style = "slidefade 18%" })
    end
end

local mode = read_mode()
_G.PhantomOS = _G.PhantomOS or {}
PhantomOS.mode = function() return mode end

PhantomOS.set_mode = function(value)
    if value ~= "work" and value ~= "relax" then return end
    if value == mode then
        apply_visual_profile(value)
        return
    end

    if value == "relax" then
        save_visible_workspaces()
        mode = "relax"
        for _, window in ipairs(hl.get_windows()) do remember_and_float(window) end
        show_relax_workspaces()
    else
        for _, window in ipairs(hl.get_windows()) do restore_window(window) end
        restore_visible_workspaces()
        mode = "work"
    end

    write_mode(mode)
    apply_visual_profile(mode)
    hl.exec_cmd(HOME_DIR .. "/.local/bin/phantomosctl refresh-panels")
    hl.exec_cmd("notify-send --app-name=PhantomOS 'PhantomOS' 'Переключено в режим " ..
        (mode == "work" and "Работы" or "Отдыха") .. "'")
end

PhantomOS.toggle_mode = function()
    PhantomOS.set_mode(mode == "work" and "relax" or "work")
end

hl.on("window.open", function(window)
    if mode == "relax" then remember_and_float(window) end
end)

hl.on("hyprland.start", function()
    apply_visual_profile(mode)
    if mode == "relax" then
        for _, window in ipairs(hl.get_windows()) do remember_and_float(window) end
        show_relax_workspaces()
    end
end)
