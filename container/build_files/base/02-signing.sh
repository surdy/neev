#!/usr/bin/env bash
#
# Container image signature policy for Neev.
#
# Installs our cosign public key and configures /etc/containers so that images
# pulled from our own repos must be cosign-signed. This is what makes a signed
# `bootc switch ghcr.io/surdy/neev*` verify before deploying.
#
# NOTE: keep the repo list here in sync with the build matrix (tiers x variants).

set ${CI:+-x} -euo pipefail

CTX="${CTX:-/ctx}"

install -D -m 0644 "${CTX}/cosign.pub" /etc/pki/containers/neev.pub

mkdir -p /etc/containers
[ -f /etc/containers/policy.json ] && cp /etc/containers/policy.json /etc/containers/policy.json.orig

# default stays permissive so unrelated images keep working; only our repos
# require a valid signature made with /etc/pki/containers/neev.pub
cat >/etc/containers/policy.json <<'EOF'
{
    "default": [ { "type": "insecureAcceptAnything" } ],
    "transports": {
        "docker": {
            "ghcr.io/surdy/neev-minimal": [
                { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/neev.pub", "signedIdentity": { "type": "matchRepoDigestOrExact" } }
            ],
            "ghcr.io/surdy/neev-minimal-nvidia-open": [
                { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/neev.pub", "signedIdentity": { "type": "matchRepoDigestOrExact" } }
            ],
            "ghcr.io/surdy/neev": [
                { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/neev.pub", "signedIdentity": { "type": "matchRepoDigestOrExact" } }
            ],
            "ghcr.io/surdy/neev-nvidia-open": [
                { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/neev.pub", "signedIdentity": { "type": "matchRepoDigestOrExact" } }
            ],
            "ghcr.io/surdy/neev-hci": [
                { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/neev.pub", "signedIdentity": { "type": "matchRepoDigestOrExact" } }
            ],
            "ghcr.io/surdy/neev-hci-nvidia-open": [
                { "type": "sigstoreSigned", "keyPath": "/etc/pki/containers/neev.pub", "signedIdentity": { "type": "matchRepoDigestOrExact" } }
            ]
        },
        "docker-daemon": { "": [ { "type": "insecureAcceptAnything" } ] }
    }
}
EOF

mkdir -p /etc/containers/registries.d
cat >/etc/containers/registries.d/neev.yaml <<'EOF'
docker:
  ghcr.io/surdy/neev-minimal:
    use-sigstore-attachments: true
  ghcr.io/surdy/neev-minimal-nvidia-open:
    use-sigstore-attachments: true
  ghcr.io/surdy/neev:
    use-sigstore-attachments: true
  ghcr.io/surdy/neev-nvidia-open:
    use-sigstore-attachments: true
  ghcr.io/surdy/neev-hci:
    use-sigstore-attachments: true
  ghcr.io/surdy/neev-hci-nvidia-open:
    use-sigstore-attachments: true
EOF
