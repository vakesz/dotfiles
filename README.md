# Dotfiles

My dotfiles for macOS, with Linux and WSL support. GNU Stow links `home/` into `$HOME`, `config/` (and `config-macos/` on macOS) into `$XDG_CONFIG_HOME`, and `data/` into `$XDG_DATA_HOME`.

The repo is public and the stowed files are symlinks into it, so a tool that writes to one (`git config --global`, Gradle, Claude Code settings, ssh) writes into git. Keep secrets and machine-specific values in the `*.local` files listed under [Machine-local overrides](#machine-local-overrides).

## Install

On a fresh Mac, or on Linux and WSL, run:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
```

On macOS this installs the Xcode Command Line Tools. On Linux it installs `git`, `stow` and `zsh` with the distro package manager, which needs root or `sudo`. Either way it then clones the repo to `~/projects/dotfiles` and runs `bootstrap.sh`, which installs Homebrew and the Brewfile (macOS), links the dotfiles, and offers the platform setup.

To pass flags to `bootstrap.sh`, use `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash -s -- --adopt
```

- `--adopt`: move your existing files into the repo with `stow --adopt`, replacing the repo's versions. Interactive only. Review the result with `git diff`.
- `--skip-preflight`: skip installing the Command Line Tools, Homebrew and the Brewfile.
- `DOTFILES_REPO`, `DOTFILES_DIR` and `DOTFILES_BRANCH` change the repo URL, clone location and branch that `install.sh` uses.

If the repo is already cloned, run `./bootstrap.sh` directly. After pulling, rerun it if files were added or moved. Platform details: [macOS](docs/macos.md), [Linux / WSL](docs/linux.md). macOS is the first-class platform. Debian and Ubuntu, including WSL, are tested; Fedora, Arch and openSUSE are best-effort.

## Layout

- `home/`: stowed into `$HOME`. Only files that must live directly there: `.zshenv`, `.ssh/config` and `.claude/` (CLAUDE.md, settings.json with deny rules, agents).
- `config/`: stowed into `$XDG_CONFIG_HOME`. `config-macos/` is the macOS-only part.
- `data/`: stowed into `$XDG_DATA_HOME`.
- `scripts/`: `doctor.sh`, the repo checks, shared libraries in `lib/` and platform setup in `platform/`.
- `assets/`: files the macOS setup uses. They are not stowed.
- `docs/`: longer notes: [macOS](docs/macos.md), [Linux / WSL](docs/linux.md), [Omnimount](docs/omnimount.md).

Per-user agent state at the repo root (`/.claude/`, `/.agents/`, `/skills-lock.json`) is gitignored. The tracked `home/.claude` is not.

## Make targets

`make help` lists them all. The ones used most:

- `make bootstrap` and `make adopt`: the full bootstrap.
- `make macos` and `make linux`: the platform setup on its own. Each macOS sub-script (hardening, Omnimount, Office tweaks, Spotlight) has its own `macos-*` target too.
- `make doctor`: check a bootstrapped machine. It never changes anything and exits non-zero on a failed check. `scripts/doctor.sh --only stow` runs just the stow link checks.
- `make check`: the repo checks. `.editorconfig` sets the shell formatting that `check-fmt` enforces.
- `make hooks`: points this clone at `.githooks/`. The pre-commit hook runs `gitleaks` on staged changes and fails if gitleaks is missing (bypass with `--no-verify`).

CI (`.github/workflows/checks.yml`) runs `make check`, gitleaks over the full history, and bootstrap on Ubuntu 22.04 and 24.04. On macOS it runs bootstrap and doctor with `/bin/bash`. A weekly run also fails on Brewfile entries Homebrew has deprecated or disabled.

Shell policy: `install.sh`, `bootstrap.sh` and `scripts/lib` must stay compatible with bash 3.2. Other scripts may assume Homebrew bash 5, which the Brewfile installs.

## What's configured

- `config/zsh/.zshenv`: XDG directories, `ZDOTDIR`, `EDITOR`, `VISUAL`, `HOMEBREW_NO_*`, tool locations (Go, Rust, uv, pnpm, ccache, Gradle, Android SDK) and the `PATH` every shell gets, in this order: `~/.local/bin`, rustup wrappers, cargo/uv/go/gem/composer bins, pnpm, Homebrew. Missing directories are skipped. There is no cached `brew shellenv`. On macOS `JAVA_HOME` is JDK 17: the JDK folders first, then Homebrew's `openjdk@17`, with `java_home` as the fallback. `home/.zshenv` is a shim that sets `ZDOTDIR` and sources it. Never put secrets in `.zshenv`: macOS exports it to every GUI app ([details](docs/macos.md#launchd-env-agent)).
- `config/zsh`: `.zshrc` loads `rc.d/*.zsh` in order: helpers, PATH, options, tools, completion, commands, Python venvs, keybindings, then plugins (`25-wsl.zsh` on WSL). The PATH step adds keg-only formulae and ccache just ahead of Homebrew's bin, in interactive shells only. Tool init scripts are cached in `$XDG_CACHE_HOME/zsh`. Commands you type have plain names; internal helpers start with `_dotfiles_`.
- `config/starship.toml`: the prompt. `config/ghostty`: the terminal.
- `config/git`: config and global ignores. HTTPS credentials go through Git Credential Manager. `transfer.fsckObjects` is on, and `core.fsmonitor` is off globally (enable it per large repo). The Git LFS filter is part of the config.
- `config/gh`: only the non-default keys (HTTPS protocol, the `co` alias).
- `home/.ssh/config`: GitHub uses `~/.ssh/id_ed25519`; hosts and `Include`s for container tools are listed there. No keys are tracked.
- `data/gradle/gradle.properties`: parallel builds, the build cache and the configuration cache. It is stowed from `data/` because Gradle reads user settings only from `$GRADLE_USER_HOME`.
- `config-macos/linearmouse`: mice get no acceleration and reversed scrolling; trackpads keep the system settings. `config-macos/mole`: Mole's purge paths and whitelists.
- `config/fd`, `config/ripgrep`, `config/tealdeer`, `config/topgrade.toml`: CLI tool settings. `make check-config` keeps the fd and ripgrep ignore lists in sync.
- `home/.claude`: Claude Code's global CLAUDE.md, settings (including `permissions.deny` for `~/.ssh`, `.env` files, keychain reads and force pushes) and agents.

### Machine-local overrides

Bootstrap links files one by one (`--no-folding`), so `$XDG_CONFIG_HOME/zsh` and `$XDG_CONFIG_HOME/git` are real directories. Put machine-local files there, not in the repo:

- `$XDG_CONFIG_HOME/zsh/.zshrc.local` and `$XDG_CONFIG_HOME/zsh/rc.d/*.local.zsh`
- `$XDG_CONFIG_HOME/git/gitconfig.local`: signing key, `commit.gpgsign`, credential helpers
- `~/.ssh/config.local`: machine-specific hosts
- Gradle secrets: `ORG_GRADLE_PROJECT_*` environment variables or a project-local `gradle.properties`

The repo git-ignores and stow-ignores `*.local` files as a guard.

### Shell helpers

- `rgf <rg args>`: search with ripgrep, pick a match in fzf, and open it in `$EDITOR` at that line.
- `venv [dir]`: activate a virtualenv, creating it with `uv` if needed. `venv-off` deactivates it.
- `venv-auto [dir]`: create the virtualenv if needed, write a `.envrc` that points direnv at it, and run `direnv allow`. It won't edit an existing `.envrc`.
- `zsh-profile [runs]`: time shell startup. `dots` and `c`: jump to the repo clone and to `~/projects`. `cl` is `claude`.
- Vi mode with the usual gaps filled (backspace and `^W` past the insert point, history search on `k`/`j`, `v` edits the line, text objects, block and bar cursors).

## Toolchains

- **Homebrew** installs everything in the Brewfile, including the zsh plugins, so there's no plugin manager. The login shell is the system `/bin/zsh`.
- **JavaScript**: Node, pnpm and Bun from Homebrew. **Python**: `uv`. **Ruby**: Homebrew's, gems in `$GEM_HOME`. **Rust**: Homebrew's rustup, toolchains in the XDG data directory.
- **Updates** go through `topgrade`. **Xcode** is installed separately.

More in [docs/macos.md](docs/macos.md#toolchains).
