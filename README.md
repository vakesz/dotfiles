# Dotfiles

macOS-primary dotfiles with Linux and WSL support. `home/` holds the few files
that must live in `$HOME`; `config/` holds everything XDG-managed. Both are
linked into place with GNU Stow.

## Quick Start

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

Override the defaults with `DOTFILES_REPO`, `DOTFILES_DIR`, or `DOTFILES_BRANCH`.

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

`scripts/doctor.sh` checks that every tracked file resolves to a symlink into
this repo, that the XDG and private directories exist with the right modes,
that expected commands are on `PATH`, and that the Brewfile is satisfied. On
macOS it also reports Touch ID for sudo, GitHub CLI auth, FileVault, SIP,
Gatekeeper, automatic security responses, and the application firewall. On
Linux, Brewfile workstation CLIs are warnings rather than failures. It exits
non-zero on any failure and never changes anything.

### Adopt an existing setup

```bash
./bootstrap.sh --adopt
```

Interactive only. It uses `stow --adopt`, which overwrites repo files with the
existing local copies; review the result with `git diff`.

## Layout

```text
dotfiles/
├── .github/workflows/    # CI: shellcheck on push and PR
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
├── home/                 # Stowed into ~
│   └── .zshenv
├── scripts/
│   ├── doctor.sh         # Verify a bootstrapped machine
│   ├── lib/
│   │   ├── common.sh
│   │   ├── macos-common.sh   # Read-only macOS state checks (firewall, MDM, ...)
│   │   └── macos-preflight.sh
│   └── platform/         # Optional platform setup scripts
│       ├── linux.sh
│       ├── macos.sh
│       ├── macos-hardening.sh
│       └── macos-office-tweaks.sh
├── bootstrap.sh          # The only stow entrypoint
├── install.sh            # Remote one-liner; self-contained by design
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

## What Is Configured

- `home/.zshenv`: XDG directories, `ZDOTDIR`, and tool cache/config
  redirects that must apply to non-interactive shells too (Go, uv, pnpm,
  Gradle, Android SDK, JDK 17 via `java_home`)
- `config/zsh`: `.zshrc` sources `rc.d/*.zsh` in order: environment, PATH,
  tool init (fnm, starship, zoxide, fzf, dircolors), completion, aliases,
  Python venv helpers, keybindings, then plugins. Tool init output is cached
  under `$XDG_CACHE_HOME/zsh` and recompiled only when the tool or its config
  changes. The line editor uses the **vi** keymap, selected explicitly in
  `rc.d/10-env.zsh` rather than inherited from `$EDITOR`, and it must be set
  there because fzf's init binds Tab into whichever keymap is current
- `config/starship.toml`: prompt. `git_status` shells out to `git` so the
  `fsmonitor` and `untrackedcache` settings in `config/git/config` apply
- `config/git`: config and global ignore rules. `gh auth setup-git` (run by
  `macos.sh`) routes GitHub HTTPS credentials through `gh`
- `config/ghostty`: terminal
- `config/linearmouse`: pointer and scroll settings matched by device
  *category*, so any mouse gets acceleration disabled and reversed scrolling,
  and any trackpad keeps system acceleration
- `config/fd`, `config/ripgrep`, `config/tealdeer`, `config/topgrade.toml`:
  CLI tool config. The `fd` and `ripgrep` exclusion lists are kept in sync by
  hand

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

- **Homebrew** provides the workstation CLIs and apps declared in the
  `Brewfile`. Mac App Store entries need a signed-in account. Shell plugins
  (`zsh-autosuggestions`, `zsh-syntax-highlighting`) come from the Brewfile
  too; there is no plugin manager. The login shell is macOS's own `/bin/zsh`.
- **Node** is managed by `fnm`, not Homebrew. The platform scripts offer to
  install the latest LTS, make it the `fnm` default, and enable `pnpm` via
  `corepack`. JavaScript formatter/linter CLIs are project-local; no global
  `prettier` or similar is installed, and topgrade's npm/pnpm steps are off.
- **Python** runtimes and global Python CLIs go through `uv`; `UV_TOOL_BIN_DIR`
  is on `PATH`. Homebrew only supplies the `uv` binary.
- **Ruby** is Homebrew's, preferred over the system Ruby. Gems install under
  `$GEM_HOME`, whose `bin` is on `PATH`.
- **Homebrew keg-only tools** that need explicit prefix paths are wired in
  `rc.d/20-path.zsh`: `curl`, `sqlite`, GNU `coreutils`, GNU `make`, Homebrew
  Ruby, `flex`, and `bison`. Homebrew LLVM stays keg-only so `clang` remains
  Apple's; `macos.sh` only symlinks `dlltool` into `~/.local/bin`.
- **Updates** run through `topgrade`. Greedy cask mode keeps self-updating apps
  under Homebrew's control.

## Platform Setup

`bootstrap.sh` offers the matching script; each can also be run later on its
own. Every step prompts, and prompts default to **No** after
`DOTFILES_CONFIRM_TIMEOUT` seconds (default `30`).

- `scripts/platform/macos.sh`: Touch ID for sudo (written to
  `/etc/pam.d/sudo_local`, which macOS 14+ preserves across updates, and
  offered first so every later sudo prompt is a fingerprint), Rosetta, computer
  name, macOS defaults, power settings, Dock layout (needs `dockutil`),
  Spotlight exclusions, the custom Hungarian keyboard layout, the LLVM
  `dlltool` symlink, Xcode first-launch setup, GitHub CLI auth, Node/pnpm, then
  the two scripts below. Separate Spaces per display only takes effect after a
  log out, which the script says when it applies the defaults
- `scripts/platform/macos-office-tweaks.sh`: disables Microsoft EdgeUpdater and
  Microsoft AutoUpdate (MAU) so updates flow through `topgrade` only. App
  updates can reinstall the updater artifacts, so it is safe to rerun
- `scripts/platform/linux.sh`: `en_US.UTF-8` locale, zsh as the default shell,
  Node/pnpm
- `scripts/lib/macos-preflight.sh`: Command Line Tools, Homebrew, and Brewfile
  install, shared by `bootstrap.sh` and `macos.sh`

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
