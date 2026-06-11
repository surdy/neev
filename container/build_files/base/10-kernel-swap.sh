#!/usr/bin/env bash
# shellcheck disable=SC1083
#
# Swap the stock Fedora kernel for the Universal Blue MOK-signed kernel-cache
# build. Same kernel version, just re-signed so our signed ZFS/NVIDIA kmods load
# under Secure Boot. RPMs are bind-mounted from akmods-zfs at /tmp/kernel-rpms.

set ${CI:+-x} -euo pipefail

find /tmp/kernel-rpms

pushd /tmp/kernel-rpms
CACHED_VERSION=$(find "$KERNEL_NAME"-*.rpm | grep -P "$KERNEL_NAME-\d+\.\d+\.\d+-\d+$(rpm -E %{dist})" | sed -E "s/$KERNEL_NAME-//;s/\.rpm//")
popd
echo "cached kernel version: ${CACHED_VERSION}"

# remove the distro kernel; the cache provides the signed replacement
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
  rpm --erase "$pkg" --nodeps || true
done

dnf -y install \
  /tmp/kernel-rpms/"$KERNEL_NAME"-"$CACHED_VERSION".rpm \
  /tmp/kernel-rpms/"$KERNEL_NAME"-core-"$CACHED_VERSION".rpm \
  /tmp/kernel-rpms/"$KERNEL_NAME"-modules-"$CACHED_VERSION".rpm \
  /tmp/kernel-rpms/"$KERNEL_NAME"-modules-core-"$CACHED_VERSION".rpm \
  /tmp/kernel-rpms/"$KERNEL_NAME"-modules-extra-"$CACHED_VERSION".rpm

# pin it so later transactions can't pull a differently-signed kernel
dnf versionlock add \
  "$KERNEL_NAME" \
  "$KERNEL_NAME"-core \
  "$KERNEL_NAME"-modules \
  "$KERNEL_NAME"-modules-core \
  "$KERNEL_NAME"-modules-extra
