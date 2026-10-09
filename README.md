# Dotfiles

My dotfiles for macOS, with Linux and WSL support. GNU Stow links `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`.

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

Install the prerequisites first:

```bash
sudo apt install -y git stow zsh      # Debian / Ubuntu
sudo dnf install -y git stow zsh      # Fedora
sudo pacman -S --needed git stow zsh  # Arch Linux
```

Then run `./bootstrap.sh`. It creates the XDG directories, links the dotfiles, and offers to run `scripts/platform/linux.sh` to set the locale and default shell.

The Brewfile is macOS-only, so install the CLI tools with your package manager: `bat`, `bun`, `ccache`, `direnv`, `eza`, `fd`, `fzf`, `git-lfs`, `jq`, `node`, `pnpm`, `ripgrep`, `rustup`, `starship`, `tealdeer`, `uv`, `yq` and `zoxide`. `make doctor` lists any that are missing.

### Adopt existing files

```bash
./bootstrap.sh --adopt
```

This moves your existing files into the repo with `stow --adopt`, replacing the repo's versions. It only runs interactively. Review the result with `git diff`.

### Check the result

```bash
make doctor
```

This checks that every file in `home/` and `config/` is linked, the XDG directories exist, `$GNUPGHOME` and `~/.ssh` are private, the expected commands are installed, and the Brewfile is satisfied. On macOS it also checks Touch ID for sudo, GitHub CLI login, FileVault, SIP, Gatekeeper, automatic security responses, the firewall and Stealth Mode. Missing CLI tools are only warnings on Linux. It never changes anything and exits non-zero if a check fails.

### Updating

After pulling, rerun `./bootstrap.sh` if files were added or moved under `home/` or `config/`, or if `scripts/lib/paths.sh` gained a new directory. `make doctor` shows anything still missing.

## Layout

```
dotfiles/
├── .github/workflows/    # CI checks
├── assets/macos/         # Files used by the macOS setup (not stowed)
├── Brewfile
├── config/               # Stowed into ~/.config
│   ├── .stow-local-ignore
│   ├── fd/
│   ├── ghostty/
│   ├── git/
│   ├── linearmouse/
│   ├── ripgrep/
│   ├── starship.toml
│   ├── tealdeer/
│   ├── topgrade.toml
│   └── zsh/
│       ├── .zshenv       # For nested shells that inherit ZDOTDIR
│       ├── .zprofile
│       ├── .zshrc
│       └── rc.d/         # Loaded in order by .zshrc
├── home/                 # Stowed into ~
│   └── .zshenv
├── scripts/
│   ├── check.sh          # Lint, formatting, zsh syntax and config checks
│   ├── check-apps.sh     # Validate configs with the installed apps
│   ├── doctor.sh         # Check a bootstrapped machine
│   ├── lib/
│   │   ├── macos-preflight.sh # Command Line Tools, Homebrew, Brewfile
│   │   ├── macos-state.sh     # Read-only macOS state checks
│   │   ├── paths.sh           # Repo paths, XDG defaults, runtime directories
│   │   ├── platform.sh        # OS detection
│   │   └── ui.sh              # Messages, prompts, check results
│   └── platform/         # Optional platform setup
│       ├── linux.sh
│       ├── macos.sh
│       ├── macos-hardening.sh
│       └── macos-office-tweaks.sh
├── bootstrap.sh          # Links everything with stow
├── install.sh            # One-line installer (self-contained)
└── Makefile
```

`make help` lists all targets.

## What's configured

