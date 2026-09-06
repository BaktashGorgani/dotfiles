-- Monitors, environment, look and feel, animations, input.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "DP-2", mode = "preferred", position = "1920x0", scale = 1.25 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "3968x0", scale = 1, transform = 3 })

-- Alternatives kept from the legacy config:
-- hl.monitor({ output = "DP-1", mode = "preferred", position = "1920x0", scale = 1.25 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "4000x0", scale = 1, transform = 3 })

-- Bind workspaces to monitors
hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1" })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("HYPRCURSOR_THEME", "material_cursors")
hl.env("HYPRCURSOR_SIZE", "32")

hl.env("XCURSOR_THEME", "material_cursors")
hl.env("XCURSOR_SIZE", "32")

-- hl.env("GDK_SCALE", "2")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(00ff99ee)", "rgba(33ccffee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Resize windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/
        allow_tearing = false,

        layout = "dwindle",
    },

    group = {
        col = {
            border_active   = { colors = { "rgba(00ff99ee)", "rgba(33ccffee)" }, angle = 45 },
            border_inactive = "rgba(595959aa)",
        },
        -- group_on_movetoworkspace = true,

        groupbar = {
            -- stacked = true,
            height         = 1,
            render_titles  = false,
            gradients      = true,
            col = {
                active   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 90 },
                inactive = "rgba(595959aa)",
            },
            text_color = "rgba(ffffffff)",
        },
    },

    decoration = {
        rounding = 10,

        -- Transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper   = 1,     -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo     = false, -- If true disables the random hyprland logo / anime girl background. :(
        initial_workspace_tracking = 2,
        on_focus_under_fullscreen = 1,
    },

    binds = {
        movefocus_cycles_fullscreen = false,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        numlock_by_default = true,

        follow_mouse                = 2,
        float_switch_override_focus = 0,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        scroll_method = "on_button_down",
        scroll_button = 274,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-----------------
---- CURSOR ----
-----------------

-- Render the cursor in software instead of using the GPU's hardware cursor
-- plane. NVIDIA's hardware cursor plane is composited after the frame is
-- captured, so without this the mouse pointer is invisible in screen
-- shares/recordings (e.g. Chrome/Meet window & screen capture).
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
