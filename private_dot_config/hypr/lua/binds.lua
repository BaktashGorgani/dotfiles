-- Keybindings
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
-- and https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local apps = require("./lua/apps.lua")

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Move focus in a direction and raise the newly focused window.
local function focusAndRaise(direction)
    return function()
        hl.dispatch(hl.dsp.focus({ direction = direction }))
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
    end
end

-- Pull a workspace onto the focused monitor, then switch to it.
local function grabWorkspace(id)
    return function()
        hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = "current" }))
        hl.dispatch(hl.dsp.focus({ workspace = id }))
    end
end

--
-- Fullscreen
--
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen({ mode = "maximized" }))

--
-- Groups
--
hl.bind(mainMod .. " + r", hl.dsp.group.toggle())
hl.bind(mainMod .. " + u", hl.dsp.group.prev())
hl.bind(mainMod .. " + i", hl.dsp.group.next())

--
-- Screenshot
--
hl.bind(mainMod .. " + CONTROL + s", hl.dsp.exec_cmd(apps.screenshot))

--
-- Task Manager
--
hl.bind(mainMod .. " + CONTROL + escape", hl.dsp.exec_cmd(apps.taskManager))

--
-- Logout Manager
--
hl.bind(mainMod .. " + CONTROL + l", hl.dsp.exec_cmd("wlogout"))

--
-- Color Picker
--
hl.bind(mainMod .. " + ALT + c", hl.dsp.exec_cmd("hyprpicker -a"))

--
-- Rofi menus
--
hl.bind(mainMod .. " + a", hl.dsp.exec_cmd(apps.applicationLauncher))
hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd(apps.windowSwitcher))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.exec_cmd(apps.fileExplorer))
hl.bind(mainMod .. " + SHIFT + a", hl.dsp.exec_cmd(apps.styleSelectMenu))

--
-- Clipboard manager
--
hl.bind(mainMod .. " + v", hl.dsp.exec_cmd(apps.clipboard))

--
-- Emoji Picker
--
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(apps.emojiPicker))

--
-- Notifications
--
hl.bind(mainMod .. " + n", hl.dsp.exec_cmd("dunstctl history-pop"))
hl.bind(mainMod .. " + SHIFT + n", hl.dsp.exec_cmd("dunstctl close-all; dunstctl history-clear"))

--
-- Windows
--
hl.bind(mainMod .. " + q", hl.dsp.exec_cmd(apps.terminal))
hl.bind(mainMod .. " + SHIFT + q", hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + x", hl.dsp.window.close())
hl.bind(mainMod .. " + e", hl.dsp.exec_cmd(apps.fileManager))
hl.bind(mainMod .. " + SHIFT + v", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + p", hl.dsp.window.pseudo()) -- dwindle

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- ... and with vim keys, which also alter the z order
hl.bind(mainMod .. " + h", focusAndRaise("left"))
hl.bind(mainMod .. " + l", focusAndRaise("right"))
hl.bind(mainMod .. " + k", focusAndRaise("up"))
hl.bind(mainMod .. " + j", focusAndRaise("down"))

-- Move windows with mainMod + SHIFT + arrow keys and vim keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left",  group_aware = true }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up",    group_aware = true }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down",  group_aware = true }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left",  group_aware = true }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up",    group_aware = true }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down",  group_aware = true }))

--
-- Monitors: keys 1-3 and Equal juggle the per-monitor workspaces
--
hl.bind(mainMod .. " + 1",     hl.dsp.workspace.swap_monitors({ monitor1 = "DP-2", monitor2 = "DP-1" }))
hl.bind(mainMod .. " + 2",     hl.dsp.focus({ monitor = "DP-2" }))
hl.bind(mainMod .. " + 3",     hl.dsp.workspace.swap_monitors({ monitor1 = "DP-2", monitor2 = "HDMI-A-1" }))
hl.bind(mainMod .. " + equal", hl.dsp.workspace.swap_monitors({ monitor1 = "HDMI-A-1", monitor2 = "DP-1" }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ monitor = "DP-1" }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ monitor = "DP-2" }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ monitor = "HDMI-A-1" }))

--
-- Workspaces 4-10 (10 maps to key 0)
--
for i = 4, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,           grabWorkspace(i))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Regain a way to get to / move to workspaces 1-3
for i = 1, 3 do
    hl.bind(mainMod .. " + CONTROL + " .. i,         grabWorkspace(i))
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. i, hl.dsp.window.move({ workspace = i }))
end

--
-- Special workspaces
--
hl.bind(mainMod .. " + s", hl.dsp.workspace.toggle_special("floatingwindow"))
hl.bind(mainMod .. " + SHIFT + s", hl.dsp.window.move({ workspace = "special:floatingwindow" }))

hl.bind(mainMod .. " + o", hl.dsp.workspace.toggle_special("outoftheway"))
hl.bind(mainMod .. " + SHIFT + o", hl.dsp.window.move({ workspace = "special:outoftheway", follow = false }))

hl.bind(mainMod .. " + t", hl.dsp.workspace.toggle_special("terminal"))
hl.bind(mainMod .. " + SHIFT + t", hl.dsp.window.move({ workspace = "special:terminal" }))

hl.bind(mainMod .. " + c", hl.dsp.workspace.toggle_special("chats"))
hl.bind(mainMod .. " + SHIFT + c", hl.dsp.window.move({ workspace = "special:chats" }))

hl.bind(mainMod .. " + w", hl.dsp.workspace.toggle_special("work"))
hl.bind(mainMod .. " + SHIFT + w", hl.dsp.window.move({ workspace = "special:work" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with ALT + LMB/RMB and dragging
hl.bind("ALT + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("ALT + mouse:273", hl.dsp.window.resize(), { mouse = true })

--
-- Multimedia keys for volume and LCD brightness
--
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                       { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
