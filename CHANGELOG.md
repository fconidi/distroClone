# Changelog

All notable changes to DistroClone are documented in this file.

Format follows Keep a Changelog (https://keepachangelog.com/en/1.0.0/).
Versioning follows Semantic Versioning (https://semver.org/).

---

## Version 1.4.8 — 2026-06-15

### Added

**Btrfs / SysLinuxOS 13.2 integration**

- rsync exclusion set now strips `/.snapshots`, `/.snapshots/*`,
  `@.rollback-bak-*`, and `var/lib/snapper/snapshots` from the squashfs,
  preventing source machine snapshot identities from leaking into the ISO.

- Calamares `partition.conf` gains a `btrfsSubvolumes` block for the standard
  SysLinuxOS / Debian `@` + `@home` layout. On btrfs targets Calamares creates
  both subvolumes automatically; `syslinuxos-snapshots` configures snapper on
  first boot of the installed system.

### Fixed

**Calamares "Erase disk" on btrfs host formats target as ext4**

- `partition.conf` previously hardcoded `defaultFileSystemType: "ext4"` and
  `partitionLayout[0].filesystem: "ext4"`. On a btrfs host the Calamares
  dropdown was ignored because a non-empty layout filesystem field takes
  precedence over the UI.
  Fix: `DistroClone.sh` detects the host root filesystem at build time
  (`findmnt -n -o FSTYPE /`), validates against `{ext4,btrfs,xfs}`, and
  injects it into both `defaultFileSystemType` and `partitionLayout[0].filesystem`.

**GRUB "premature end of file" on btrfs targets**

- `fstab.conf` set `compress=zstd` as a btrfs mount option. Calamares'
  mount module inherits `mountOptions` from `fstab.conf`, so `unpackfs`/rsync
  wrote kernel and initramfs files as zstd-compressed extents. GRUB 2.12's
  btrfs driver failed reading them on first boot.
  Fix: `compress=zstd` removed from `fstab.conf` btrfs `mountOptions`
  (now `defaults,noatime`). A belt-and-suspenders rewrite loop in
  `calamares-grub-install.sh` additionally rewrites every `/boot/vmlinuz-*`
  and `/boot/initrd.img-*` with `cp --reflink=never` on btrfs targets,
  forcing fresh single-extent allocation readable by GRUB.

---

## Version 1.3.8 — 2026-05-08

### Fixed

**EFI directory case conflict causes GRUB console on reinstall**

- FAT32/vfat creates two separate LFN directory entries when the same EFI
  directory name is written with different casing (e.g. `syslinuxos` vs
  `SysLinuxOS`) across installs. UEFI firmware resolves the path
  case-insensitively and may load the older `grubx64.efi`, whose `grub.cfg`
  references the old partition UUID, dropping to a GRUB console.
  Fix: `calamares-grub-install.sh` performs a case-insensitive scan of
  `/boot/efi/EFI/` before `grub-install` and removes any existing entry
  whose lowercase name matches the target `BOOTLOADER_ID`.

**Non-default kernel fails to boot on installed system**

- For non-LUKS installs, initramfs rebuilding was deferred to
  `remove-live-admin.service` (first boot), which could be skipped if the
  service exited early. The LUKS path rebuilt only the latest kernel
  (`sort -V | tail -1`), leaving other kernels with stale live initramfs.
  Fix: `calamares-grub-install.sh` iterates all kernels in `/boot` and
  runs `update-initramfs -c -k <ver>` for each, immediately after
  `grub-mkconfig`. The live hook (`/usr/share/initramfs-tools/hooks/live`)
  is temporarily renamed and `BOOT=local` injected before the loop,
  producing an initrd with no live-mode scripts.

**In-chroot mkinitramfs loop produced 0-byte initrd on some hosts**

- The step-4.5 mkinitramfs block caused 0-byte `initrd.img-*` files on
  some hosts, leaving every kernel unbootable.
  Fix: step 4.5 removed entirely. The target keeps the live-mode initrd;
  `remove-live-admin.service` rebuilds initramfs on first boot with
  `update-initramfs -c -k all` and purges `live-boot` afterwards.

**Calamares install log unreachable on failure**

- `pkexec calamares` stripped most env; no persistent diagnostics survived
  to the installed system.
  Fix: `install-system.desktop` launches `/usr/local/bin/launch-calamares.sh`
  (via pkexec). The wrapper redirects stdout+stderr to
  `/var/log/calamares-install-<timestamp>.log` and copies any
  `/tmp/Calamares*.log` alongside it. Both wrapper and policy file are
  removed from the installed target by `remove-live-admin.service`.

---

## Version 1.3.7 — 2026-05-06

### Fixed

**apt update aborts the build when a repository is offline**

- With `set -e` active, any non-zero exit from `apt update` aborted the
  entire build. Reproducible with the Liquorix kernel repository returning
  a 521 error.
  Fix: the three `apt update` calls changed to `apt-get update || true`.
  A partial repository failure is now tolerated and the build continues
  using the package cache and remaining reachable repositories.

- Version strings in the UI were still showing v1.3.3. All language blocks
  updated.

---

## Version 1.3.6 — 2026-04-26

### Fixed

**System icon deleted after first run**

- `rm -f "$TEMP_LOGO"` was unconditional: if `get_dc_logo` returned a real
  system icon path the file was permanently deleted. From the third run
  onward all real icons were gone and ImageMagick generated a fallback hexagon.
  Fix: cleanup now guarded — only files under `/tmp/` are removed.

- `--window-icon` argument passed to `yad` without the `${VAR:+...}` guard
  in three dialog calls. All three calls now use the conditional form.

**Root password set in Welcome dialog not applied to live system**

- The `[4/30] CONFIG` block unconditionally reset `ROOT_PASSWORD="root"`,
  overwriting the custom password from the Welcome dialog.
  Fix: changed to `ROOT_PASSWORD="${ROOT_PASSWORD:-root}"`.

- The `chpasswd` calls inside the chroot heredoc were hardcoded.
  Fix: both lines moved outside the heredoc and executed via
  `chroot "$DEST" chpasswd` with `${ROOT_PASSWORD}` expanded in the host shell.

---

## Version 1.3.5 — 2026-04-26

### Fixed

**distroClone missing from clone and installed system**

- distroClone binaries were listed in the rsync exclusion set. As a result
  distroClone was absent from both the live ISO and the installed system.
  Fix: exclusions removed. `remove-live-admin.service` line that deleted
  `distroClone.desktop` also dropped.

**distroclone-backup removed by post-install autoremove**

- The post-install service purged `imagemagick-7-common` then ran
  `apt-get autoremove --purge`, which cascaded and removed `distroclone-backup`.
  Fix: imagemagick purge block removed entirely; only the GUI desktop entry
  (`display-im7.q16.desktop`) deleted. `apt-mark manual distroclone distroclone-backup`
  now runs before the autoremove step.

---

## Version 1.3.4 — 2026-03-23

First public release of the universal Debian-based ISO builder.

### Added

- Auto-detection of distribution, version, and desktop environment at runtime.
- Multilanguage graphical interface: English, Italian, French, Spanish, German,
  Portuguese — auto-detected from system locale, overridable with `--lang=`.
- YAD advanced interface with Zenity and terminal fallback.
- Real-time build log window showing all 30 build steps.
- Welcome dialog: compression type, root password, hostname selection.
- User-configuration cloning to `/etc/skel`.
- Calamares installer with dynamic per-distribution branding.
- UEFI + Legacy BIOS dual boot (GRUB + isolinux).
- Squashfs compression: standard xz, fast lz4, maximum xz+bcj.
- Optional manual chroot pause for custom modifications before squashfs.
- MD5 and SHA256 checksums generated alongside the ISO.

---

Links

- https://www.syslinuxos.com
- https://www.francoconidi.it
- fconidi@gmail.com

Maintained by Franco Conidi aka edmond — GPL-3.0-or-later
