#!/usr/bin/env bash
#
# NVIDIA open kmods + container toolkit, from the akmods-nvidia-open cache
# (bind-mounted at /tmp/akmods-nv-rpms). Only built into the -nvidia-open
# variants (gated by #ifdef NVIDIA in the Containerfile). NVIDIA is hot-loaded,
# not added to the initramfs.
#
# Adapted from uCore's install-ucore-minimal-nvidia.sh (the proven Fedora path).
# NOTE: this differs from Cayo's nvidia script, which enables the CentOS-only
# "epel-nvidia" repo; on Fedora the addons package ships the negativo17
# "fedora-nvidia" repo instead.

set ${CI:+-x} -euo pipefail

NV_RPMS=/tmp/akmods-nv-rpms

# Mitigate upstream packaging bug rhbz#2332429: nvidia-driver-cuda can pull in
# OpenCL-ICD-Loader instead of the expected ocl-icd. Make sure ocl-icd provides
# libOpenCL ahead of time (swap if the other loader is already present).
if rpm -q OpenCL-ICD-Loader >/dev/null 2>&1; then
    dnf -y swap --repo=fedora OpenCL-ICD-Loader ocl-icd
else
    dnf -y install --repo=fedora ocl-icd
fi

# ublue-os-nvidia-addons drops the (disabled) fedora-nvidia + nvidia-container-toolkit
# repos and the CDI/SELinux bits.
dnf -y install "${NV_RPMS}"/ublue-os/ublue-os-nvidia-addons-*.rpm

# We only ship the open driver, so the repo is always fedora-nvidia (never -lts).
dnf5 config-manager setopt fedora-nvidia.enabled=1 nvidia-container-toolkit.enabled=1

# kmod-nvidia-open built against our exact kernel, straight from the cache.
dnf -y install --setopt=install_weak_deps=False \
    "${NV_RPMS}"/kmods/kmod-nvidia*.rpm

# Hack until nvidia-container-toolkit's repo signing and dnf5 play nice
# (see https://github.com/NVIDIA/nvidia-container-toolkit/issues/1307).
echo "%_pkgverify_level none" >/etc/rpm/macros.verify
dnf -y install --setopt=install_weak_deps=False \
    nvidia-container-toolkit
rm /etc/rpm/macros.verify

dnf -y install --setopt=install_weak_deps=False \
    nvidia-driver-cuda

dnf5 config-manager setopt fedora-nvidia.enabled=0 nvidia-container-toolkit.enabled=0

semodule --verbose --install /usr/share/selinux/packages/nvidia-container.pp

systemctl enable ublue-nvctk-cdi.service
