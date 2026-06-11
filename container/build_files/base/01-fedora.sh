#!/usr/bin/env bash
#
# Fedora-specific base bits.

set ${CI:+-x} -euo pipefail

# dnf5-plugins: copr/config-manager used by package install-scripts.
# rsync: used by build.sh to overlay each package's files/ tree onto /.
dnf -y --setopt=install_weak_deps=False install dnf5-plugins rsync

# sysusers shim for libutempter (drop once libutempter ships the user itself)
cat >/usr/lib/sysusers.d/neev-utempter.conf <<'EOF'
g utempter 35
EOF
