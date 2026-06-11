set unstable := true

# --- pinned upstreams (keep in sync with images.yaml + CI) ---
fedora_version := "44"
akmods_flavor := "coreos-stable"
registry := "ghcr.io"
org := "surdy"

source_image := "quay.io/fedora/fedora-bootc:" + fedora_version
akmods_zfs := "ghcr.io/ublue-os/akmods-zfs:" + akmods_flavor + "-" + fedora_version
akmods_nvidia := "ghcr.io/ublue-os/akmods-nvidia-open:" + akmods_flavor + "-" + fedora_version

container := "podman"
builddir := "build"

_default:
    @just --list

# Map a tier to its build target and published image base-name.
_target tier:
    #!/usr/bin/env bash
    case "{{ tier }}" in
      minimal)  echo "neev-minimal neev-minimal" ;;
      standard) echo "neev neev" ;;
      hci)      echo "neev-hci neev-hci" ;;
      *) echo "unknown tier '{{ tier }}'" >&2; exit 1 ;;
    esac

# Render container/Containerfile from Containerfile.in (variant: "" or "nvidia-open").
[group('build')]
containerfile variant="":
    #!/usr/bin/env bash
    set -euo pipefail
    flags=(-E -P -traditional-cpp)
    [[ "{{ variant }}" == "nvidia-open" ]] && flags+=(-DNVIDIA)
    [[ -n "${CI:-}" ]] && flags+=(-DCI_SETX)
    cpp "${flags[@]}" container/Containerfile.in > container/Containerfile
    echo ":: wrote container/Containerfile (variant='{{ variant }}')"

# Build a tier image. tier: minimal|standard|hci  variant: ""|nvidia-open
[group('build')]
build tier="standard" variant="": (containerfile variant)
    #!/usr/bin/env bash
    set -euo pipefail
    read -r target name < <(just _target "{{ tier }}")
    suffix=""; [[ -n "{{ variant }}" ]] && suffix="-{{ variant }}"
    image="{{ registry }}/{{ org }}/${name}${suffix}"
    timestamp="$(date +%Y%m%d)"
    mkdir -p "{{ builddir }}"

    args=(
      --file container/Containerfile
      --target "$target"
      --build-arg "SOURCE_IMAGE={{ source_image }}"
      --build-arg "AKMODS_ZFS={{ akmods_zfs }}"
      --build-arg "IMAGE_VERSION={{ fedora_version }}"
      --build-arg "KERNEL_NAME=kernel"
      --security-opt label=disable
      --cap-add all
      --device /dev/fuse
      --tag "${image}:latest"
      --tag "${image}:{{ fedora_version }}"
      --tag "${image}:{{ fedora_version }}.${timestamp}"
    )
    [[ -n "{{ variant }}" ]] && args+=(--build-arg "AKMODS_NVIDIA={{ akmods_nvidia }}")

    {{ container }} pull --retry 3 "{{ akmods_zfs }}"
    [[ -n "{{ variant }}" ]] && {{ container }} pull --retry 3 "{{ akmods_nvidia }}"
    {{ container }} pull --retry 3 "{{ source_image }}"
    {{ container }} build "${args[@]}" .
    echo "$image" > "{{ builddir }}/.last-image"

# Push every tag of a built tier image and cosign-sign it by digest.
# Requires COSIGN_PRIVATE_KEY + COSIGN_PASSWORD in the environment for signing.
[group('registry')]
push tier="standard" variant="":
    #!/usr/bin/env bash
    set -euo pipefail
    read -r _ name < <(just _target "{{ tier }}")
    suffix=""; [[ -n "{{ variant }}" ]] && suffix="-{{ variant }}"
    image="{{ registry }}/{{ org }}/${name}${suffix}"

    mapfile -t tags < <({{ container }} image list "${image}" --noheading --format '{{{{ .Tag }}')
    digestfile="$(mktemp)"
    for tag in "${tags[@]}"; do
      for i in 1 2 3 4 5; do
        {{ container }} push --digestfile="$digestfile" "${image}:${tag}" "docker://${image}:${tag}" && break || sleep $((5 * i))
        [[ $i -eq 5 ]] && exit 1
      done
    done

    if [[ -n "${COSIGN_PRIVATE_KEY:-}" ]]; then
      digest="$(cat "$digestfile")"
      cosign sign --yes --key env://COSIGN_PRIVATE_KEY "${image}@${digest}"
    fi

[group('registry')]
login:
    echo "${REGISTRY_TOKEN:?set REGISTRY_TOKEN}" | {{ container }} login {{ registry }} -u "${REGISTRY_USER:-{{ org }}}" --password-stdin

# Standalone shellcheck (bootc container lint already runs inside the build).
[group('check')]
check:
    shellcheck container/build_files/build.sh container/build_files/*.sh \
        container/build_files/base/*.sh packages/*/install-scripts/*

# Build an installer ISO for a built tier image via bootc-image-builder.
[group('disk')]
build-iso tier="standard" variant="":
    #!/usr/bin/env bash
    set -euo pipefail
    read -r _ name < <(just _target "{{ tier }}")
    suffix=""; [[ -n "{{ variant }}" ]] && suffix="-{{ variant }}"
    img="{{ registry }}/{{ org }}/${name}${suffix}:latest"
    mkdir -p "{{ builddir }}/iso"
    {{ container }} run --rm --privileged \
      --security-opt label=type:unconfined_t \
      -v "$(pwd)/{{ builddir }}/iso:/output" \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      -v "$(pwd)/BIB/iso.toml:/config.toml:ro" \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type iso --use-librepo=True "$img"

[group('build')]
clean:
    rm -rf {{ builddir }} container/Containerfile
