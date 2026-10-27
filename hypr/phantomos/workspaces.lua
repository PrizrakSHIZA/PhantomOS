local monitors = hl.get_monitors()
table.sort(monitors, function(a, b)
    return a.position.x < b.position.x
end)

for workspace_id = 1, 10 do
    local monitor
    if #monitors <= 1 then
        monitor = monitors[1]
    elseif workspace_id <= 5 then
        monitor = monitors[1]
    else
        monitor = monitors[2]
    end

    if monitor ~= nil then
        hl.workspace_rule({
            workspace = tostring(workspace_id),
            monitor = monitor.name,
            default = (workspace_id == 1 or (#monitors > 1 and workspace_id == 6)),
            persistent = true,
        })
    end
end