-- Autostart
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- hl.exec_cmd() spawns asynchronously, so the legacy trailing `&` is not needed.

local apps = require("./lua/apps.lua")

hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 1; /usr/bin/google-chrome", { workspace = "1 silent" })
    hl.exec_cmd("sleep 1; /usr/bin/warp-terminal", { workspace = "3 silent" })
    hl.exec_cmd("sleep 1; " .. apps.terminal, { workspace = "2" })
    hl.exec_cmd("sleep 1; Discord", { workspace = "special:chats" })
    hl.exec_cmd("sleep 1; " .. apps.taskManager, { workspace = "special:terminal" })
end)
