#!/usr/bin/env bash

# The work directory may contain bind mounts after an interrupted build.
distroclone_reset_workdir() {
    local workdir="$1" base="${2:-/mnt}" name mounts mount_path
    base="$(realpath -e -- "$base")" || return 1
    [[ "$workdir" == "$base/"* && ! -L "$workdir" ]] || return 1
    [[ "$(realpath -m -- "$workdir")" == "$workdir" ]] || return 1
    name="${workdir#"$base"/}"
    [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*_live$ ]] || {
        printf 'Invalid work directory name: %s\n' "$workdir" >&2
        return 1
    }
    # Detach leftover bind mounts of an interrupted build, deepest first.
    mounts="$(findmnt -rn -o TARGET --raw)" || return 1
    while IFS= read -r mount_path; do
        case "$mount_path" in
            "$workdir"/*) printf '%s\n' "$mount_path" ;;
        esac
    done <<< "$mounts" | awk '{ print length($0) "\t" $0 }' | sort -rn \
        | cut -f2- | while IFS= read -r mount_path; do
            umount -l -- "$mount_path" 2>/dev/null || true
        done
    # Never remove anything while a mount is still present.
    mounts="$(findmnt -rn -o TARGET --raw)" || return 1
    while IFS= read -r mount_path; do
        case "$mount_path" in
            "$workdir"|"$workdir"/*)
                printf 'Refusing to remove mounted work directory: %s\n' "$mount_path" >&2
                return 1
                ;;
        esac
    done <<< "$mounts"
    rm -rf -- "$workdir" || return 1
    mkdir -p -- "$workdir"
}

# Backup metadata is display data, never shell code.
distroclone_read_cache_meta() {
    local file="$1" line key value
    META_DATE='' META_DISTRO='' META_SIZE=''
    [[ -f "$file" && $(stat -c %s -- "$file") -le 4096 ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        key="${line%%=*}"
        value="${line#*=}"
        case "$key" in META_DATE|META_DISTRO|META_SIZE) ;; *) continue ;; esac
        if [[ "$value" == \"*\" ]]; then
            value="${value:1:${#value}-2}"
        fi
        [[ ${#value} -le 256 ]] || return 1
        printf -v "$key" '%s' "$value"
    done < "$file"
}

distroclone_clone_excludes() {
    CLONE_EXCLUDES=(
        --exclude='/dev/*' --exclude='/proc/*' --exclude='/sys/*'
        --exclude='/run/*' --exclude='/tmp/*' --exclude='/mnt/*'
        --exclude='/media/*' --exclude='/lost+found' --exclude='/swapfile'
        --exclude='/home/*' --exclude='/root/*'
        --exclude='/var/cache/apt/archives/*' --exclude='/var/lib/apt/lists/*'
        --exclude='/var/log/*' --exclude='/var/tmp/*'
        --exclude='/snap' --exclude='/snap/*' --exclude='/var/snap'
        --exclude='/var/lib/snapd' --exclude='/.snapshots'
        --exclude='/.snapshots/*' --exclude='/@.rollback-bak-*'
        --exclude='/etc/machine-id' --exclude='/var/lib/dbus/machine-id'
        --exclude='/var/lib/systemd/random-seed'
        --exclude='/etc/ssh/ssh_host_*' --exclude='/etc/wireguard'
        --exclude='/etc/openvpn' --exclude='/etc/ssl/private'
        --exclude='/etc/letsencrypt' --exclude='/etc/crypttab'
        --exclude='/var/lib/tailscale' --exclude='/var/lib/samba/private'
        --exclude='/etc/samba/private'
        --exclude='/etc/apt/auth.conf' --exclude='/etc/apt/auth.conf.d'
        --exclude='/etc/NetworkManager/system-connections/*'
        --exclude='/var/lib/NetworkManager/*'
        --exclude='/etc/wpa_supplicant/wpa_supplicant.conf'
        --exclude='/etc/initramfs-tools/hooks/distromove-crypt'
        --exclude='/etc/netplan/*.yaml'
    )
}

distroclone_prepare_identity() {
    local dest="$1" unit_dir parent
    [[ -d "$dest/etc" && ! -L "$dest/etc" ]] || return 1
    [[ "$(realpath -e -- "$dest")" == "$dest" ]] || return 1
    unit_dir="$dest/etc/systemd/system"
    for parent in "$dest/etc/ssh" "$dest/var/lib/dbus" \
                  "$dest/var/lib/systemd" "$dest/etc/systemd" "$unit_dir" \
                  "$unit_dir/multi-user.target.wants"; do
        if [[ -e "$parent" || -L "$parent" ]]; then
            [[ "$(realpath -m -- "$parent")" == "$parent" ]] || return 1
        fi
    done
    rm -f -- "$dest/etc/ssh"/ssh_host_* || return 1
    rm -f -- "$dest/var/lib/dbus/machine-id" || return 1
    rm -f -- "$dest/var/lib/systemd/random-seed" || return 1
    rm -f -- "$dest/etc/machine-id" || return 1
    install -m 0444 /dev/null "$dest/etc/machine-id" || return 1
    mkdir -p "$unit_dir/multi-user.target.wants" || return 1
    cat > "$unit_dir/distroclone-ssh-host-keys.service" <<'EOF'
[Unit]
Description=Generate SSH host keys for cloned system
Before=ssh.service sshd.service
ConditionPathExists=/usr/bin/ssh-keygen

[Service]
Type=oneshot
ExecStart=/usr/bin/ssh-keygen -A

[Install]
WantedBy=multi-user.target
EOF
    ln -sfn ../distroclone-ssh-host-keys.service \
        "$unit_dir/multi-user.target.wants/distroclone-ssh-host-keys.service"
}
