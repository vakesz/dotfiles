# Dotfiles

My dotfiles for macOS, with Linux and WSL support. GNU Stow links `home/` into `$HOME`, `config/` (and `config-macos/` on macOS) into `$XDG_CONFIG_HOME`, and `data/` into `$XDG_DATA_HOME`.

## Install

### macOS

On a fresh Mac, run:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
```

This installs the Xcode Command Line Tools, clones the repo to `~/.dotfiles` and runs `bootstrap.sh`. That script installs Homebrew and the Brewfile, links the dotfiles, and offers to run the macOS setup.

To pass flags to `bootstrap.sh`, use `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash -s -- --adopt
```

`DOTFILES_REPO`, `DOTFILES_DIR` and `DOTFILES_BRANCH` change the repo URL, clone location and branch that `install.sh` uses.

If the repo is already cloned, run `./bootstrap.sh` directly. Add `--skip-preflight` to skip installing the Command Line Tools, Homebrew and the Brewfile.

### Linux / WSL

The same one-liner works on Linux and WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
```

It installs `git`, `stow` and `zsh` with `apt-get`, `dnf`, `zypper` or `pacman`, clones the repo to `~/.dotfiles` and runs `bootstrap.sh`. This needs root or `sudo`. It never does a full system upgrade, so on Arch a stale package database is yours to sync (`sudo pacman -Syu`).

macOS is the first-class platform. Debian and Ubuntu, including WSL, are tested. Fedora, Arch and openSUSE are best-effort.

`bootstrap.sh` creates the XDG directories, links the dotfiles and offers to run `scripts/platform/linux.sh`. That script asks before each of four steps:

- **Locale**: installs and sets `en_US.UTF-8`.
- **CLI tools and zsh plugins**: installs what the distro repos carry. For anything they don't carry, it prints the upstream install link. It never runs a third-party installer. It does not take `node` from apt, because Debian and Ubuntu ship an end-of-life Node. It does not take `yq` from apt either: Debian's `yq` is an unrelated Python wrapper around `jq`, not the Go tool the Brewfile installs.
- **Git credential helper**: writes one to `$XDG_CONFIG_HOME/git/gitconfig.local`. On WSL it uses Git Credential Manager from Git for Windows if that is installed. Otherwise it uses libsecret when a keyring is reachable, and falls back to an in-memory cache that lasts an hour. It never overwrites a helper that is already set, and it skips the step when Git Credential Manager is already on `PATH`.
- **Default shell**: switches the login shell to zsh.

On WSL, `config/zsh/rc.d/25-wsl.zsh` also sets `BROWSER=wslview` when `wslu` is installed, provides `pbcopy` and `pbpaste` through `clip.exe` and PowerShell, and keeps the Windows entries on `PATH` last.

If fzf is older than 0.48 (Ubuntu 24.04 ships 0.44), `fzf --zsh` doesn't exist, so the shell loads the key-binding and completion scripts that the distro package installs.

### Adopt existing files

```bash
./bootstrap.sh --adopt
```

This moves your existing files into the repo with `stow --adopt`, replacing the repo's versions. It only runs interactively. Review the result with `git diff`.

### Check the result

```bash
make doctor
```

Doctor checks a bootstrapped machine. It never changes anything and exits non-zero if a check fails. It covers the stow links, the XDG directories, private directory permissions, the expected commands and the login shell. On macOS it also covers the Brewfile, system tooling, security settings and Spotlight indexing. Missing CLI tools are only warnings on Linux, and when `$CI` is set the login-shell check warns instead of failing. `make doctor` prints every check.

### Updating

After pulling, rerun `./bootstrap.sh` if files were added or moved, or if `scripts/lib/paths.sh` gained a new directory. The first rerun after the move of `gradle.properties` to `data/` and `linearmouse.json` to `config-macos/` replaces the old links automatically. `make doctor` shows anything still missing.

## Layout

