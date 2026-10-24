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
