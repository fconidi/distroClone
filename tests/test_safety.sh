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
printf '%s\n' "${FAKE_MOUNTS:-}"
EOF
chmod +x "$work/bin/findmnt"
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
distroclone_clone_excludes
rsync -a "${CLONE_EXCLUDES[@]}" "$work/source/" "$work/clone/"
test -f "$work/clone/etc/hostname"
for path in etc/machine-id etc/ssh/ssh_host_ed25519_key etc/wireguard/wg0.conf etc/ssl/private/server.key etc/apt/auth.conf var/lib/systemd/random-seed; do
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
printf 'regenerated\n' > "$work/clone/etc/machine-id"
printf 'regenerated\n' > "$work/clone/var/lib/dbus/machine-id"
printf 'regenerated\n' > "$work/clone/var/lib/systemd/random-seed"
distroclone_prepare_identity "$work/clone"
test ! -e "$work/clone/etc/ssh/ssh_host_ed25519_key"
test ! -s "$work/clone/etc/machine-id"
test ! -e "$work/clone/var/lib/dbus/machine-id"
test ! -e "$work/clone/var/lib/systemd/random-seed"

echo 'Safety tests passed'
