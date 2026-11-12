# Omnimount

[Omnimount](https://github.com/ramdoor/omnimount) mounts ext2/3/4 and NTFS disks on macOS. It lives in its own script, `scripts/platform/macos-omnimount.sh`. `scripts/platform/macos.sh` calls it, and you can also run it alone. See the [README](../README.md) for the rest of the setup.

It runs on FUSE-T from the Brewfile, which uses local NFS mounts instead of a kernel extension, so it needs no Reduced Security or Recovery changes. Don't install macFUSE alongside it; their libraries conflict.

## Install

The script asks before it builds anything, and skips the build if FUSE-T, the CLI and the app are already installed. FUSE-T comes from the Brewfile, so run `./bootstrap.sh` first.

The build:

- checks out a pinned upstream revision and applies `assets/macos/omnimount-build.patch`, which fixes the e2fsprogs and NTFS configure steps and Swift concurrency warnings, and translates the build messages and `omnimount doctor` into English (other CLI output may still be Spanish)
- targets only the Mac's own architecture, even under Rosetta. FUSE-T's libraries are in `/usr/local` on both architectures, which doesn't mean an Intel build
- happens in a temporary directory that is removed afterwards, whether or not it succeeds
- installs the app to `/Applications/Omnimount.app`, the CLI to `$(brew --prefix)/bin` and `fuse2fs` to `$(brew --prefix)/sbin`

To rebuild, for example to replace a universal build, quit Omnimount and run one of:

```bash
OMNIMOUNT_REBUILD=1 make macos
OMNIMOUNT_REBUILD=1 ./scripts/platform/macos-omnimount.sh
```

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
