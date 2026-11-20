# Linux and WSL

The [README](../README.md) has the install one-liner. This page covers what the Linux setup does.

`install.sh` installs `git`, `stow` and `zsh` with `apt-get`, `dnf`, `zypper` or `pacman`. It needs root or `sudo`. It never does a full system upgrade, so on Arch a stale package database is yours to sync (`sudo pacman -Syu`). CI bootstraps on Ubuntu 22.04 and 24.04.

`bootstrap.sh` creates the XDG directories, links the dotfiles and offers to run `scripts/platform/linux.sh` (`make linux` runs it alone). That script asks before each of four steps:

- **Locale**: installs and sets `en_US.UTF-8`.
- **CLI tools and zsh plugins**: installs what the distro repos carry. For anything they don't carry, it prints the upstream install link. It never runs a third-party installer. It does not take `node` from apt, because Debian and Ubuntu ship an end-of-life Node. It does not take `yq` from apt either: Debian's `yq` is an unrelated Python wrapper around `jq`, not the Go tool the Brewfile installs.
- **Git credential helper**: writes one to `$XDG_CONFIG_HOME/git/gitconfig.local`. On WSL it uses Git Credential Manager from Git for Windows if that is installed. Otherwise it uses libsecret when a keyring is reachable, and falls back to an in-memory cache that lasts an hour. It never overwrites a helper that is already set, and it skips the step when Git Credential Manager is already on `PATH`.
- **Default shell**: switches the login shell to zsh.

## WSL

`config/zsh/rc.d/25-wsl.zsh` sets `BROWSER=wslview` when `wslu` is installed, provides `pbcopy` and `pbpaste` through `clip.exe` and PowerShell, and keeps the Windows entries on `PATH` last.

## fzf older than 0.48

Ubuntu 24.04 ships fzf 0.44, which has no `fzf --zsh`. The shell then loads the key-binding and completion scripts that the distro package installs.

## Doctor

On Linux, missing CLI tools are only warnings. When `$CI` is set, the login-shell check warns instead of failing, because the runner's login shell is bash.
