# Dotfiles

macOS-primary dotfiles with Linux and WSL support. `home/` holds the few files
that must live in `$HOME`; `config/` holds everything XDG-managed. Both are
linked into place with GNU Stow.

## Quick start

### macOS: one command on a clean machine

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
```

`install.sh` installs the Xcode Command Line Tools, clones the repo to
`~/.dotfiles`, and hands off to `bootstrap.sh`, which installs Homebrew and
the Brewfile, stows the files, and offers the optional macOS setup. Pass flags
through with `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash -s -- --adopt
```

`DOTFILES_REPO`, `DOTFILES_DIR`, and `DOTFILES_BRANCH` override `install.sh`'s
own defaults (repo URL, clone target, branch); they have no effect once
`bootstrap.sh` takes over.

With the repo already cloned, `./bootstrap.sh` does the same work. Its macOS
preflight installs the Command Line Tools, Homebrew, and the Brewfile packages
before it needs `stow`; skip that stage with `--skip-preflight`.

### Linux / WSL

There is no preflight for Linux. Install the prerequisites first:

```bash
sudo apt install -y git stow zsh      # Debian / Ubuntu
sudo dnf install -y git stow zsh      # Fedora
sudo pacman -S --needed git stow zsh  # Arch Linux
```

Then run `./bootstrap.sh`. It creates the XDG directories, prepares
`$GNUPGHOME` with private permissions, stows `home/` into `$HOME` and
`config/` into `$XDG_CONFIG_HOME`, and offers to run `scripts/platform/linux.sh`
(locale, default shell, Node.js, pnpm). The broader workstation toolset in the
`Brewfile` is macOS-only; install `bat`, `fd`, `fzf`, `ripgrep`, `starship`,
`uv`, and `zoxide` through the distribution package manager.

### Verify the result

```bash
make doctor
```

`scripts/doctor.sh` checks that every managed file in the current working tree
resolves into this repo, that the XDG and private directories have the right
modes, that expected commands are on `PATH`, and that the Brewfile is satisfied.
On macOS it also reports Touch ID for sudo, GitHub CLI auth, FileVault, SIP,
Gatekeeper, automatic security responses, and the application firewall. On
Linux, Brewfile workstation CLIs are warnings rather than failures. It exits
non-zero on any failure and never changes anything.

### Adopt an existing setup

```bash
./bootstrap.sh --adopt
```

Interactive only. It uses `stow --adopt`, which overwrites repo files with the
existing local copies; review the result with `git diff`.

### Updating an existing machine

After pulling a change that touches `scripts/lib/paths.sh` or adds a new state
directory, re-run `./bootstrap.sh` once so `ensure_xdg_runtime_directories`
creates it — most recently `$XDG_STATE_HOME/less` and `$XDG_STATE_HOME/psql`.
`make doctor` reports any directory that is still missing.

## Layout

```text
dotfiles/
├── .github/workflows/    # CI: source and configuration checks
├── assets/macos/         # Non-stowed assets used by platform setup
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
│       ├── .zprofile
│       ├── .zshrc
│       └── rc.d/         # 00-lib, 10-env, 20-path, 30-options, 40-tools,
│                          # 50-completion, 60-commands, 70-python-venv,
│                          # 80-keybindings, 90-plugins
├── home/                 # Stowed into ~
│   └── .zshenv
├── scripts/
│   ├── check.sh          # Bash lint/format, zsh syntax, config checks
│   ├── check-apps.sh     # Ask installed applications to validate their config
│   ├── doctor.sh         # Verify a bootstrapped machine
│   ├── lib/
│   │   ├── macos-preflight.sh # Command Line Tools, Homebrew, Brewfile
│   │   ├── macos-state.sh     # Read-only macOS state checks
│   │   ├── node.sh            # fnm-managed Node.js and Corepack setup
│   │   ├── paths.sh           # Repo paths, XDG defaults, runtime directories
│   │   ├── platform.sh        # OS detection
│   │   └── ui.sh              # Prompts, status output, the check vocabulary
│   └── platform/         # Optional platform setup scripts
│       ├── linux.sh
│       ├── macos.sh
│       ├── macos-hardening.sh
│       └── macos-office-tweaks.sh
├── bootstrap.sh          # The only stow entrypoint
├── install.sh            # Remote one-liner; self-contained by design
└── Makefile
```

Run `make help` for the full list of targets; there is no separate table here.

## What is configured

- `home/.zshenv`: XDG directories, `ZDOTDIR`, and tool cache/config
  redirects that must apply to non-interactive shells too (Go, uv, pnpm,
  PostgreSQL, Gradle, Android SDK, JDK 17 via `java_home`)
- `config/zsh`: `.zshrc` sources `rc.d/*.zsh` in order: shared helpers and
  platform detection, environment, PATH, shell options, tool integration,
  completion, commands, Python venv helpers, keybindings, then plugins. Tool
  init output is cached under `$XDG_CACHE_HOME/zsh` and recompiled only when
  the tool or its config changes. `30-options.zsh` selects the **vi** keymap
  before fzf initializes in `40-tools.zsh`, because fzf binds Tab into
  whichever keymap is current. Naming rule: a bare name is a command meant to
  be typed (`venv`, `rgf`, `zsh-profile`); everything else is a helper
  prefixed `_dotfiles_*`
- `config/starship.toml`: prompt. `git_status` shells out to `git` so the
  `fsmonitor` and `untrackedcache` settings in `config/git/config` apply
- `config/git`: config and global ignore rules. HTTPS credentials go through
  Git Credential Manager (`credential.helper = manager`); `macos.sh` only
  signs in the `gh` CLI itself
- `config/ghostty`: terminal
- `config/linearmouse`: pointer and scroll settings matched by device
  *category*, so any mouse gets acceleration disabled and reversed scrolling,
  and any trackpad keeps system acceleration
- `config/fd`, `config/ripgrep`, `config/tealdeer`, `config/topgrade.toml`:
  CLI tool config. `make check-config` verifies that the `fd` and `ripgrep`
  exclusion lists match

Stow symlinks tracked files, so after adding or moving files under `home/` or
`config/`, re-run `./bootstrap.sh`. Keep XDG-managed config under `config/` and
only true home-level files in `home/`.

### Machine-local overrides

Git ignores every `*.local` file plus `config/zsh/rc.d/*.local.zsh`, and stow
applies the same rules, so these stay untracked while living in the repo tree:

- `config/zsh/.zshrc.local`
- `config/zsh/rc.d/*.local.zsh`
- `config/git/gitconfig.local`

### Shell helpers

- `rgf <ripgrep arguments>`: search file contents with ripgrep, pick a match
  with fzf, and open it in `$EDITOR` at that line.
- Vi keymap, with the parts vi mode normally lacks filled in: backspace and
  `^W` work past the insert point, `^A`/`^E`/`^U`/`^K` behave as expected, `k`
  and `j` search history from normal mode, `v` opens the line in `$EDITOR`,
  `ci"`/`da(` text objects work, and the cursor is a block in normal mode and a
  bar in insert. `KEYTIMEOUT` is 1, so mode switches are immediate.
- `venv [path]`: create (with `uv`) or activate a virtualenv. `venv-off`
  deactivates.
- Entering a directory with `.venv/bin/activate` auto-activates it only after
  `venv-trust` has been run from the project root. Trust is bound to the
  project path and the activation script's SHA-256, so a modified script must
  be trusted again. `venv-untrust` removes it. Records are private files under
  `$XDG_STATE_HOME/zsh/trusted-venvs`.
- `zsh-profile [runs]`: time interactive shell startup.
- `dots` changes to `~/.dotfiles`; `c` changes to `~/Code`.

## Toolchains

- **Homebrew Bundle** provides the workstation CLIs, apps, and Mac App Store
  apps declared in the `Brewfile`. Mac App Store entries need a signed-in
  account. Shell plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`)
  come from the Brewfile too; there is no plugin manager. The login shell is
  macOS's own `/bin/zsh`.
- **Node** is managed by `fnm`, not Homebrew. The platform scripts offer to
  install the latest LTS, make it the `fnm` default, and enable `pnpm` via
  `corepack`. JavaScript formatter/linter CLIs are project-local; no global
  `prettier` or similar is installed, and topgrade's npm/pnpm steps are off.
- **Bun** and **JDK 17** are Homebrew-managed runtimes. Topgrade does not run
  their standalone updaters.
- **Python** runtimes and project environments go through `uv`;
  `UV_TOOL_BIN_DIR` is on `PATH`. Homebrew supplies the `uv` binary and the
  standalone `ruff` CLI.
- **Ruby** is Homebrew's, preferred over the system Ruby. Gems install under
  `$GEM_HOME`, whose `bin` is on `PATH`.
- **PostgreSQL 18** is Homebrew-managed and keg-only; its `bin` is added to
  `PATH` by `rc.d/20-path.zsh`. `PSQLRC`, `PSQL_HISTORY`, `PGPASSFILE`, and
  `PGSERVICEFILE` redirect its config and history under `$XDG_CONFIG_HOME`
  and `$XDG_STATE_HOME`.
- **Homebrew keg-only tools** that need explicit prefix paths are wired in
  `rc.d/20-path.zsh`: `curl`, `sqlite`, `postgresql@18`, GNU `coreutils`, GNU
  `make`, Homebrew Ruby, `flex`, and `bison`. Homebrew LLVM stays keg-only so
  `clang` remains Apple's; `macos.sh` only symlinks `dlltool` into
  `$XDG_BIN_HOME`.
- **Updates** run through `topgrade`. Homebrew owns installed application and
  runtime binaries; Topgrade owns TLDR cache, editor extension, GitHub CLI
  extension, global skill, repository, operating-system, and firmware updates.
  Greedy cask mode keeps self-updating apps under Homebrew's control.
- **Xcode** is installed separately so stable, beta, and direct-download builds
  remain interchangeable. The macOS setup handles first-launch configuration,
  and `make doctor` reports whether a full Xcode installation is available.

## Platform setup

`bootstrap.sh` offers the matching script; each can also be run later on its
own. Every step prompts, and prompts default to **No** after
`DOTFILES_CONFIRM_TIMEOUT` seconds (default `30`).

- `scripts/platform/macos.sh`: Touch ID for sudo, Rosetta, computer name,
  macOS defaults, power settings, Dock layout, Finder visibility for
  `~/Library`, Spotlight exclusions, the custom Hungarian keyboard layout, the
  LLVM `dlltool` symlink, Xcode first-launch setup, GitHub CLI auth, and
  Node/pnpm, then runs the two scripts below
- `scripts/platform/macos-hardening.sh`: optionally configures the application
  firewall, FileVault, remote login/services, privacy defaults, automatic
  security responses, and Homebrew analytics
- `scripts/platform/macos-office-tweaks.sh`: disables Microsoft EdgeUpdater and
  Microsoft AutoUpdate (MAU) so updates flow through `topgrade` only
- `scripts/platform/linux.sh`: `en_US.UTF-8` locale, zsh as the default shell,
  Node/pnpm

## Resources

- [GNU Stow](https://www.gnu.org/software/stow/)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Starship](https://starship.rs/)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [fzf](https://github.com/junegunn/fzf)
- [fnm](https://github.com/Schniz/fnm)
- [pnpm](https://pnpm.io/)
- [uv](https://docs.astral.sh/uv/)
- [ripgrep](https://ripgrep.dev/docs/guide/)
- [fd](https://github.com/sharkdp/fd)
- [tealdeer](https://tealdeer-rs.github.io/tealdeer/)
- [Ghostty](https://ghostty.org/docs/config)
- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [topgrade](https://github.com/topgrade-rs/topgrade)
- [GnuPG](https://gnupg.org/)
