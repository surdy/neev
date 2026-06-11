#!/usr/bin/env bash
#
# NVIDIA open kmods + container toolkit, from the akmods-nvidia-open cache
# (bind-mounted at /tmp/akmods-nv-rpms). Only built into the -nvidia-open
# variants (gated by #ifdef NVIDIA in the Containerfile). NVIDIA is hot-loaded,
# not added to the initramfs.

set ${CI:+-x} -euo pipefail

dnf -y install /tmp/akmods-nv-rpms/ublue-os/ublue-os-nvidia-addons-*.rpm

dnf config-manager --set-enabled epel-nvidia
dnf config-manager --set-enabled nvidia-container-toolkit

KERNEL_VR="$(rpm -q "$KERNEL_NAME" --queryformat '%{VERSION}-%{RELEASE}')"
dnf -y install \
    nvidia-container-toolkit \
    nvidia-driver-cuda \
    /tmp/akmods-nv-rpms/kmods/kmod-nvidia*"${KERNEL_VR}"*.rpm

dnf config-manager --set-disabled epel-nvidia
dnf config-manager --set-disabled nvidia-container-toolkit

semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp
systemctl preset ublue-nvctk-cdi.service
