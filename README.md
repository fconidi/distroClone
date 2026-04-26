# distroClone

**Universal Live ISO Builder for Debian-based distributions**



DistroClone creates a bootable live ISO image from any running Debian-based system, preserving the current configuration, installed packages, desktop theme, and user settings. The resulting ISO includes the Calamares installer for permanent installation on other machines.



<img width="1472" height="720" alt="DC-Welcome" src="https://github.com/user-attachments/assets/ab9fdd83-f0aa-4017-b809-ab88aa559243" />


---

DEFAULT PASSWORD LIVE = root

---

## Supported Distributions

| Distribution | Versions |
|---|---|
| Debian | Bookworm and later |
| Ubuntu | 22.04 and later |
| Linux Mint | All current releases |
| LMDE | Linux Mint Debian Edition |
| Elementary OS | All current releases |
| SysLinuxOS | All releases |
| Other Debian-based derivatives | ZorinOS 18 |

---

## Features

- Auto-detection of distribution, version, and desktop environment
- Multilanguage interface: English, Italian, French, Spanish, German, Portuguese -- auto-detected from system locale
- Graphical interface via YAD (advanced) with Zenity and terminal fallback
- Real-time build log window showing all 30 build steps
- Calamares installer with dynamic branding per distribution
- UEFI and Legacy BIOS dual boot (GRUB + isolinux)
- Squashfs compression: standard xz, fast lz4, maximum xz+bcj
- User configuration cloning to `/etc/skel`
- Optional manual chroot pause for custom modifications before squashfs
- Automatic cleanup of live packages after installation
- Splash screen and completion/error dialogs
- Snap directory exclusion for Ubuntu-based systems

---

## Requirements

- A running Debian-based system
- Root privileges
- Minimum 4-6 GB free disk space in `/mnt`
- Minimum 2 GB RAM
- Estimated build time: 10-30 minutes depending on system size and compression method

---

## Installation

### From .deb package (recommended)

```bash
sudo apt install -y yad
sudo apt install -y ./distroClone_1.3.6_all.deb # recommended
sudo dpkg -i distroClone_1.3.6_all.deb  
sudo apt install -f
```

The package installs:

| Path | Description |
|---|---|
| `/usr/bin/distroClone` | Launcher script with multilanguage splash |
| `/usr/share/distroClone/` | Main script and branding resources |
| `/usr/share/applications/distroClone.desktop` | Desktop menu entry |
| `/usr/share/polkit-1/actions/` | PolicyKit policy for graphical auth |
| `/usr/share/icons/hicolor/` | DC icon at 48, 128, 256 px |

### From script (standalone)

```bash
chmod +x DistroClone.sh
sudo ./DistroClone.sh
```

The script will install required packages automatically on first run.

---

## Usage

### From desktop menu

Launch **DistroClone** from the System category. Authentication will be requested via PolicyKit.

### From terminal

```bash
sudo apt install -y yad
sudo distroClone
```

Or directly:

```bash
sudo ./DistroClone.sh
```

### Language selection

The interface language is detected automatically from the system locale. To override:

```bash
sudo distroClone --lang=fr
```

Or via environment variable:

```bash
DISTROCLONE_LANG=de sudo distroClone
```

Supported language codes: `en`, `it`, `fr`, `es`, `de`, `pt`.

### Build process

1. Splash screen appears while the system initializes.
2. Welcome dialog shows detected system info and build options: compression type, root password, hostname.
3. User configuration dialog asks whether to clone current desktop settings to the live system.
4. The build proceeds through 30 steps visible in the Build Log window: system cloning, chroot configuration, package installation, Calamares setup, squashfs compression, GRUB/isolinux configuration, ISO creation.
5. Optional pause before squashfs for manual chroot modifications.
6. Final dialog reports success with ISO path and size, or error details.

### Output

The ISO is created in `/mnt/<distro>_live/` with the naming convention:

```
<Distro>-<Version>-<Desktop>.iso
```

Examples: `Ubuntu-24.04-Gnome.iso`, `SysLinuxOS-12-Mate.iso`

MD5 and SHA256 checksums are generated alongside the ISO.

### Testing the ISO

With VirtualBox:

```
Create a new VM and mount the ISO file.
```

With a USB drive:

```bash
sudo dd if=/mnt/<distro>_live/<n>.iso of=/dev/sdX bs=4M status=progress
```

---

## Dependencies

### Required (installed by .deb or script)

- `bash`
- `rsync`
- `xorriso`
- `mtools`
- `syslinux-utils`, `syslinux-common`
- `isolinux`
- `imagemagick`
- `grub-pc-bin`

### Recommended (installed automatically during build)

- `yad`
- `zenity`
- `calamares`, `calamares-settings-debian`
- `live-boot`, `live-config`, `live-config-systemd`
- `grub-efi-amd64`, `efibootmgr`
- `os-prober`
- `fdisk`

---

## Desktop Environment Support

DistroClone detects the running desktop environment and applies specific handling where needed:

| Desktop | Notes |
|---|---|
| GNOME | Desktop icon trust mechanism for Calamares launcher, Wayland/X11 wrapper for slideshow compatibility |
| Pantheon (Elementary OS) | pkexec DISPLAY passthrough, Calamares wrapper exclusion |
| Cinnamon, MATE, KDE, XFCE | Standard handling, no special workarounds required |

---

## File Structure

```
DistroClone.sh            Main build script (multilanguage)
distroClone               Launcher script (multilanguage splash)
distroClone-logo.png      Calamares branding logo (optional, auto-generated)
distroClone-welcome.png   Calamares welcome image (optional)
distroClone-grub.png      GRUB background image (optional)
slide*.png                Calamares slideshow images (optional)
```

Optional image files are placed alongside the script. If absent, the script generates placeholder graphics via ImageMagick.

---

## How It Works

1. Clones the running system via `rsync` with exclusion of virtual filesystems, temporary files, caches, snap directories, and user-specific data.
2. Sets up a chroot environment and installs `live-boot`, Calamares, and boot components.
3. Configures Calamares branding, partition layout (ext4 default with EFI), display manager detection, and a post-install systemd service that removes live packages and build tools from the installed system.
4. Creates the squashfs filesystem with the selected compression.
5. Builds GRUB (EFI) and isolinux (BIOS) boot configurations with translated menu entries.
6. Generates the final ISO with `xorriso`, bootable on both UEFI and Legacy BIOS systems.
7. Cleans up: removes Calamares, live-boot, and build dependencies from the host system.

---

## License

This project is licensed under the **GPL-3.0-or-later** license.  
See the [LICENSE](LICENSE) file for details.

---

## Author

**Franco Conidi** (aka edmond)  
fconidi@gmail.com

- [syslinuxos.com](https://syslinuxos.com)
- [francoconidi.it](https://francoconidi.it)
- [github.com/fconidi](https://github.com/fconidi)