- `home/`: stowed into `$HOME`. Only files that must live directly there.
- `config/`: stowed into `$XDG_CONFIG_HOME`.
- `config-macos/`: stowed into `$XDG_CONFIG_HOME` on macOS only.
- `data/`: stowed into `$XDG_DATA_HOME`.
- `scripts/`: `bootstrap.sh` helpers, `doctor.sh`, the repo checks, shared shell libraries in `lib/` and the optional platform setup in `platform/`.
- `assets/`: files the macOS setup uses. They are not stowed.
- `docs/`: longer notes. So far, [Omnimount](docs/omnimount.md).

Per-user agent state (`.claude/`, `.agents/`, `skills-lock.json`) is gitignored and never committed.

`make help` lists all targets. `make check` runs the repo checks, and `.editorconfig` defines the shell formatting style that `make check-fmt` enforces.

## What's configured

- `config/zsh/.zshenv`: XDG directories, `ZDOTDIR`, and tool locations that non-interactive shells need too (Go, Rust, uv, pnpm, ccache, Gradle, the Android SDK, and JDK 17 via `java_home`). `home/.zshenv` is a short shim that sets `ZDOTDIR` and sources it, because zsh reads `~/.zshenv` before it knows where `ZDOTDIR` is.
- `scripts/launchd-env.zsh`: apps opened from Finder or the Dock don't read `~/.zshenv`, so they write dot-directories into `$HOME`. `macos.sh` offers to install a LaunchAgent that runs this script at login and copies every variable `~/.zshenv` exports, except `PATH`, into launchd with `launchctl setenv`. Restart an app to pick up changes.
- `config/zsh`: `.zshrc` loads `rc.d/*.zsh` in order: helpers, environment, PATH, options, tools, completion, commands, Python venvs, keybindings, then plugins. Tool init scripts are cached in `$XDG_CACHE_HOME/zsh` and only regenerated when the tool or its config changes. Commands you type have plain names (`venv`, `rgf`); internal helpers start with `_dotfiles_`.
- `config/starship.toml`: the prompt. Git status runs the `git` binary so the untracked cache, and fsmonitor in repos that turn it on, apply.
- `config/git`: config and global ignores. HTTPS credentials go through Git Credential Manager. `core.fsmonitor` is off globally because it starts a daemon per repo; enable it in large repos with `git config core.fsmonitor true`. The Git LFS filter is part of the config, so `git lfs install` isn't needed.
- `data/gradle/gradle.properties`: parallel builds, the build cache and the configuration cache for every Gradle project. Configuration-cache problems are warnings, so incompatible React Native or Expo plugins don't fail the build. Gradle only reads user settings from `$GRADLE_USER_HOME`, which is `$XDG_DATA_HOME/gradle`, so the file is stowed from `data/`.
- `config/ghostty`: the terminal.
- `config-macos/linearmouse`: mice get no acceleration and reversed scrolling; trackpads keep the system settings.
- `config/fd`, `config/ripgrep`, `config/tealdeer`, `config/topgrade.toml`: CLI tool settings. `make check-config` keeps the fd and ripgrep ignore lists in sync.

Keep XDG config under `config/` (`config-macos/` if it is macOS-only), XDG data under `data/`, and only put files that must live directly in `$HOME` under `home/`.

### Machine-local overrides

Bootstrap links files one by one (`--no-folding`), so `$XDG_CONFIG_HOME/zsh` and `$XDG_CONFIG_HOME/git` are real directories. Put machine-local files there, not in the repo:

- `$XDG_CONFIG_HOME/zsh/.zshrc.local`
- `$XDG_CONFIG_HOME/zsh/rc.d/*.local.zsh`
- `$XDG_CONFIG_HOME/git/gitconfig.local`

As a guard, the repo also git-ignores and stow-ignores `*.local` files, in case one is copied in.

### Shell helpers