- `home/.zshenv`: XDG directories, `ZDOTDIR`, and tool locations that non-interactive shells need too (Go, Rust, uv, pnpm, ccache, Gradle, the Android SDK, and JDK 17 via `java_home`).
- `config/zsh`: `.zshrc` loads `rc.d/*.zsh` in order: helpers, environment, PATH, options, tools, completion, commands, Python venvs, keybindings, then plugins. Tool init scripts are cached in `$XDG_CACHE_HOME/zsh` and only regenerated when the tool or its config changes. Commands you type have plain names (`venv`, `rgf`); internal helpers start with `_dotfiles_`.
- `config/starship.toml`: the prompt. Git status runs the `git` binary so the fsmonitor and untracked-cache settings apply.
- `config/git`: config and global ignores. HTTPS credentials go through Git Credential Manager. The Git LFS filter is part of the config, so `git lfs install` isn't needed.
- `config/ghostty`: the terminal.
- `config/linearmouse`: mice get no acceleration and reversed scrolling; trackpads keep the system settings.
- `config/fd`, `config/ripgrep`, `config/tealdeer`, `config/topgrade.toml`: CLI tool settings. `make check-config` keeps the fd and ripgrep ignore lists in sync.

Keep XDG config under `config/`, and only put files that must live directly in `$HOME` under `home/`.

### Machine-local overrides

Git and stow both ignore these, so they can live in the repo without being tracked:

- `config/zsh/.zshrc.local`
- `config/zsh/rc.d/*.local.zsh`
- `config/git/gitconfig.local`

### Shell helpers

- `rgf <rg args>`: search with ripgrep, pick a match in fzf, and open it in `$EDITOR` at that line.
- `venv [dir]`: activate a virtualenv, creating it with `uv` if needed. `venv-off` deactivates it.
- `venv-trust` / `venv-untrust`: a project's `.venv` only auto-activates after you trust it. Trust is tied to the project path and the activation script's SHA-256, so a changed script must be trusted again.
- `zsh-profile [runs]`: time shell startup.
- `dots` and `c`: jump to `~/.dotfiles` and `~/Code`.
- Vi mode with the usual gaps filled: backspace and `^W` work past the insert point, `^A`, `^E`, `^U` and `^K` work as expected, `k`/`j` search history in normal mode, `v` edits the line in `$EDITOR`, text objects like `ci"` and `da(` work, and the cursor is a block in normal mode and a bar in insert mode.

## Toolchains

- **Homebrew** installs the CLI tools, apps and Mac App Store apps in the Brewfile. App Store apps need a signed-in account. The zsh plugins come from Homebrew too, so there's no plugin manager. The login shell is the system `/bin/zsh`.
- **JavaScript**: Node, pnpm and Bun come from Homebrew. pnpm's global binaries go in `$PNPM_HOME/bin`; formatters and linters stay project-local.
- **Rust**: Homebrew's rustup, with toolchains in the XDG data directory. `macos.sh` offers to install the stable toolchain. ccache's compiler wrappers are on the interactive `PATH`.
- **Python**: `uv` manages Python versions, environments and tools, and its tool bin directory is on `PATH`. Homebrew also provides `ruff`.
- **Ruby**: Homebrew's Ruby comes before the system one. Gems install to `$GEM_HOME`, whose `bin` is on `PATH`.
- **Keg-only formulae**: `rc.d/20-path.zsh` adds `curl`, GNU `make`, Ruby, `flex`, `bison` and rustup to `PATH`. GNU coreutils is only available with its `g` prefix, because the unprefixed commands break GMP builds. LLVM stays off `PATH` so `clang` is Apple's; `macos.sh` only links `dlltool` into `$XDG_BIN_HOME`.
- **Updates** go through `topgrade`. Homebrew updates apps and runtimes, including self-updating apps (greedy casks). Topgrade handles the rest: tldr pages, editor and `gh` extensions, global skills, git repos, macOS and firmware.
- **Xcode** is installed separately so any build works (stable, beta or a direct download). `macos.sh` runs its first-launch setup.

## Platform setup

`bootstrap.sh` offers the script for the current platform, and each one can be run on its own later. Every step asks first, and prompts default to No after `DOTFILES_CONFIRM_TIMEOUT` seconds (30 by default).

