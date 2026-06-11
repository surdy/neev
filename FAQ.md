# Neev FAQ

### How is Neev different from uCore?

uCore is built on **Fedora CoreOS**, which brings Ignition, Butane, zincati, and
`coreos-installer` into the picture. Neev is built on the plain
**`quay.io/fedora/fedora-bootc`** base and uses the standard `bootc` install and
update flow instead. Functionally the OS is meant to feel like uCore (ublue
kernel, ZFS, Cockpit, the same kind of server package set), just without the
CoreOS machinery. See the research notes in this repo's parent project for a
deeper comparison.

### Why build on `fedora-bootc` instead of Fedora CoreOS?

For a self-hoster, CoreOS's first-boot provisioning model (Ignition) and its
separate updater (zincati) add complexity without much benefit. `bootc` on top
of a normal Fedora base gives a simpler mental model: it's just a container
image that happens to be the whole OS, installed and updated with one tool.

### Why is the kernel pulled from `akmods-zfs` instead of using the stock one?

The base image already contains a perfectly good Fedora kernel — the swap is
**not** about getting a *different* kernel. It's about getting the **same**
kernel **re-signed with Universal Blue's Machine Owner Key (MOK)**. That
matters because ZFS and nvidia-open are out-of-tree kernel modules; under Secure
Boot they will only load if they (and the kernel) are signed by a key the
firmware trusts. Reusing ublue's signed kernel + signed kmods means Secure Boot
works out of the box once you enroll the ublue MOK.

### Why the `coreos-stable` kernel flavor?

Universal Blue's `akmods-zfs` cache is only built for a few kernel flavors:
`coreos-stable`, `coreos-testing`, `longterm-6.18`, and `centos`. There is **no
`main` flavor with a ZFS cache**. `coreos-stable` is the flavor uCore itself
tracks, so Neev uses it to inherit the same well-tested, ZFS-ready kernel.

### Why only nvidia-open, not the proprietary driver?

Universal Blue does **not** build the proprietary `akmods-nvidia` package for any
Fedora flavor (only for CentOS). For Fedora, only `akmods-nvidia-open` exists.
Since Neev is Fedora-based, only the `-nvidia-open` variant is offered. For
Turing-and-newer GPUs the open kernel modules are the recommended path anyway.

### Do I need Secure Boot? What's the `universalblue` password?

You don't *need* Secure Boot — Neev runs fine with it off. If it's on, the
installer ISO enrolls Universal Blue's signing certificate via MOK so the signed
kernel and kmods load. At first boot the MOK manager asks you to confirm the
enrollment with the password **`universalblue`**.

### How do updates work without zincati?

A systemd timer (`bootc-fetch-apply-updates.timer`) periodically does a
**staged** `bootc` update — it downloads and prepares the new image but does
**not** reboot automatically. You reboot when convenient. To update on demand:

```bash
sudo bootc upgrade && sudo systemctl reboot
```

### Why XFS for the root filesystem, not ZFS or Btrfs?

The root filesystem is kept simple and boring (XFS, the Fedora server default).
ZFS is included for your **data** pools (the kmods and tools ship in the image),
not for the OS root. Keeping `/` on XFS avoids tying the bootloader/boot path to
ZFS.

### Can I add my own packages?

Yes — that's the point of the layout. Create `packages/<name>/` with any of
`rpm-ostree-pkgs`, `files/`, and `install-scripts/`, then add `<name>` to the
appropriate file in `manifests/`. Rebuild. To remove a package, delete its line
from the manifest (or delete the folder). See `packages/docker/` for a complete
example that ships in the tree but isn't enabled by default.

### What are the tiers and which should I use?

- **`neev-minimal`** — base server: Cockpit, Podman, Tailscale, ZFS, firewall.
  Good if you want a thin base to build on.
- **`neev`** (standard) — adds file sharing (Samba/NFS), storage tooling,
  monitoring, rclone/mergerfs, wifi/firmware. The default for most users.
- **`neev-hci`** — adds virtualization (libvirt, `cockpit-machines`). For
  hyper-converged hosts that also run VMs.

### How much of this is borrowed from Cayo?

The build mechanics (the `Containerfile.in` structure, the kernel-swap / ZFS /
nvidia scripts, `github-release-install.sh`, and the dev-container CI approach)
are adapted from [`ublue-os/cayo`](https://github.com/ublue-os/cayo), which is a
proven `fedora-bootc` build. The per-package folder convention is inspired by
[`clusterfault/custom-ucore`](https://github.com/clusterfault/custom-ucore).
