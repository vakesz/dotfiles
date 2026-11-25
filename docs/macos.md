# macOS

The [README](../README.md) has the install one-liner. This page covers the macOS platform setup. Every step asks first, and prompts default to No after `DOTFILES_CONFIRM_TIMEOUT` seconds (30 by default).

## macos.sh

`bootstrap.sh` offers `scripts/platform/macos.sh`; `make macos` runs it alone. In order, it offers:

- Touch ID for sudo (first, so later sudo prompts can use it), Rosetta on Apple Silicon, the computer name
- macOS defaults, power settings, the Dock layout
- the [GUI app PATH](#gui-app-path)
- showing `~/Library`, the custom Hungarian keyboard layout, the LLVM `dlltool` link into `$XDG_BIN_HOME` for Wine builds
- [Spotlight](#spotlight) and [Omnimount](omnimount.md), each its own script
- Xcode first-launch setup, GitHub CLI login, the stable Rust toolchain
- [hardening](#hardening) and [Office tweaks](#office-tweaks)

Each sub-script asks for confirmation itself and has its own target: `make macos-spotlight`, `macos-omnimount`, `macos-hardening` and `macos-office-tweaks`.

## GUI app PATH

Apps opened from Finder, the Dock or at login don't read `~/.zshenv`, so by default they only see `/usr/bin:/bin:/usr/sbin:/sbin` and can't find brew's `cargo`, `node` or `pnpm`. `macos.sh` offers to run `sudo launchctl config user path` with the `PATH` that `~/.zshenv` builds. launchd stores it in its own config, so it needs no LaunchAgent and applies to every app after a reboot. Re-run it after changing the base `PATH`; `make doctor` warns when it drifts.

launchd can only persist `PATH`, not other variables. GUI apps never see the rest of `~/.zshenv`, so anything they run must work with its default locations. That is why Rust uses rustup's default `~/.rustup` and `~/.cargo` instead of XDG directories.

## Hardening

`scripts/platform/macos-hardening.sh` (`make macos-hardening`), drawn from the drduh macOS security guide. It offers:

- the application firewall, Stealth Mode, and asking before signed software accepts connections (the signed-software allowlist off)
- FileVault (prints a recovery key you must save), Gatekeeper, automatic login off
- a password required immediately after the screen locks
- Remote Management off (this breaks IT remote assistance) and remote login and sharing off
- update checks, with security responses and system data files installed automatically (all four SoftwareUpdate keys)
- privacy defaults and the Homebrew analytics opt-out

On an MDM-managed Mac, some of these are refused (`socketfilterfw`) or overridden by a profile. The script warns and treats a profile-set value as settled.

## Spotlight

`scripts/platform/macos-spotlight.sh` (`make macos-spotlight`) puts high-churn dev paths on the Search Privacy list, because macOS 27 ignores `.metadata_never_index` marker files. The list lives in a root-only plist, so your terminal needs Full Disk Access. If an entry doesn't survive the Spotlight restart, the script opens System Settings so you can add it there. Once the list is updated, it rebuilds the index for both `/` and `/System/Volumes/Data`, where the home folder lives, so already-indexed items drop out.

## Office tweaks

`scripts/platform/macos-office-tweaks.sh` turns off Microsoft AutoUpdate for Office and Teams so `topgrade` handles their updates.

## Omnimount

`scripts/platform/macos-omnimount.sh` installs Omnimount for ext2/3/4 and NTFS disks. See [omnimount.md](omnimount.md).

## Doctor

`make doctor` on macOS also checks the Brewfile, system tooling, macOS defaults drift, security (FileVault, SIP, Gatekeeper, auto-login, Remote Management, the firewall signed-software allowlist, sharing, update checks), Filesystems (FUSE-T and Omnimount) and Spotlight indexing. In CI only `--only stow` runs: FileVault is off on a hosted runner and the Brewfile commands aren't installed.

## Toolchains

- **Homebrew**: Mac App Store apps need a signed-in account.
- **JavaScript**: pnpm's global binaries go in `$PNPM_HOME/bin`; formatters and linters stay project-local. `PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS=false` makes the shell always run Homebrew's pnpm, instead of downloading the version a project's `packageManager` field pins.
- **Rust**: Homebrew's rustup is the only Rust install. Its wrappers go on `PATH` ahead of `~/.cargo/bin` in every shell, so `cargo` and `rustc` stay brew-managed instead of going through rustup proxies. Toolchains live in rustup's default `~/.rustup` so [GUI apps](#gui-app-path) find them too. `macos.sh` offers the stable toolchain. ccache's compiler wrappers are on the interactive `PATH`.
- **Python**: `uv` manages versions, environments and tools. Homebrew also provides `ruff`.
- **Keg-only formulae**: `rc.d/20-path.zsh` adds `curl`, GNU `make`, Ruby, `flex` and `bison` just ahead of Homebrew's bin. GNU coreutils is only available with its `g` prefix, because the unprefixed commands break GMP builds. LLVM stays off `PATH` so `clang` is Apple's; only `dlltool` is linked into `$XDG_BIN_HOME`.
- **Updates** go through `topgrade`. Homebrew updates apps and runtimes, including self-updating apps (greedy casks). Topgrade handles the rest: tldr pages, editor and `gh` extensions, global skills, git repos, macOS and firmware.
- **Xcode** is installed separately so any build works (stable, beta or a direct download). `macos.sh` runs its first-launch setup.
