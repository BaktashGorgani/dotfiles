-- Hyprland configuration (Lua)
-- See https://wiki.hypr.land/Configuring/Start/
--
-- Migrated from the legacy hyprlang config (old hyprland.conf /
-- windowrules.conf). Hyprland loads this file instead of hyprland.conf
-- whenever it exists. The pre-migration files are preserved in chezmoi's
-- source history (see the chezmoi repo log for
-- private_dot_config/hypr/hyprland.conf and .../windowrules.conf) if you
-- ever need to fall back; move this file aside and restart Hyprland to do so.
--
-- Each require() runs in its own scope, so an error in one module does not
-- abort the rest of the configuration.

require("./lua/settings.lua")  -- monitors, env, look and feel, input
require("./lua/autostart.lua") -- processes started with the session
require("./lua/binds.lua")     -- keyboard, media and mouse binds
require("./lua/rules.lua")     -- window and layer rules