- `scripts/platform/macos.sh`: Touch ID for sudo, Rosetta, computer name, macOS defaults, power settings, Dock layout, showing `~/Library`, Spotlight exclusions, a custom Hungarian keyboard layout, [Omnimount](#omnimount), the LLVM `dlltool` link, Xcode first-launch setup, GitHub CLI login and the stable Rust toolchain. It then runs the two scripts below.
- `scripts/platform/macos-hardening.sh`: the firewall and Stealth Mode, FileVault, remote login and sharing, privacy defaults, automatic security responses, and Homebrew analytics.
- `scripts/platform/macos-office-tweaks.sh`: turns off Microsoft AutoUpdate for Office and Teams so `topgrade` handles their updates.
- `scripts/platform/linux.sh`: the `en_US.UTF-8` locale and zsh as the default shell.

## Omnimount

`macos.sh` can build and install [Omnimount](https://github.com/ramdoor/omnimount) to mount ext2/3/4 and NTFS disks. It runs on FUSE-T from the Brewfile, which uses local NFS mounts instead of a kernel extension, so it needs no Reduced Security or Recovery changes. Don't install macFUSE alongside it; their libraries conflict.

The build:

- checks out a pinned upstream revision and applies `assets/macos/omnimount-build.patch`, which fixes the e2fsprogs and NTFS configure steps and Swift concurrency warnings, and translates the build messages and `omnimount doctor` into English (other CLI output may still be Spanish)
- targets only the Mac's own architecture, even under Rosetta. FUSE-T's libraries are in `/usr/local` on both architectures, which doesn't mean an Intel build
- happens in a temporary directory that is removed afterwards, whether or not it succeeds
- installs the app to `/Applications/Omnimount.app`, the CLI to `$(brew --prefix)/bin` and `fuse2fs` to `$(brew --prefix)/sbin`

To rebuild, for example to replace a universal build, quit Omnimount and run `OMNIMOUNT_REBUILD=1 make macos`.

### Permissions

macOS doesn't let a script grant these, so `macos.sh` prints this checklist whenever Omnimount is installed:

1. Open Omnimount, click its menu bar icon, open **Setup** and activate the helper.
2. In **System Settings > General > Login Items & Extensions** (**Login Items** on older macOS), allow Omnimount in the background.
3. In **System Settings > Privacy & Security > Full Disk Access**, click **+**, press **Cmd+Shift+G**, add `/Applications/Omnimount.app/Contents/MacOS/OmnimountHelper` and turn it on.
4. If the helper was already running, restart it: `sudo launchctl kickstart -k system/org.omnimount.helper`.

Check these again after updating, especially if the signing identity changed. `omnimount doctor` only checks the tools, not these permissions.

### Using drives

- When you connect a drive, dismiss the macOS **Initialize** prompt without initializing.
- Mount the partition from Omnimount's menu, and always eject before unplugging. Mounted disks can show up as network volumes; use Omnimount's reveal-in-Finder if they're missing from the sidebar.
- If NTFS mounts read-only, turn off Windows Fast Startup and hibernation, check the disk in Windows, and shut Windows down fully. Only force-remove a hibernation file if you're fine losing that Windows session.
- fuse2fs doesn't support every ext4 feature (internal quotas, for example). Don't change filesystem features or run repairs without a backup.
- From the command line, give Full Disk Access to your terminal and `$(brew --prefix)/bin/omnimount`, find the partition with `omnimount list`, then run `sudo omnimount mount diskXsY --read-only` (leave out `--read-only` for read/write) and `sudo omnimount unmount diskXsY`.

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [Starship](https://starship.rs/)
- [Ghostty](https://ghostty.org/docs/config)
- [fzf](https://github.com/junegunn/fzf)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [ripgrep](https://ripgrep.dev/docs/guide/)
- [fd](https://github.com/sharkdp/fd)
- [tealdeer](https://tealdeer-rs.github.io/tealdeer/)
- [topgrade](https://github.com/topgrade-rs/topgrade)
- [uv](https://docs.astral.sh/uv/)
- [Node.js](https://nodejs.org/)
- [pnpm](https://pnpm.io/)
- [Bun](https://bun.com/)
- [GnuPG](https://gnupg.org/)

