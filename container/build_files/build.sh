#!/usr/bin/env bash
#
# Neev modular package installer.
#
#   Usage: build.sh <tier>      (tier = minimal | standard | hci)
#
# Honors the per-package layout (one self-contained folder per package):
#
#   packages/<name>/
#     rpm-ostree-pkgs      newline-delimited package names (optional; '#' comments ok)
#     files/               overlay tree rsync'd onto / (optional)
#     install-scripts/     numbered scripts run in lexical order (optional)
#
# manifests/<tier> lists which package folders belong to a tier (one name per line).
# For the given tier we: (1) batch every rpm-ostree-pkgs into a single dnf install,
# then (2) for each package, overlay files/ and run its install-scripts/.

set ${CI:+-x} -euo pipefail

TIER="${1:?usage: build.sh <tier>}"

export CTX="${CTX:-/ctx}"
PACKAGES_DIR="${CTX}/packages"
MANIFEST="${CTX}/manifests/${TIER}"

[ -f "$MANIFEST" ] || { echo "ERROR: no manifest for tier '${TIER}' (${MANIFEST})" >&2; exit 1; }

# Ordered package list for this tier (skip blank lines and # comments).
mapfile -t PACKAGES < <(sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$MANIFEST" | grep -v '^[[:space:]]*$')

echo ":: neev tier='${TIER}' packages: ${PACKAGES[*]:-(none)}"

# --- 1. batch all rpm-ostree-pkgs across this tier into one dnf transaction ---
pkglist=()
for p in "${PACKAGES[@]}"; do
    f="${PACKAGES_DIR}/${p}/rpm-ostree-pkgs"
    [ -f "$f" ] || continue
    while IFS= read -r line; do
        line="${line%%#*}"
        # shellcheck disable=SC2206
        for tok in $line; do pkglist+=("$tok"); done
    done < "$f"
done

if [ "${#pkglist[@]}" -gt 0 ]; then
    mapfile -t pkglist < <(printf '%s\n' "${pkglist[@]}" | sort -u)
    echo ":: dnf install (${#pkglist[@]}): ${pkglist[*]}"
    dnf -y install --setopt=install_weak_deps=False "${pkglist[@]}"
fi

# --- 2. per package: overlay files/ then run install-scripts/ in order ---
for p in "${PACKAGES[@]}"; do
    pdir="${PACKAGES_DIR}/${p}"
    [ -d "$pdir" ] || { echo "ERROR: missing package dir '${pdir}'" >&2; exit 1; }

    if [ -d "${pdir}/files" ]; then
        echo ":: [${p}] overlay files/ -> /"
        rsync -rlptK "${pdir}/files/" /
    fi

    sdir="${pdir}/install-scripts"
    if [ -d "$sdir" ]; then
        while IFS= read -r script; do
            echo ":: [${p}] run $(basename "$script")"
            bash "$script"
        done < <(find "$sdir" -maxdepth 1 -type f | sort)
    fi
done

echo ":: neev tier='${TIER}' done"
