-- Programs and commands used by binds and autostart.
-- Ported from the legacy `$variable` definitions in hyprland.conf.

local killRofi = "pkill -x rofi"
local rofiLaunch = killRofi .. " || ~/.config/rofi/scripts/rofilaunch.sh"

local terminal = "kitty"

return {
    terminal    = terminal,
    fileManager = "thunar",

    killRofi = killRofi,

    -- rofilaunch.sh modes: d = drun, w = window, f = filebrowser
    applicationLauncher = rofiLaunch .. " d",
    windowSwitcher      = rofiLaunch .. " w",
    fileExplorer        = rofiLaunch .. " f",

    -- The legacy value was missing the `$` on `kill_rofi`, so this never
    -- toggled rofi closed. Fixed to match the other rofi binds.
    styleSelectMenu = killRofi .. " || ~/.config/rofi/scripts/rofiselect.sh",

    clipboard = killRofi .. " || ~/.config/rofi/scripts/cliphist.sh",
    -- Alternative clipboard picker with image previews:
    -- clipboard = "rofi -modi clipboard:~/.config/sway/scripts/cliphist-rofi-img -show clipboard -show-icons",

    emojiPicker = killRofi .. ' || rofimoji --selector-args="-theme ~/.config/rofi/clipboard.rasi" -a type copy',

    -- Fixed: kitty's real flags are --class and --title, not --match:class /
    -- --match:title (which aren't recognized options at all, so kitty was
    -- failing to launch before ever reaching `pkexec btop`).
    taskManager = terminal .. ' --class "btop" --title "Task Manager" pkexec btop',

    screenshot = "~/.config/hypr/scripts/screenshot.sh",

    -- Defined for convenience; not bound to a key.
    whatsapp = '/opt/microsoft/msedge/microsoft-edge "--profile-directory=Profile 1" --app-id=hnpfjngllnobngcgfapefoaidbinmjnm --app-url=https://web.whatsapp.com/',
    messages = '/opt/microsoft/msedge/microsoft-edge "--profile-directory=Profile 1" --app-id=hpfldicfbfomlpcikngkocigghgafkph "--app-url=https://messages.google.com/web/?pwa=1"',
}
