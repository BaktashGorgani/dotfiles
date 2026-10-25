# Created using [chezmoi](https://www.chezmoi.io/)

## macOS

Homebrew is the only prerequisite (it is installed by the dotfiles if missing, but
needs Xcode command line tools and a sudo prompt). With it:

```
brew install chezmoi
chezmoi init --apply BaktashGorgani
```

The install script then installs the CLI tools the configs rely on, plus the
kitty, Google Chrome and Warp casks and the Monofur Nerd Font. Casks whose app
is already in `/Applications` (installed by hand) are skipped. You will be asked
for the passphrase of the encrypted age key during the first apply.

## Linux / other

To install on a new machine:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply BaktashGorgani
```

Or to install on a machine that already has chezmoi installed:

```
chezmoi init --apply BaktashGorgani
```

## Updating packages

Package upgrades run automatically on every `chezmoi apply`, including the
apply performed by `chezmoi update --refresh-externals`. Use the `cur` alias
to pull the dotfiles, refresh externals, apply the configuration, and run
package updates.

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

Run the isolated regression tests with
`python3 -m unittest discover -s tests -v`.
