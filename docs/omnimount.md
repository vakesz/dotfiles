# Omnimount

[Omnimount](https://github.com/ramdoor/omnimount) mounts ext2/3/4 and NTFS disks on macOS. It lives in its own script, `scripts/platform/macos-omnimount.sh`. `scripts/platform/macos.sh` calls it, and you can also run it alone. See the [README](../README.md) for the rest of the setup.

It runs on FUSE-T from the Brewfile, which uses local NFS mounts instead of a kernel extension, so it needs no Reduced Security or Recovery changes. Don't install macFUSE alongside it; their libraries conflict.

## Install

The script asks before it changes anything. FUSE-T comes from the Brewfile, so run `./bootstrap.sh` first. It stops if macFUSE is installed.

When `/Applications/Omnimount.app` has a stapled notarization ticket, the script leaves that app in place and points `$(brew --prefix)/bin/omnimount` and `$(brew --prefix)/sbin/fuse2fs` at the copies inside it. Homebrew does not manage those two paths: `brew cleanup` will not update or remove them. Sparkle updates the app, and the symlinks follow the new binaries. Replacing the notarized app with a local build would change the signing identity and drop Full Disk Access.

A source build runs only when that notarized app is absent. It:

- checks out Omnimount v0.4.8 and applies `assets/macos/omnimount-build.patch`, which builds for this Mac's architecture, including under Rosetta, and fixes the Swift concurrency warnings. Upstream messages are left unchanged
- downloads e2fsprogs 1.47.3 and ntfs-3g 2026.7.7, checks their sha256, and hands those trees to the build
- records the revision, architecture, FUSE-T version and signing identity in `$XDG_STATE_HOME/omnimount/build.stamp`, and builds again when one of those no longer matches
- writes `$XDG_STATE_HOME/omnimount/build.log`, removes the build tree afterwards, and keeps the tree when `OMNIMOUNT_KEEP=1`
- stops if Omnimount or its helper is running, because the install replaces `/Applications/Omnimount.app`

`OMNIMOUNT_REBUILD=1` forces another pass. With a notarized app, that pass only refreshes the symlinks. Quit Omnimount first when the pass will compile.

```bash
OMNIMOUNT_REBUILD=1 make macos
OMNIMOUNT_REBUILD=1 ./scripts/platform/macos-omnimount.sh
OMNIMOUNT_KEEP=1 ./scripts/platform/macos-omnimount.sh
```

An ad-hoc signature, used when the keychain has no codesigning identity, does not keep Full Disk Access across rebuilds. The script warns when the installed CLI is signed that way.

## Checks

`make doctor` checks that the FUSE-T cask and `/usr/local/lib/libfuse-t.dylib` are present, that macFUSE is absent, and, when Omnimount.app is installed, that `$(brew --prefix)/bin/omnimount --version` matches the app and that `fuse2fs` links FUSE-T. A missing app is a warning: the install is optional. `omnimount doctor` only checks that the filesystem tools can be found.

## Permissions

macOS doesn't let a script grant these, so the script prints this checklist whenever Omnimount is installed:

1. Open Omnimount, click its menu bar icon, open **Setup** and activate the helper.
2. In **System Settings > General > Login Items & Extensions** (**Login Items** on older macOS), allow Omnimount in the background.
3. In **System Settings > Privacy & Security > Full Disk Access**, click **+**, press **Cmd+Shift+G**, add `/Applications/Omnimount.app/Contents/MacOS/OmnimountHelper` and turn it on.
4. If the helper was already running, restart it after granting access or rebuilding: `sudo launchctl kickstart -k system/org.omnimount.helper`.

Check these again after updating, especially if the signing identity changed. `omnimount doctor` only checks the tools, not these permissions.

## Using drives

- When you connect a drive, dismiss the macOS **Initialize** prompt without initializing.
- Mount the partition from Omnimount's menu, and always eject before unplugging. Mounted disks can show up as network volumes; use Omnimount's reveal-in-Finder if they're missing from the sidebar.
- If NTFS mounts read-only, turn off Windows Fast Startup and hibernation, check the disk in Windows, and shut Windows down fully. Only force-remove a hibernation file if you're fine losing that Windows session.
- fuse2fs doesn't support every ext4 feature (internal quotas, for example). Don't change filesystem features or run repairs without a backup.
- From the command line, give Full Disk Access to your terminal and `$(brew --prefix)/bin/omnimount`, find the partition with `omnimount list`, then run `sudo omnimount mount diskXsY --read-only` (leave out `--read-only` for read/write) and `sudo omnimount unmount diskXsY`.
