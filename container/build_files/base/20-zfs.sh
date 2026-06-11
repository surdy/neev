#!/usr/bin/env bash
#
# Install signed OpenZFS kmods + userspace from the akmods-zfs cache
# (bind-mounted at /tmp/akmods-zfs-rpms). ZFS is intentionally NOT added to the
# initramfs (no ZFS-on-root), matching uCore/Cayo.

set ${CI:+-x} -euo pipefail

KERNEL_VRA="$(rpm -q "$KERNEL_NAME" --queryformat '%{EVR}.%{ARCH}')"

dnf -y install \
    pv \
    /tmp/akmods-zfs-rpms/kmods/zfs/kmod-zfs-"${KERNEL_VRA}"-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libnvpair3-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libuutil3-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libzfs6-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/libzpool6-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/python3-pyzfs-*.rpm \
    /tmp/akmods-zfs-rpms/kmods/zfs/zfs-*.rpm

# depmod no longer runs automatically for zfs >= 2.2
depmod -a "${KERNEL_VRA}"