- `rgf <rg args>`: search with ripgrep, pick a match in fzf, and open it in `$EDITOR` at that line.
- `venv [dir]`: activate a virtualenv, creating it with `uv` if needed. `venv-off` deactivates it.
- `venv-auto [dir]`: create the virtualenv if needed, write a `.envrc` that points direnv at it, and run `direnv allow`. direnv then activates it when you enter the directory and deactivates it when you leave. It won't edit an existing `.envrc`. `direnv allow` is the trust check, and a changed `.envrc` stays blocked until it is allowed again. The old `venv-trust` and `venv-untrust` commands are gone; delete the records in `$XDG_STATE_HOME/zsh/trusted-venvs/`.
- `zsh-profile [runs]`: time shell startup.
- `dots` and `c`: jump to the repo clone and to `~/Code`.
- Vi mode with the usual gaps filled: backspace and `^W` work past the insert point, `^A`, `^E`, `^U` and `^K` work as expected, `k`/`j` search history in normal mode, `v` edits the line in `$EDITOR`, text objects like `ci"` and `da(` work, and the cursor is a block in normal mode and a bar in insert mode.

## Toolchains

- **Homebrew** installs the CLI tools, apps and Mac App Store apps in the Brewfile. App Store apps need a signed-in account. The zsh plugins come from Homebrew too, so there's no plugin manager. The login shell is the system `/bin/zsh`.
- **JavaScript**: Node, pnpm and Bun come from Homebrew. pnpm's global binaries go in `$PNPM_HOME/bin`; formatters and linters stay project-local.
- **Rust**: Homebrew's rustup, with toolchains in the XDG data directory. Its wrappers go on `PATH` ahead of `$CARGO_HOME/bin`, in every shell, so `cargo` and `rustc` stay brew-managed instead of relying on rustup proxies. `macos.sh` offers to install the stable toolchain. ccache's compiler wrappers are on the interactive `PATH`.
- **Python**: `uv` manages Python versions, environments and tools, and its tool bin directory is on `PATH`. Homebrew also provides `ruff`.
- **Ruby**: Homebrew's Ruby comes before the system one. Gems install to `$GEM_HOME`, whose `bin` is on `PATH`.
- **Keg-only formulae**: `rc.d/20-path.zsh` adds `curl`, GNU `make`, Ruby, `flex` and `bison` to `PATH`. Homebrew's rustup wrappers take precedence over `$CARGO_HOME/bin`. GNU coreutils is only available with its `g` prefix, because the unprefixed commands break GMP builds. LLVM stays off `PATH` so `clang` is Apple's; `macos.sh` only links `dlltool` into `$XDG_BIN_HOME`.
- **Updates** go through `topgrade`. Homebrew updates apps and runtimes, including self-updating apps (greedy casks). Topgrade handles the rest: tldr pages, editor and `gh` extensions, global skills, git repos, macOS and firmware.
- **Xcode** is installed separately so any build works (stable, beta or a direct download). `macos.sh` runs its first-launch setup.

## Platform setup

`bootstrap.sh` offers the script for the current platform, and each one can be run on its own later. Every step asks first, and prompts default to No after `DOTFILES_CONFIRM_TIMEOUT` seconds (30 by default).

- `scripts/platform/macos.sh`: Touch ID for sudo, Rosetta, computer name, macOS defaults, power settings, Dock layout, showing `~/Library`, Spotlight exclusions, a custom Hungarian keyboard layout, the LLVM `dlltool` link, Xcode first-launch setup, GitHub CLI login and the stable Rust toolchain. It also runs the three scripts below, each of which asks first.
  Spotlight exclusions go on the Search Privacy list, because macOS 27 ignores `.metadata_never_index` marker files. The list lives in a root-only plist, so this step needs your terminal to have Full Disk Access. If an entry doesn't survive the Spotlight restart, the script opens System Settings so you can add it there.
- `scripts/platform/macos-hardening.sh`: the firewall and Stealth Mode, FileVault, remote login and sharing, privacy defaults, automatic security responses, and Homebrew analytics.
- `scripts/platform/macos-office-tweaks.sh`: turns off Microsoft AutoUpdate for Office and Teams so `topgrade` handles their updates.
- `scripts/platform/macos-omnimount.sh`: builds and installs Omnimount to mount ext2/3/4 and NTFS disks. `macos.sh` runs it, and it can run alone. See [docs/omnimount.md](docs/omnimount.md).
- `scripts/platform/linux.sh`: the locale, CLI tools and zsh plugins from the distro repos, a git credential helper, and zsh as the default shell. See [Linux / WSL](#linux--wsl).
