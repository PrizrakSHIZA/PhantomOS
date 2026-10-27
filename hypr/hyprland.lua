-- PhantomOS entry point. Requires Hyprland 0.55+ (Lua configuration).
require("phantomos.theme")
require("phantomos.monitors")
require("phantomos.workspaces")
-- nwg-displays writes these optional Lua modules into ~/.config/hypr.
pcall(require, "monitors")
pcall(require, "workspaces")
require("phantomos.mode")
require("phantomos.keybinds")
require("phantomos.autostart")
