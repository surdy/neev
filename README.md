# Neev

> **नींव** (_neev_) — Hindi for "foundation".

Neev is a [Universal Blue](https://universal-blue.org)-style **server**
operating system built as a [bootc](https://bootc-dev.github.io/bootc/) image.
It is intentionally "**uCore without CoreOS**": the same reusable Universal Blue
infrastructure (ublue-signed kernel, prebuilt ZFS and nvidia-open kmods), but
built on the plain **`quay.io/fedora/fedora-bootc`** base instead of Fedora
CoreOS — so there is no Ignition, no zincati, and no `coreos-installer` to deal
with. Just a normal, immutable, image-based Fedora server you update with
`bootc`.

> [!WARNING]
> Neev is early and experimental. Expect breaking changes. Do not run it on
> anything you cannot afford to reinstall.

## Why Neev exists

[uCore](https://github.com/ublue-os/ucore) is excellent, but its Fedora CoreOS
foundation brings deployment complexity (Ignition, Butane, zincati,
`coreos-installer`) that is overkill for a self-hoster who just wants an
immutable Fedora server with ZFS and Cockpit. Neev keeps everything that makes
uCore great and drops the CoreOS-specific machinery in favour of the standard
`bootc` install/update flow.

## Images

All images are published to `ghcr.io/surdy/`. There are three **tiers**, each
built on top of the previous one, and an optional **`-nvidia-open`** variant of
each that adds signed nvidia-open kmods.

| Tier       | Image                          | Builds on  | Adds |
|------------|--------------------------------|------------|------|
| `minimal`  | `ghcr.io/surdy/neev-minimal`   | fedora-bootc + ublue kernel + ZFS | Cockpit, Podman, Tailscale, server basics |
| `standard` | `ghcr.io/surdy/neev`           | `neev-minimal` | Samba, NFS, wifi/firmware, storage tools, monitoring, rclone, mergerfs, distrobox |
| `hci`      | `ghcr.io/surdy/neev-hci`       | `neev`     | Virtualization (libvirt, `cockpit-machines`, `virt-install`) |

NVIDIA variants: `neev-minimal-nvidia-open`, `neev-nvidia-open`,
`neev-hci-nvidia-open`.

Tags: `:latest`, `:44` (Fedora major), and `:44.YYYYMMDD` (pinned for rollback).

## Installation

### From an installer ISO

**Build in CI (recommended — no local Linux/podman needed).** Trigger the
[**Build Neev ISO**](../../actions/workflows/build-iso.yml) workflow
(Actions → *Build Neev ISO* → *Run workflow*), pick a `tier` and `variant`, and
download the resulting `*.iso` (plus its `.sha256` and cosign `.sig`) from the
run's **Artifacts**. Or from the CLI:

```bash
gh workflow run build-iso.yml -f tier=standard -f variant=base
gh run watch                         # then: gh run download <run-id>
```

**Build locally** (needs Linux with rootful/privileged podman):

```bash
just build-iso standard            # or: minimal | hci, optionally nvidia-open
```

Both paths use [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
with [`BIB/iso.toml`](BIB/iso.toml). The ISO runs a semi-interactive Anaconda
install (you create your user; disk is auto-partitioned as XFS). On Secure Boot
systems it enrolls Universal Blue's MOK so the signed kernel and kmods load —
confirm at first boot with the password **`universalblue`**.

Each CI artifact ships the `*.iso` alongside a `*.iso.sha256` checksum and a
cosign `*.iso.cosign.bundle`. Verify before flashing:

```bash
sha256sum -c neev-*.iso.sha256
cosign verify-blob --key cosign.pub --bundle neev-*.iso.cosign.bundle neev-*.iso
```

### Onto an existing bootc/Fedora Atomic host

```bash
sudo bootc switch ghcr.io/surdy/neev:latest
sudo systemctl reboot
```

### To a disk directly

```bash
sudo podman run --rm --privileged --pid=host \
  -v /var/lib/containers:/var/lib/containers \
  -v /dev:/dev \
  ghcr.io/surdy/neev:latest \
  bootc install to-disk /dev/sdX
```

## Updates

Neev updates itself via a staged `bootc` pull (no auto-reboot) on a timer.
Trigger manually with:

```bash
sudo bootc upgrade
sudo systemctl reboot
```

## Image verification

Images are signed with [cosign](https://github.com/sigstore/cosign). The public
key lives in this repo at [`cosign.pub`](cosign.pub) and is baked into every
image at `/etc/pki/containers/neev.pub`.

```bash
cosign verify --key cosign.pub ghcr.io/surdy/neev | jq
```

## Building locally

Requires `podman`, `just`, `cpp`, and (for signing) `cosign`. The easiest path
is the bundled dev container (`ghcr.io/ublue-os/devcontainer:latest`), which has
all of these.

```bash
just build standard               # build the standard tier (base variant)
just build hci nvidia-open        # build the HCI tier with nvidia-open
just check                        # shellcheck the build scripts
just build-iso standard           # produce an installer ISO
```

`just build` renders [`container/Containerfile`](container/Containerfile.in)
from the `.in` template with `cpp` (the only place the C preprocessor is used is
the optional `#ifdef NVIDIA` block), then builds the requested `--target`.

## Repository layout

```
container/
  Containerfile.in        cpp template: akmods stages -> neev-minimal -> neev -> neev-hci
  build_files/
    build.sh              tier-aware package installer (reads manifests/<tier>)
    github-release-install.sh
    base/                 ordered base assembly (kernel swap, ZFS, nvidia, branding, cleanup)
packages/<name>/          one self-contained folder per package:
    rpm-ostree-pkgs         newline-delimited package names (optional)
    files/                  overlay tree rsync'd onto / (optional)
    install-scripts/        numbered scripts run in order (optional)
manifests/<tier>          which package folders belong to each tier
BIB/iso.toml              bootc-image-builder installer config
images.yaml               pinned upstreams (docs / single source of truth)
```

### Adding or removing a package

Everything for a package lives in one folder under `packages/`, then you list
its folder name in the relevant `manifests/<tier>` file. To remove it, delete
the line (or the folder). See
[`packages/docker/`](packages/docker/) for an optional package that ships in the
tree but is not enabled in any tier.

## What is reused from Universal Blue

- **Kernel**: the stock Fedora kernel re-signed with Universal Blue's MOK,
  pulled from `ghcr.io/ublue-os/akmods-zfs:coreos-stable-44` (so ZFS and
  nvidia-open kmods verify under Secure Boot).
- **ZFS kmods**: prebuilt and signed, from the same `akmods-zfs` cache.
- **nvidia-open kmods**: from `ghcr.io/ublue-os/akmods-nvidia-open:coreos-stable-44`.
- **Dev container & build conventions**: adapted from
  [`ublue-os/cayo`](https://github.com/ublue-os/cayo).

## Acknowledgements

Neev stands on the shoulders of [Universal Blue](https://universal-blue.org),
[uCore](https://github.com/ublue-os/ucore), and
[Cayo](https://github.com/ublue-os/cayo). The per-package layout is inspired by
[`clusterfault/custom-ucore`](https://github.com/clusterfault/custom-ucore).

## License

[Apache-2.0](LICENSE).
