-- █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█
--
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- Rules are evaluated top to bottom, so order matters.

-- Ignore maximize requests from apps.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

--
-- Opacity
--
hl.window_rule({ match = { class = "^(.*)$" },                                 opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(code-oss)$" },                           opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^([Cc]ode)$" },                            opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(code-url-handler)$" },                   opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(code-insiders-url-handler)$" },          opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(kitty)$" },                              opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$" },                    opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(org.kde.ark)$" },                        opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(nwg-look)$" },                           opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(qt5ct)$" },                              opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(qt6ct)$" },                              opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(kvantummanager)$" },                     opacity = "0.80 0.80" })
hl.window_rule({ match = { title = "^(Task Manager)$" },                       opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" },         opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(blueman-manager)$" },                    opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(nm-applet)$" },                          opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },               opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },   opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" },          opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" },      opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$" }, opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^([Ss]team)$" },                           opacity = "0.70 0.70" })
hl.window_rule({ match = { class = "^(steamwebhelper)$" },                     opacity = "0.70 0.70" })
hl.window_rule({ match = { class = "^([Ss]potify)$" },                         opacity = "0.70 0.70" })
hl.window_rule({ match = { initial_title = "^(Spotify Free)$" },               opacity = "0.70 0.70" })
hl.window_rule({ match = { initial_title = "^(Spotify Premium)$" },            opacity = "0.70 0.70" })

hl.window_rule({ match = { class = "^(com.github.rafostar.Clapper)$" },        opacity = "0.90 0.90" }) -- Clapper-Gtk
hl.window_rule({ match = { class = "^(com.github.tchx84.Flatseal)$" },         opacity = "0.80 0.80" }) -- Flatseal-Gtk
hl.window_rule({ match = { class = "^(hu.kramo.Cartridges)$" },                opacity = "0.80 0.80" }) -- Cartridges-Gtk
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" },              opacity = "0.80 0.80" }) -- Obs-Qt
hl.window_rule({ match = { class = "^(gnome-boxes)$" },                        opacity = "0.80 0.80" }) -- Boxes-Gtk
hl.window_rule({ match = { class = "^(vesktop)$" },                            opacity = "0.80 0.80" }) -- Vesktop
hl.window_rule({ match = { class = "^(discord)$" },                            opacity = "0.85 0.80" }) -- Discord-Electron
hl.window_rule({ match = { class = "^(WebCord)$" },                            opacity = "0.80 0.80" }) -- WebCord-Electron
hl.window_rule({ match = { class = "^(ArmCord)$" },                            opacity = "0.80 0.80" }) -- ArmCord-Electron
hl.window_rule({ match = { class = "^(app.drey.Warp)$" },                      opacity = "0.80 0.80" }) -- Warp-Gtk
hl.window_rule({ match = { class = "^(net.davidotek.pupgui2)$" },              opacity = "0.80 0.80" }) -- ProtonUp-Qt
hl.window_rule({ match = { class = "^(yad)$" },                                opacity = "0.80 0.80" }) -- Protontricks-Gtk
hl.window_rule({ match = { class = "^(Signal)$" },                             opacity = "0.80 0.80" }) -- Signal-Gtk
hl.window_rule({ match = { class = "^(io.github.alainm23.planify)$" },         opacity = "0.80 0.80" }) -- planify-Gtk
hl.window_rule({ match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" }, opacity = "0.80 0.80" }) -- Upscaler-Gtk
hl.window_rule({ match = { class = "^(com.github.unrud.VideoDownloader)$" },   opacity = "0.80 0.80" }) -- VideoDownloader-Gtk
hl.window_rule({ match = { class = "^(io.gitlab.adhami3310.Impression)$" },    opacity = "0.80 0.80" }) -- Impression-Gtk
hl.window_rule({ match = { class = "^(io.missioncenter.MissionCenter)$" },     opacity = "0.80 0.80" }) -- MissionCenter-Gtk
hl.window_rule({ match = { class = "^(io.github.flattool.Warehouse)$" },       opacity = "0.80 0.80" }) -- Warehouse-Gtk

hl.window_rule({ match = { class = "^(steam)$" },                              opacity = "0.95 0.90" })

--
-- Floating
--
hl.window_rule({ match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog — Dolphin)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$", title = "^(Copying — Dolphin)$" },         float = true })
hl.window_rule({ match = { title = "^(About Mozilla Firefox)$" },                                    float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" },                float = true })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Library)$" },                           float = true })
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(top)$" },  float = true })
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(btop)$" }, float = true })
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(htop)$" }, float = true })
hl.window_rule({ match = { class = "^(vlc)$" },                                float = true })
hl.window_rule({ match = { class = "^(kvantummanager)$" },                     float = true })
hl.window_rule({ match = { class = "^(qt5ct)$" },                              float = true })
hl.window_rule({ match = { class = "^(qt6ct)$" },                              float = true })
hl.window_rule({ match = { class = "^(nwg-look)$" },                           float = true })
hl.window_rule({ match = { class = "^(org.kde.ark)$" },                        float = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" },         float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" },                    float = true })
hl.window_rule({ match = { class = "^(nm-applet)$" },                          float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },               float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" },       float = true })

hl.window_rule({ match = { class = "^(Signal)$" },                             float = true }) -- Signal-Gtk
hl.window_rule({ match = { class = "^(com.github.rafostar.Clapper)$" },        float = true }) -- Clapper-Gtk
hl.window_rule({ match = { class = "^(app.drey.Warp)$" },                      float = true }) -- Warp-Gtk
hl.window_rule({ match = { class = "^(net.davidotek.pupgui2)$" },              float = true }) -- ProtonUp-Qt
hl.window_rule({ match = { class = "^(yad)$" },                                float = true }) -- Protontricks-Gtk
hl.window_rule({ match = { class = "^(eog)$" },                                float = true }) -- Imageviewer-Gtk
hl.window_rule({ match = { class = "^(io.github.alainm23.planify)$" },         float = true }) -- planify-Gtk
hl.window_rule({ match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" }, float = true }) -- Upscaler-Gtk
hl.window_rule({ match = { class = "^(com.github.unrud.VideoDownloader)$" },   float = true }) -- VideoDownloader-Gtk
hl.window_rule({ match = { class = "^(io.gitlab.adhami3310.Impression)$" },    float = true }) -- Impression-Gtk
hl.window_rule({ match = { class = "^(io.missioncenter.MissionCenter)$" },     float = true }) -- MissionCenter-Gtk

--
-- Custom window rules
--
hl.window_rule({ match = { class = "^(com.cisco.secureclient.gui)$" }, float = true })                            -- Cisco VPN
hl.window_rule({ match = { class = "^(com.cisco.secureclient.gui)$" }, workspace = "special:outoftheway" })       -- Cisco VPN
hl.window_rule({ match = { class = "^(com.cisco.secureclient.gui)$" }, idle_inhibit = "always" })                 -- Cisco VPN

hl.window_rule({ match = { class = "^(thunar)$" }, float = true })          -- file manager
hl.window_rule({ match = { class = "^(thunar)$" }, size = { 1500, 800 } })  -- file manager

hl.window_rule({ match = { title = "(Enter name of file to save to)" }, float = true })
hl.window_rule({ match = { title = "(Enter name of file to save to)" }, center = true })
hl.window_rule({ match = { title = "(Enter name of file to save to)" }, size = { 1500, 800 } })

hl.window_rule({ match = { class = "(org.gnome.Calculator)" },   float = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator)" },   center = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator)" },   size = { 670, 1040 } })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, workspace = "special:outoftheway" })

