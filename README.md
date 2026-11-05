# Created using [chezmoi](https://www.chezmoi.io/)

Personal dotfiles for a Fedora Hyprland desktop and macOS, with shared Zsh,
tmux, kitty, Git, and development tools. Linux desktop settings include
machine-specific monitor names, NVIDIA settings, application paths, and services;
review these before applying on another machine.

## What's managed

- **Shell:** Oh My Zsh, autosuggestions, syntax highlighting, fzf-tab, vi mode,
  an Oh My Posh Night Owl prompt, zoxide navigation, and fuzzy file/Git helpers.
  Bash configuration and custom Zsh completions are also included.
- **Terminal:** kitty, tmux with Catppuccin Mocha, Nerd Font window icons,
  tmux-yank, resurrect/continuum session persistence, and floax.
- **Editor and previews:** Neovim is pulled from the separate
  [nvim-config repository](https://github.com/BaktashGorgani/nvim-config);
  less/fzf previews use tools such as bat, eza, chafa, and syncat.
- **Linux desktop:** modular Lua-based Hyprland configuration, Sway configuration,
  Waybar, Rofi, Dunst, hypridle/hyprlock, wlogout, clipboard services, wallpaper
  rotation, and Gammastep.
- **System integration:** Linux user services, local browser activity logging,
  Fedora release notifications, boot-entry maintenance, and a GDM monitor layout.

## Installation notes

The initial apply requires the passphrase for `key.txt.age`. The before-script
decrypts the age identity to `~/.config/chezmoi/key.txt` with mode `0600` if it is
missing; chezmoi then uses it for the encrypted shell files and SSH helper.
The identity is not stored in plaintext in this repository.

Applying these dotfiles also installs software and runs package upgrades; it is
not just a configuration-file copy.

## macOS

Install the Xcode command line tools and Homebrew before using the `brew`
bootstrap below. The dotfiles can install Homebrew if missing when chezmoi is
bootstrapped another way; that installation may require sudo.

```sh
brew install chezmoi
chezmoi init --apply BaktashGorgani
```

The install script then installs the CLI tools the configs rely on, plus the
kitty, Google Chrome and Warp casks and the Monofur Nerd Font. Casks whose app
is already in `/Applications` (installed by hand) are skipped.

Wayland desktop files, systemd units, Linux MIME associations, and activity-watch
helpers are excluded on macOS. kitty treats Option as Alt for tmux shortcuts,
and tmux-yank uses the native clipboard instead of `wl-copy`.

## Linux

To install on a new machine:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply BaktashGorgani
```

Or to install on a machine that already has chezmoi installed:

```sh
chezmoi init --apply BaktashGorgani
```

Full DNF and Flatpak installation/update automation runs **on Fedora regardless
of hostname**. It enables the Hyprland/nwg-shell COPRs, RPM Fusion,
Google Chrome, and the additional repositories declared in the package inventory.
Flatpak applications are installed explicitly from `flathub`; that remote must
already be configured. Cisco Secure Client VPN, Webex, and Zoom require manual
RPM installation; the installer only reports whether they are present.

Non-Fedora Linux hosts still receive shared Homebrew/Rust/pipx setup and Linux
desktop files, and the user-unit setup script still runs. Install the required distro
packages and review the service list before applying there; this is not a complete
generic Linux bootstrap. In particular, pipx maintenance expects
`/usr/bin/python3` and `/usr/bin/pipx`. Fedora boot and GDM installers are gated
by distribution, **not** by hostname.

Fedora release notifications are enabled alongside the desktop setup.
Their dependencies are declared explicitly; see
[Fedora release notifications](#fedora-release-notifications).

The hostname does not select a smaller Fedora profile: a new Fedora workstation
receives the same managed files, package inventory, repositories, and user-unit
setup as this PC. The checks use the Fedora distribution ID, not the installed
desktop environment, so they also apply to Fedora spins. Review the monitor layout,
NVIDIA configuration, local paths/assets, and manually installed tools before
using this setup on different hardware; those are not auto-detected or cloned
from the current PC.

## Configuration map

Paths below are in the chezmoi source directory (`chezmoi source-path`).
Chezmoi maps `dot_` to a leading `.`, `private_` to private permissions, and
`executable_` to an executable target; `.tmpl` files are rendered before use.

- `.chezmoidata/packages.yaml`: shared and OS-specific package inventories,
  Fedora repository definitions, manual RPM reminders, and TPM plugins.
- `.chezmoiexternal.toml`: Oh My Zsh, Zsh plugins, TPM, tmux themes/helpers,
  and the separate Neovim repository. Most externals have a seven-day refresh
  period; Neovim has a one-day period.
- `dot_zshrc` and `dot_zsh_custom/`: shell plugins, aliases, functions,
  keybindings, environment, and encrypted secrets.
- `dot_tmux.conf`, `dot_gitmux.conf`, `dot_gitconfig`, and
  `private_dot_config/kitty/`: terminal, multiplexer, and Git settings.
- `private_dot_config/hypr/`: Hyprland entry point `hyprland.lua`, Lua modules
  under `lua/`, idle/lock settings, and desktop scripts.
- `private_dot_config/` also contains Sway, Waybar, Rofi, Dunst, wlogout,
  rustfmt, and syncat configuration; `mimeapps.list` defines file/URL handlers.
- `private_dot_config/systemd/user/` and `private_dot_local/bin/`: user units
  and activity-watch/release-check helpers. `scripts/` contains
  tmux/SSH/scrollback helpers.
- `.chezmoitemplates/`: shared maintenance helpers, the boot hook, and GDM XML.
  Root-level `run_*` scripts automate installation, upgrades, and setup.

Edit the source files and apply with chezmoi rather than editing generated target
files without bringing the changes back into the source.

## Updating packages

Package upgrades run automatically on every `chezmoi apply`, including the
apply performed by `chezmoi update --refresh-externals`. Use the `cur` alias
to pull the dotfiles, refresh externals, apply the configuration, and run
package updates.

The install script is `run_onchange_install-packages.sh.tmpl` (runs when its
rendered contents change); `run_update-packages.sh.tmpl` runs on every apply.
The update workflow includes:

- DNF upgrades, autoremove, and package-cache cleanup, plus Flatpak upgrades,
  stale exact-runtime-pin cleanup, and unused-runtime removal on Fedora hosts.
- Homebrew metadata refresh, upgrades, autoremove, and cache cleanup.
- Repair and upgrade of the declared pipx tools (`git-filter-repo`, `isort`,
  and `mypy`), including broken launchers or environments left behind by Python
  upgrades. Linux uses distro Python; macOS uses Homebrew Python.
- TPM plugin updates, blocking Neovim Lazy sync, a Mason Jedi language-server
  health check/repair, and explicit Tree-sitter parser updates.
- Rust toolchain and Cargo package upgrades, including Git-installed crates,
  followed by Cargo cache cleanup.

Language servers are managed by Neovim's Mason rather than pipx. The shared
Homebrew list includes Go for `gopls` builds and `tree-sitter-cli` for parser
builds. syncat has its own language inventory and a one-time `syncat install`
script under `private_dot_config/syncat/`.

Install/update scripts stop on failures rather than reporting successful
upgrades. An apply can therefore stop at package maintenance; inspect the reported
command before retrying. Package operations are not transactional, so earlier
steps may already have completed.

### Useful shell and tmux commands

- `cur`: pull, refresh externals, apply, and upgrade packages.
- `tm`: create or attach to tmux session `Main`; `lg`: open lazygit.
- `fnv`: fuzzy-select files for Neovim (`Ctrl+V` opens vertical splits);
  `frg`: live ripgrep/fzf search that opens the selected line in Neovim.
- `fgc`, `fgbc`, `fgcc`: fuzzy Git checkout helpers for branches/commits.
- `ez` / `ezt`: detailed eza listing / tree; `disks`: disk usage via gdu
  (`gdu-go` on macOS).
- In tmux, `Alt+P` toggles floax, `Ctrl+Alt+H` opens scrollback in Neovim,
  `Ctrl+Q` opens the fuzzy window switcher, and `Ctrl+Left/Right` changes windows.
  Prefix + `r` reloads the configuration; the default prefix is `Ctrl+B`.

## Linux desktop

### Hyprland

`hyprland.lua` loads `lua/settings.lua`, `lua/autostart.lua`, `lua/binds.lua`,
and `lua/rules.lua`; shared application commands live in `lua/apps.lua`.
The layout uses the HP display on `DP-2` at `0x0` on the left, the Samsung display
on `DP-1` at `1920x0` in the middle (scale 1.25), and a rotated `HDMI-A-1` at
`3968x0` on the right. Workspaces 1, 2, and 3 are assigned to those outputs,
respectively. Dunst notifications stay on the center Samsung (`monitor = DP-1`,
`follow = none`) rather than relying on an unstable monitor index.
NVIDIA-specific environment variables and software cursors are enabled.
Chrome, Warp, kitty, Discord, and a privileged btop task-manager window are
started with the session.

Selected bindings (`Super` is the Windows key):

- `Super+Q`: kitty; `Super+E`: Thunar; `Super+Shift+X`: close window.
- `Super+A`: application launcher; `Super+Tab`: window switcher;
  `Super+Shift+E`: Rofi file browser; `Super+V`: clipboard history.
- `Super+Ctrl+S`: screenshot with grimshot and optional Swappy editing, saved
  under `~/Pictures/Screenshots` (create the directory before use).
- `Super+Ctrl+Escape`: privileged btop; `Super+Ctrl+L`: wlogout.
- `Super+H/J/K/L` or arrows: focus; add Shift to move windows.
- `Super+1/2/3` have monitor-specific behavior, not normal workspace selection.
  `Super+1` swaps center/left workspaces; `Super+2` focuses the center;
  `Super+3` swaps center/right; `Super+=` swaps right/left. `Super+Shift+1/2/3`
  moves the active window to the left/center/right display.
  Use `Super+Ctrl+1/2/3` to bring those workspaces to the current monitor.
- `Super+T/C/W/S/O`: toggle terminal/chats/work/floatingwindow/outoftheway
  special workspaces. See `lua/binds.lua` for the complete binding list.

HTTP/HTTPS links, HTML/XHTML, and `text/xml` are routed through Junction via
`mimeapps.list`; many text/source files default to Neovim.

### User services and local dependencies

The Linux setup script reloads systemd user units and enables wallpaper/idle
handling, Waybar, Dunst, Gammastep and its hotplug watcher, Polkit authentication,
clipboard persistence/history, wallpaper rotation, and activity-watch.
It masks `swaync.service` to avoid competing with Dunst, and
`hyprpolkitagent.service` because of the documented COPR Qt6 ABI incompatibility.

The fallback Polkit service requires a manually built
`/usr/local/libexec/polkit-gnome-authentication-agent-1`; this binary is not
installed by the dotfiles. Some desktop helpers also rely on tools/assets outside
the managed inventory, so check the relevant script before enabling it elsewhere.
Wallpaper rotation expects images in `~/wallpaper` and runs every five minutes.
Gammastep is configured at 4000 K; hypridle locks after five minutes.

Check service failures and logs with:

```sh
systemctl --user --failed
systemctl --user list-timers
journalctl --user -u change-wallpaper.service -b
```

### Cloud drive mounts

Two optional rclone user services mount Google Drive at `~/Cloud/GoogleDrive`
(`rclone-gdrive.service`) and OneDrive at `~/Cloud/OneDrive`
(`rclone-onedrive.service`). Their definitions are managed under
`private_dot_config/systemd/user/`; Fedora's package inventory includes `rclone`
and `fuse3`. On other Linux distributions, install these dependencies separately.

Account credentials are deliberately **not managed by chezmoi**. On each new PC,
run `rclone config` and create remotes named exactly `gdrive` (Google Drive) and
`onedrive` (Microsoft OneDrive). Keep the configuration at the path used by the
units, `~/.config/rclone/rclone.conf`, and restrict its permissions:

```sh
rclone config
chmod 600 ~/.config/rclone/rclone.conf
```

For Google Drive, create your own Desktop OAuth client following
[rclone's client-ID instructions](https://rclone.org/drive/#making-your-own-client-id).
Set the Google OAuth app to **In production** before authorizing to avoid
Testing mode's seven-day refresh-token expiration. Google may require a homepage,
privacy-policy URL, and authorized domain under Branding before publication.
If already authorized in Testing, run `rclone config reconnect gdrive:` after
publishing. For OneDrive, the default client credentials normally work; select
the actual **OneDrive** drive, not an internal metadata/archive drive.
See the [OneDrive configuration guide](https://rclone.org/onedrive/).

Verify access before enabling each service:

```sh
rclone lsd gdrive:
rclone lsd onedrive:
systemctl --user daemon-reload
systemctl --user enable --now rclone-gdrive.service rclone-onedrive.service
```

Run the enable/start command from an active graphical session; enable only the
service for accounts you have configured. The general user-unit setup hook does
not enable these optional mounts automatically. Mount directories are created
by the services and must be empty before their first mount. Stop any manually
started rclone mounts before starting the services to avoid duplicate mounts.

Like the other custom desktop units, these services are wanted by
`graphical-session.target` and stop when that target stops. The Hyprland session
must activate that target, as it does on this PC; no extra Hyprland autostart
command is needed. No `/etc/fstab` entry, lingering, or system-boot dependency is
used. Failed starts time out after 45 seconds and retry after 15 seconds without
blocking desktop startup.

These are **read/write cloud mounts**, not offline mirrors or backups: edits and
deletions affect the cloud account. Full VFS caching uses local disk space under
`~/.cache/rclone`; writes may upload after an application closes the file. Allow
uploads to finish before logging out, and do not delete the cache with pending
uploads. Neither cached cloud data nor OAuth secrets/tokens should be added to
this repository.

Inspect status/logs or disable automatic mounting with:

```sh
systemctl --user status rclone-gdrive.service rclone-onedrive.service --no-pager
journalctl --user -u rclone-gdrive.service -u rclone-onedrive.service -b --no-pager
systemctl --user disable --now rclone-gdrive.service rclone-onedrive.service
```

Use systemd to stop the managed services rather than unmounting them manually.

### Activity logging

The local activity-watch helpers log browser window/tab titles from Hyprland
and check for removed Chrome history entries every five minutes. Data stays under
`~/.local/share/activity-watch/` and is retained for 30 active days; generated
logs are not tracked by chezmoi.

Run `activity-watch` for help, `activity-watch --check` to view findings since
the last checkpoint, or `activity-watch --check --mark-read` to advance it.
Use `--pause` / `--resume` to stop/start tracking, and `--delete` to reset only
activity-watch's records (not Chrome history). Linux Zsh aliases
`activity-watch-check`, `activity-watch-pause`, `activity-watch-resume`, and
`activity-watch-delete` expand to the corresponding actions.
See [README-activity-watch.md](README-activity-watch.md) for implementation,
log paths, service commands, and limitations.

### Fedora release notifications

On Fedora, a normal `chezmoi apply` installs the release-check dependencies
(`bash`, `coreutils`, `curl`, `dunst`, `jq`, `libnotify`, `systemd`, `util-linux`,
and `xdg-utils`) if missing, deploys `~/.local/bin/fedora-release-check` and its
user service/timer, and enables `fedora-release-check.timer`. This feature is
not hostname-gated. The helper and user units are excluded on macOS; the timer
is not enabled on other Linux distributions.

The timer checks about 30 seconds after each graphical login, then every 24 hours
while the session stays active. It belongs to `graphical-session.target` and stops
on logout; the next login starts a fresh schedule even if the user manager stays
running. There is no midnight schedule or random delay. The service only runs in
an active `graphical-session.target`; a working Dunst session and network are
required. The setup hook recreates enablement links to migrate older
`timers.target` installations automatically.
Fedora's official `releases.json` is compared with `/etc/os-release`, ignoring
beta and Rawhide entries. The release list may lag a release announcement.
No packages or release upgrades are downloaded or installed by the checker.

When a newer stable release exists, Dunst shows a notification for 60 seconds.
Left-click to open the existing action menu and select **Open upgrade guide**
to open the [Fedora offline upgrade documentation](https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/).
The URL uses your configured HTTP/HTTPS handler (Junction in these dotfiles;
it must be installed, or choose another installed handler). The opener runs in
a separate transient user service so a browser chooser cannot block the checker.
Other notifications and global Dunst mouse bindings are unchanged.

Every check notifies if a newer stable release is available, including when the
same release was announced earlier that day. There is no weekly suppression.
The last successful notification is recorded for diagnostics in
`${XDG_STATE_HOME:-~/.local/state}/fedora-release-check/last-notified`; that record
does not control the schedule and is not managed or copied by chezmoi.
Failed network/notification requests leave the record unchanged; another attempt
happens at the next scheduled check.

Inspect or manually run the check with:

```sh
systemctl --user --no-pager list-timers fedora-release-check.timer
systemctl --user start fedora-release-check.service
journalctl --user -u fedora-release-check.service -b --no-pager
```

A manual check also notifies immediately if a newer release exists. To temporarily
disable checks, run `systemctl --user disable --now fedora-release-check.timer`.
The user-unit setup hook enables it again when that hook next runs.

## Fedora GDM monitor layout

On Fedora with GDM installed, the run-onchange installer merges
`.chezmoitemplates/gdm-monitors.xml` into
`/var/lib/gdm/seat0/config/monitors.xml` using sudo. GDM must have been started
so its seat-specific configuration directory exists.
The layout matches the three-monitor desktop arrangement, but uses GDM/Mutter
identities (notably `HDMI-1` rather than Hyprland's `HDMI-A-1`).
The HP uses `DP-2` at `0x0`; the primary Samsung uses `DP-1` at `1920x0`.
GDM uses scale 1 for the center display (unlike Hyprland's 1.25), so the rotated
right display starts at `4480x0` instead of `3968x0`.
Review the XML's monitor identities and modes before applying on other hardware.

Unrelated monitor combinations are preserved. An existing file is backed up as
`monitors.xml.backup-<timestamp>` before a change; writes are atomic and SELinux
labels are restored. Matching layouts are left alone, and the installer does not
restart GDM or interrupt the session. Template changes trigger another merge on
the next apply.

## Fedora boot entries

On Fedora, `chezmoi apply` installs a root-owned kernel-install hook at
`/etc/kernel/install.d/zz-local-boot-entries.install` (sudo is required).
It runs once during setup and automatically after future kernel installations.
Changes to its source in `.chezmoitemplates/fedora-boot-entries.install`
reinstall the hook on the next apply.

The highest-version standard Fedora kernel for this machine remains visible,
with a title such as `Fedora Linux 44 7.2.11`, and becomes the saved GRUB default.
Older standard entries and the rescue entry move to unique directories under
`/boot/loader/entries-archive/`. Before editing the newest entry's title, the hook
also saves a copy in `/boot/loader/entries-archive/originals/`, using the same
filename. This first-seen copy is never overwritten by later refreshes or
reinstallations of the same kernel version. The backup must succeed before any
title or default changes. Entries already edited before this feature was enabled
can only be backed up in their current state; their old titles cannot be recovered.
Custom/debug and other machines' entries are
untouched. Kernel packages, images, initramfs files, and boot arguments are not
removed or changed. Cleanup aborts if the retained kernel or initramfs is missing
or empty, or if its entry references unexpected images.

When a title changes, the hook prints both its original and renamed title;
unchanged titles do not produce rename messages.

Only the newest standard entry remains in the boot menu, even before its first
successful boot. Archives are not bootable backups: package updates can still
remove the old images they reference.

To list archives, run `sudo ls -R /boot/loader/entries-archive`. To restore an
entry, first check that the kernel and initramfs named inside it still exist
under `/boot`, then copy that `.conf` file back into `/boot/loader/entries/`
using `sudo cp -i`. Restored alternatives are archived again on the next kernel
installation or hook refresh. To stop archiving temporarily, remove the installed
hook; chezmoi will reinstall it when the installer source changes or its script
state is reset.

## Tests

Run from the source directory:

```sh
python3 -m unittest discover -s tests -v
```

The isolated tests cover boot-entry archiving/backups/title logging and Python
tool maintenance, including pipx repair, Linux/macOS template rendering, and
Mason Jedi health/repair/error paths, plus Fedora release detection, login/daily
timer configuration, repeat notifications, actions, and fresh-host platform guards.
Boot paths and package commands are redirected
to temporary fixtures/mocks rather than changing the real boot menu or installing
packages. Template checks require chezmoi and Mason helper tests require Neovim;
those tests are skipped if the corresponding executable is unavailable.
