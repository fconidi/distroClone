# Changelog

All notable changes to DistroClone are documented in this file.

Format follows Keep a Changelog (https://keepachangelog.com/en/1.0.0/).
Versioning follows Semantic Versioning (https://semver.org/).

---

## Version 1.3.6 — 2026-04-26

### Fixed

**System icon deleted after first run (icon sometimes shows convert-generated fallback)**

- `rm -f "$TEMP_LOGO"` after the Welcome dialog was unconditional: if `get_dc_logo`
  returned a real system icon path (e.g. `/usr/share/icons/hicolor/256x256/apps/distroClone.png`),
  the file was permanently deleted from the system.
  On the second run the 128×128 icon was found and then deleted as well.
  From the third run onward all real icons were gone and ImageMagick generated a
  fallback hexagon instead.
  Fix: cleanup is now guarded — only files under `/tmp/` are removed.

- `--window-icon` argument passed to `yad` without the conditional `${VAR:+...}` guard
  in three dialog calls (Welcome, User-config, Manual-edit). When `TEMP_LOGO` was empty
  yad received `--window-icon=""` which could trigger a warning or show an unexpected
  default icon. All three calls now use the same conditional form already used for
  `--image`.

**Root password set in Welcome dialog not applied to live system**

- The `[4/30] CONFIG` block at line 1715 unconditionally reset `ROOT_PASSWORD="root"`,
  overwriting the custom password captured from the Welcome dialog.
  Fix: changed to `ROOT_PASSWORD="${ROOT_PASSWORD:-root}"` so the user's choice is
  preserved and "root" is used only as a default when no password was entered.

- The `chpasswd` calls inside the chroot heredoc (`<< 'CHROOT_EOF'`) were hardcoded
  as `echo "admin:root"` and `echo "root:root"`. Single-quoted heredoc delimiters
  prevent variable expansion entirely, so `$ROOT_PASSWORD` could never reach those
  lines even after fixing the override above.
  Fix: the two `chpasswd` lines are moved outside the heredoc and executed via
  `chroot "$DEST" chpasswd` with `${ROOT_PASSWORD}` expanded in the host shell.

---

## Version 1.3.5 — 2026-04-26

### Fixed

**distroClone missing from clone and installed system**

- distroClone binaries, desktop entry, polkit policy, man page, and icons were
  listed in the rsync exclusion set used to build the squashfs image. As a result
  distroClone was absent from both the live ISO and the system installed by
  Calamares. The exclusions are removed so distroClone is fully present in the clone.

- The `remove-live-admin.service` post-install hook explicitly deleted
  `distroClone.desktop` with a comment "binaries not present on target" — a
  self-fulfilling condition caused by the exclusions above. The line is dropped.

**distroclone-backup removed by post-install autoremove**

- The post-install service purged `imagemagick-7-common` then immediately ran
  `apt-get autoremove --purge`. Because `distroclone-backup` depends on
  `imagemagick`, purging `imagemagick-7-common` cascaded and caused autoremove
  to remove `distroclone-backup`.
  Fix: the imagemagick purge block is removed entirely; only the ImageMagick GUI
  desktop entry (`display-im7.q16.desktop`) is deleted, leaving the binaries in
  place.

- `apt-mark manual distroclone distroclone-backup` is now executed in the
  post-install service before the autoremove step, preventing apt from treating
  either package as automatically installed and eligible for removal.

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
- User-configuration cloning to `/etc/skel` (theme, icons, desktop layout).
- Calamares installer with dynamic per-distribution branding.
- UEFI + Legacy BIOS dual boot (GRUB + isolinux).
- Squashfs compression options: standard xz, fast lz4, maximum xz+bcj.
- Optional manual chroot pause for custom modifications before squashfs.
- Splash screen and completion/error dialogs with DC hexagon branding.
- Snap directory exclusion for Ubuntu-based systems.
- MD5 and SHA256 checksums generated alongside the ISO.

---

Links

- https://www.syslinuxos.com
- https://www.francoconidi.it
- fconidi@gmail.com

Maintained by Franco Conidi aka edmond — GPL-3.0-or-later