hl.window_rule({ match = { class = "(org.gnome.TextEditor)" },   float = true })
hl.window_rule({ match = { class = "(org.gnome.TextEditor)" },   center = true })
hl.window_rule({ match = { class = "(org.gnome.TextEditor)" },   size = { 1500, 800 } })
hl.window_rule({ match = { class = "^(org.gnome.TextEditor)$" }, workspace = "special:outoftheway" })

-- hl.window_rule({ match = { title = "^(Task Manager)$" }, float = true })
-- hl.window_rule({ match = { title = "^(Task Manager)$" }, center = true })
-- hl.window_rule({ match = { title = "^(Task Manager)$" }, size = { "monitor_w*0.8", "monitor_h*0.8" } })

hl.window_rule({ match = { class = "^(calcurse)$" }, float = true })
hl.window_rule({ match = { class = "^(calcurse)$" }, center = true })

hl.window_rule({ match = { class = "^(re.sonny.Junction)$" }, float = true })
hl.window_rule({ match = { class = "^(re.sonny.Junction)$" }, center = true })
hl.window_rule({ match = { class = "^(re.sonny.Junction)$", title = "^(Junction)$" }, size = { "monitor_w*0.37", "monitor_h*0.22" } })

hl.window_rule({ match = { class = "(jetbrains-studio)" }, workspace = "2" })
hl.window_rule({ match = { title = "(Running Devices.*)" }, size = { 372, 1030 } })
hl.window_rule({ match = { title = "(Running Devices.*)" }, move = { 3475, 97 } })
hl.window_rule({ match = { title = "(Outlook)" },          workspace = "1" })
hl.window_rule({ match = { title = "(Microsoft Teams)" },  workspace = "3" })
hl.window_rule({ match = { title = "(eve-ng)" },                 workspace = "special:work" })
hl.window_rule({ match = { title = "(Chrome Remote Desktop)" },  workspace = "special:work" })
hl.window_rule({ match = { title = "(WhatsApp)" },               workspace = "special:chats" })
hl.window_rule({ match = { title = "(Messages)" },               workspace = "special:chats" })
hl.window_rule({ match = { title = "(WhatsApp)" }, pseudo = true })
hl.window_rule({ match = { title = "(Messages)" }, pseudo = true })
hl.window_rule({ match = { title = "(WhatsApp)" }, size = { "monitor_w*0.5", "monitor_h*0.85" } })
hl.window_rule({ match = { title = "(Messages)" }, size = { "monitor_w*0.5", "monitor_h*0.85" } })

-- █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
-- █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█

hl.layer_rule({ match = { namespace = "rofi" },                       blur = true })
hl.layer_rule({ match = { namespace = "rofi" },                       ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" },              blur = true })
hl.layer_rule({ match = { namespace = "notifications" },              ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "swaync-control-center" },      blur = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" },      ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "logout_dialog" },              blur = true })
