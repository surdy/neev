#!/usr/bin/env bash
# shellcheck disable=SC2114
#
# Reset /tmp and /var to a clean state for a bootc image. Must run in a RUN step
# WITHOUT /var or /tmp mounts active (see Containerfile.in), otherwise rm trips
# over the mountpoints. The caller does `ostree container commit` afterwards.

set ${CI:+-x} -euo pipefail

rm -rf /tmp /var
mkdir -m 1777 /tmp
mkdir -m 1777 -p /var/tmp
