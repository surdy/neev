#!/usr/bin/env bash
#
# Regenerate the initramfs for the swapped kernel, prune stale kernels, and drop
# the build-time versionlocks. /boot is emptied: bootc populates it at install.

set ${CI:+-x} -euo pipefail

KERNEL_VERSION="$(rpm -q --queryformat='%{EVR}.%{ARCH}' "$KERNEL_NAME"-core)"

export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v \
  --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

# keep only the modules for the kernel we ship
mapfile -t kernel_dirs < <(ls -1 /usr/lib/modules)
if (( ${#kernel_dirs[@]} > 1 )); then
  for d in "${kernel_dirs[@]}"; do
    [ "$d" = "$KERNEL_VERSION" ] && continue
    echo "removing stale modules: $d"
    rm -rf "/usr/lib/modules/${d}"
  done
fi

# versionlocks were only needed during the build
dnf versionlock clear || true
