# Dotfiles

macOS-primary dotfiles with Linux and WSL support, organized around `home/` for home-level files and `config/` for XDG-managed config.

## Quick Start

### macOS: one command on a clean machine

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash
```

This installs the Xcode Command Line Tools, clones the repo to `~/.dotfiles`,
and runs `bootstrap.sh`, which handles Homebrew, the Brewfile, stow, and the
optional macOS setup. Pass flags through with `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/vakesz/dotfiles/main/install.sh | bash -s -- --adopt
```

Override the defaults with `DOTFILES_REPO`, `DOTFILES_DIR`, or `DOTFILES_BRANCH`.

If you have already cloned the repo, `./bootstrap.sh` alone does the same work;
its macOS preflight installs the Command Line Tools, Homebrew, and the Brewfile
packages before it needs `stow`. Skip that stage with `--skip-preflight`.

### Linux / WSL

There is no preflight for Linux. Install the bootstrap prerequisites with the
distribution package manager first:

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y git stow zsh

# Fedora
sudo dnf install -y git stow zsh

# Arch Linux
sudo pacman -S --needed git stow zsh
```

The Linux setup script configures the locale, default shell, Node.js, and pnpm;
it does not install the broader macOS-oriented workstation toolset from the
`Brewfile`. Install optional tools such as `bat`, `fd`, `fzf`, `ripgrep`,
`starship`, `uv`, and `zoxide` through the distribution package manager.

Then run the bootstrap:

```bash
./bootstrap.sh
```

This stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`, then offers to run the matching platform setup script.
It also creates the XDG runtime directories used by the shell, prepares
`$GNUPGHOME` with private permissions.

### Verify the result

```bash
make doctor
```

`scripts/doctor.sh` checks that every tracked file resolves to a symlink into
this repo, that the XDG and private directories exist with the right modes,
that expected commands are on `PATH`, and that the Brewfile is satisfied. On
Linux, workstation CLIs from the Brewfile (starship, fzf, ripgrep, and so on)
are warnings rather than failures. It reports problems and exits non-zero; it
never changes anything.

### Optional machine setup

You can run the platform setup scripts directly later:

```bash
./scripts/platform/macos.sh
./scripts/platform/linux.sh
```

Node is managed through `fnm`, not Homebrew. If `fnm` is available, the platform
setup scripts offer to install the latest Node.js LTS, select it as the `fnm`
default, and enable `pnpm` via `corepack`.

Python runtimes and installable Python CLI tools are managed through `uv`.
The shell keeps `uv`'s tool bin directory on `PATH`; Homebrew is only expected
to provide the `uv` executable itself and any non-`uv` workstation formulae.

On macOS, the setup script also offers an opt-in, repeatable cleanup that
disables Microsoft auto-updaters (EdgeUpdater + MAU) so updates flow through
`topgrade` only. Application updates can reinstall updater artifacts, so rerun
the cleanup when needed:

```bash
./scripts/platform/macos-office-tweaks.sh
```

### Adopt an existing setup

If your machine already has dotfiles in place and you want to import them into this repo:

```bash
./bootstrap.sh --adopt
```

`--adopt` is interactive only. It uses `stow --adopt`, which can overwrite repo files with existing local files. Review the result with `git diff`.

## Layout

```text
dotfiles/
├── assets/
│   └── macos/            # Non-stowed assets used by platform setup
├── Brewfile
├── config/               # Stowed into ~/.config
│   ├── fd/
│   ├── ghostty/
│   ├── git/
│   ├── linearmouse/
│   ├── ripgrep/
│   ├── starship.toml
│   ├── tealdeer/
│   ├── topgrade.toml
│   └── zsh/
├── home/                 # Stowed into ~
│   └── .zshenv
├── scripts/
│   ├── doctor.sh         # Verify a bootstrapped machine
│   ├── lib/
│   │   ├── common.sh
│   │   └── macos-preflight.sh
│   └── platform/         # Optional platform setup scripts
│       ├── linux.sh
│       ├── macos.sh
│       ├── macos-hardening.sh
│       └── macos-office-tweaks.sh
├── bootstrap.sh
├── install.sh            # Remote one-liner entrypoint
└── Makefile
```

## Make Targets

| Target | Purpose |
| --- | --- |
| `make bootstrap` | Full bootstrap: preflight, stow, platform setup |
| `make adopt` | Bootstrap and import existing dotfiles into the repo |
| `make macos` / `make linux` | Run one platform setup script on its own |
| `make doctor` | Verify the machine matches what bootstrap produces |
| `make lint` | Shellcheck every bash script |
| `make brew-check` | Report Brewfile entries that are not installed |
| `make brew-install` | Install everything declared in the Brewfile |

## Repo Model

- `./bootstrap.sh` stows `home/` into `$HOME` and `config/` into `$XDG_CONFIG_HOME`.
- Re-run `./bootstrap.sh` after adding or moving files inside `home/` or `config/`.
- Keep XDG-managed config under `config/` and only true home-level files in `home/`.

### Core config

- `home/.zshenv`: early shell environment such as XDG dirs and `ZDOTDIR`
- `config/zsh`: Zsh config fragments and cached tool initialization
- `config/starship.toml`: Starship prompt theme
- `config/git`: Git config and global ignore rules
- `config/ghostty`: Ghostty config
- `config/linearmouse`: LinearMouse pointer and scroll settings. Matched by
  device *category* rather than product ID, so any mouse gets acceleration
  disabled and reversed scrolling, and any trackpad keeps system acceleration
- `config/fd`, `config/ripgrep`, `config/tealdeer`, and `config/topgrade.toml`: CLI tool config

### Optional layers

- `Brewfile`: workstation package manifest for the primary macOS setup
- `scripts/platform/linux.sh`: locale and default shell setup for Linux / WSL
- `scripts/lib/macos-preflight.sh`: Command Line Tools, Homebrew, and Brewfile
  install, shared by `bootstrap.sh` and `scripts/platform/macos.sh`
- `scripts/platform/macos.sh`: macOS defaults, Xcode CLT, Rosetta, computer
  name, power settings, Dock layout, Touch ID for sudo, Spotlight exclusions,
  the custom keyboard layout, the LLVM `dlltool` symlink, Xcode first-launch
  setup, GitHub CLI authentication, Node/pnpm setup, and the Microsoft updater
  cleanup prompt
- `scripts/platform/macos-hardening.sh`: optional security hardening (see
  [macOS Hardening](#macos-hardening))
- `scripts/platform/macos-office-tweaks.sh`: repeatably removes Microsoft
  EdgeUpdater and Microsoft AutoUpdate (MAU) launch artifacts and applies
  user-domain disable preferences

## Machine-Local Customizations

Keep machine-specific overrides untracked. Git ignores every `*.local` file,
plus `config/zsh/rc.d/*.local.zsh` (that suffix does not match `*.local`).
Stow uses the same rules, so these files stay in the repo tree without being
linked as a separate package entry:

- `config/zsh/.zshrc.local`
- `config/zsh/rc.d/*.local.zsh`
- `config/git/gitconfig.local`

These files are for local aliases, secrets, machine-specific paths, or other overrides that should not be shared.

## Shell Helpers

- `rgf <ripgrep arguments>` searches file contents with ripgrep, lets you choose
  a match with fzf, and opens it in `$EDITOR` at the matching line.
- Entering a directory with `.venv/bin/activate` only activates the environment
  after it has been explicitly trusted. Review the activation script and run
  `venv-trust` from the project root. Trust is bound to the canonical project
  path and the activation script's SHA-256; modifying the script requires
  trusting it again.
- `venv-untrust` removes trust for the current project's `.venv` and deactivates
  it when active. `venv [path]` remains the explicit create-or-activate command.

## Install Notes

- `bootstrap.sh` is the only stow entrypoint. `install.sh` exists solely to get
  a clean machine as far as running it.
- Mac App Store entries in the `Brewfile` need a signed-in App Store account.
- Touch ID for sudo is written to `/etc/pam.d/sudo_local`, which macOS 14+
  preserves across system updates.
- Interactive prompts default to **No** when no input is received within
  `DOTFILES_CONFIRM_TIMEOUT` seconds (default: `30`).
- Shell plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) install via
  `Brewfile`; no separate plugin manager bootstrap is required.
- Short navigation aliases are kept as compatibility shims:
  `dots` changes to `~/.dotfiles`, and `c` changes to `~/Code`.
- Node runtimes are managed by `fnm`. Homebrew `node` is not declared directly; if
  it appears locally, it is a dependency of another formula and not the shell's
  preferred runtime.
- Python runtimes and global Python tools should use `uv`; `UV_TOOL_BIN_DIR`
  is on `PATH` for `uv tool install` executables.
- Virtualenv trust records are private files under
  `$XDG_STATE_HOME/zsh/trusted-venvs`; they are machine-local and are not stored
  in project repositories.
- Homebrew Ruby is declared because zsh intentionally prefers
  `$HOMEBREW_PREFIX/opt/ruby/bin` over the macOS system Ruby. RubyGems are kept
  under `$GEM_HOME`, and `$GEM_HOME/bin` is on `PATH` for installed gem commands.
- Homebrew replacements that need explicit prefix paths are wired in zsh:
  `curl`, `sqlite`, GNU `coreutils`, GNU `make`, Homebrew Ruby, `flex`, and
  `bison`. Homebrew LLVM stays keg-only so `clang` remains Apple's; `macos.sh`
  only symlinks `dlltool` into `~/.local/bin`. Linked Homebrew tools such as
  `git` and `diffutils` resolve through `$HOMEBREW_PREFIX/bin` from
  `brew shellenv`.
- JavaScript formatter/linter CLIs are intentionally project-local. This repo does
  not install global `prettier`, `markdownlint-cli`, or similar npm packages.

## macOS Hardening

`scripts/platform/macos-hardening.sh` raises the security floor without getting
in the way of daily development. It is optional, idempotent, and prompted from
`macos.sh`.

It can:

- Enable the application firewall (signed apps that listen still work)
- Disable the SSH server (remote login)
- Stop crash-reporter prompts, default-to-iCloud saves, and Bonjour
  multicast advertisements
- Persist Homebrew analytics opt-out outside interactive shells
- Unhide `~/Library` in Finder

It does not:

- Turn off `--setallowsigned` (every local dev server would prompt)
- Enable stealth mode (breaks ping during local network debugging)
- Enable FileVault or SIP (both require Recovery; `make doctor` only reports
  them)
- Apply the rest of the [drduh macOS security guide](https://github.com/drduh/macOS-Security-and-Privacy-Guide)
  (firmware passwords, guest-account lockdown, and similar measures that fight
  a development workstation)

## Re-Stowing

Stow symlinks tracked files into place, so after adding or moving files under `home/` or `config/`, just re-run `./bootstrap.sh`.

## XDG Compliance

Configs are kept out of `$HOME` where possible:

- `~/.config` for config
- `~/.local/share` for data
- `~/.local/state` for state
- `~/.cache` for cache
- `~/.local/share/gnupg` for GnuPG state and sockets

## Update Strategy

System and tool updates run through `topgrade`. Homebrew cask updates use
Topgrade's greedy cask mode so apps that normally self-update are still handled
by Homebrew. Global npm and pnpm package update steps are disabled because
JavaScript tooling is project-local.

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
