#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${TEST_TMP_ROOT:?Set TEST_TMP_ROOT to a local temporary directory}"
work="$(mktemp -d "$TEST_TMP_ROOT/distroclone-test.XXXXXX")"
cleanup() {
    local size
    size="$(du -sb -- "$work" | cut -f1)"
    printf 'Removing test directory %s (%s bytes)\n' "$work" "$size"
    rm -rf -- "$work"
}
trap cleanup EXIT

# The production code uses findmnt; a stub lets us test the guard without mounts.
mkdir -p "$work/bin"
cat > "$work/bin/findmnt" <<'EOF'
#!/usr/bin/env bash
if [ -n "${FAKE_MOUNTS_FILE:-}" ]; then cat "$FAKE_MOUNTS_FILE"; else printf '%s\n' "${FAKE_MOUNTS:-}"; fi
EOF
cat > "$work/bin/umount" <<'EOF'
#!/usr/bin/env bash
[ -n "${FAKE_MOUNTS_FILE:-}" ] || exit 1
target="${@: -1}"
printf '%s\n' "$target" >> "$FAKE_MOUNTS_FILE.log"
grep -vxF -- "$target" "$FAKE_MOUNTS_FILE" > "$FAKE_MOUNTS_FILE.new" || true
mv "$FAKE_MOUNTS_FILE.new" "$FAKE_MOUNTS_FILE"
EOF
chmod +x "$work/bin/findmnt" "$work/bin/umount"
export PATH="$work/bin:$PATH"

source "$repo_root/usr/share/distroClone/distroclone-safety.sh"

mkdir -p "$work/mount-base/debian_live/rootfs"
printf 'keep\n' > "$work/mount-base/debian_live/rootfs/data"
FAKE_MOUNTS="$work/mount-base/debian_live/rootfs"
export FAKE_MOUNTS
if distroclone_reset_workdir "$work/mount-base/debian_live" "$work/mount-base"; then
    echo 'Mounted workdir was removed' >&2
    exit 1
fi
test -f "$work/mount-base/debian_live/rootfs/data"
FAKE_MOUNTS=''
export FAKE_MOUNTS
distroclone_reset_workdir "$work/mount-base/debian_live" "$work/mount-base"
test -d "$work/mount-base/debian_live"
test ! -e "$work/mount-base/debian_live/rootfs/data"

# leftover bind mounts are detached, deepest first, then the dir is reset
mkdir -p "$work/mount-base/stale_live/rootfs/dev/pts"
printf 'x\n' > "$work/mount-base/stale_live/rootfs/f"
printf '%s\n' "$work/mount-base/stale_live/rootfs/dev" \
    "$work/mount-base/stale_live/rootfs/dev/pts" > "$work/fake-mounts"
FAKE_MOUNTS_FILE="$work/fake-mounts"
export FAKE_MOUNTS_FILE
distroclone_reset_workdir "$work/mount-base/stale_live" "$work/mount-base"
test ! -e "$work/mount-base/stale_live/rootfs/f"
test "$(head -1 "$work/fake-mounts.log")" = "$work/mount-base/stale_live/rootfs/dev/pts"
unset FAKE_MOUNTS_FILE

# os-release ID may be mixed case (SysLinuxOS)
mkdir -p "$work/mount-base/SysLinuxOS_live/rootfs"
distroclone_reset_workdir "$work/mount-base/SysLinuxOS_live" "$work/mount-base"
test -d "$work/mount-base/SysLinuxOS_live"

mkdir -p "$work/cache"
export TEST_MARKER="$work/executed"
cat > "$work/cache/.backup_meta" <<'EOF'
META_DATE="2026-11-07 12:00:00"
META_DISTRO="$(touch $TEST_MARKER)"
META_SIZE="1G"
EOF
distroclone_read_cache_meta "$work/cache/.backup_meta"
test "$META_DATE" = '2026-11-07 12:00:00'
test "$META_DISTRO" = '$(touch $TEST_MARKER)'
test "$META_SIZE" = '1G'
test ! -e "$TEST_MARKER"

mkdir -p "$work/source/etc/ssh" "$work/source/etc/wireguard" "$work/source/etc/ssl/private" "$work/source/etc/apt" "$work/source/var/lib/systemd"
printf 'machine\n' > "$work/source/etc/machine-id"
printf 'key\n' > "$work/source/etc/ssh/ssh_host_ed25519_key"
printf 'key\n' > "$work/source/etc/wireguard/wg0.conf"
printf 'key\n' > "$work/source/etc/ssl/private/server.key"
printf 'secret\n' > "$work/source/etc/apt/auth.conf"
printf 'seed\n' > "$work/source/var/lib/systemd/random-seed"
printf 'safe\n' > "$work/source/etc/hostname"
mkdir -p "$work/source/etc/initramfs-tools/hooks"
printf '#!/bin/sh\n' > "$work/source/etc/initramfs-tools/hooks/distromove-crypt"
printf '#!/bin/sh\n' > "$work/source/etc/initramfs-tools/hooks/copy-crypttab"
distroclone_clone_excludes
rsync -a "${CLONE_EXCLUDES[@]}" "$work/source/" "$work/clone/"
test -f "$work/clone/etc/hostname"
test -f "$work/clone/etc/initramfs-tools/hooks/copy-crypttab"
for path in etc/initramfs-tools/hooks/distromove-crypt etc/machine-id etc/ssh/ssh_host_ed25519_key etc/wireguard/wg0.conf etc/ssl/private/server.key etc/apt/auth.conf var/lib/systemd/random-seed; do
    test ! -e "$work/clone/$path" || { echo "Copied secret: $path" >&2; exit 1; }
done

mkdir -p "$work/user-config/gtk-3.0" "$work/user-config/cloud-client"
printf 'theme=dark\n' > "$work/user-config/gtk-3.0/settings.ini"
printf 'token\n' > "$work/user-config/cloud-client/credentials"
distroclone_copy_desktop_config "$work/user-config" "$work/skel-config"
test -f "$work/skel-config/gtk-3.0/settings.ini"
test ! -e "$work/skel-config/cloud-client/credentials"

mkdir -p "$work/clone/etc" "$work/clone/etc/systemd/system"
distroclone_prepare_identity "$work/clone"
test -f "$work/clone/etc/machine-id"
test ! -s "$work/clone/etc/machine-id"
test -f "$work/clone/etc/systemd/system/distroclone-ssh-host-keys.service"
test -L "$work/clone/etc/systemd/system/multi-user.target.wants/distroclone-ssh-host-keys.service"
mkdir -p "$work/clone/etc/ssh" "$work/clone/var/lib/dbus" "$work/clone/var/lib/systemd"
printf 'regenerated\n' > "$work/clone/etc/ssh/ssh_host_ed25519_key"
rm -f "$work/clone/etc/machine-id"
printf 'regenerated\n' > "$work/clone/etc/machine-id"
printf 'regenerated\n' > "$work/clone/var/lib/dbus/machine-id"
printf 'regenerated\n' > "$work/clone/var/lib/systemd/random-seed"
distroclone_prepare_identity "$work/clone"
test ! -e "$work/clone/etc/ssh/ssh_host_ed25519_key"
test ! -s "$work/clone/etc/machine-id"
test ! -e "$work/clone/var/lib/dbus/machine-id"
test ! -e "$work/clone/var/lib/systemd/random-seed"

echo 'Safety tests passed'
