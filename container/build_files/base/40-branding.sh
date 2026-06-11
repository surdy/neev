#!/usr/bin/env bash
#
# OS branding (os-release) and the Universal Blue MOK certificate that signs the
# kernel and the ZFS/NVIDIA kmods. The cert must be enrolled at install time
# (the ISO kickstart does this) for Secure Boot systems.

set ${CI:+-x} -euo pipefail

# os-release identity
sed -i 's|^NAME=.*|NAME="Neev"|' /usr/lib/os-release
sed -i "s|^VERSION=.*|VERSION=\"${IMAGE_VERSION}\"|" /usr/lib/os-release
sed -i 's|^ID=.*|ID=neev|' /usr/lib/os-release
sed -i 's|^ID_LIKE=.*|ID_LIKE=fedora|' /usr/lib/os-release
sed -i 's|^HOME_URL=.*|HOME_URL="https://github.com/surdy/neev"|' /usr/lib/os-release
sed -i 's|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL="https://github.com/surdy/neev"|' /usr/lib/os-release
sed -i 's|^SUPPORT_URL=.*|SUPPORT_URL="https://github.com/surdy/neev/issues"|' /usr/lib/os-release
sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/surdy/neev/issues"|' /usr/lib/os-release

SOURCE_VERSION="$(grep ^VERSION_ID= /usr/lib/os-release | cut -f2 -d= | tr -d \")"
SOURCE_NAME="fedora-bootc"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Neev (Version ${IMAGE_VERSION} / FROM ${SOURCE_NAME} ${SOURCE_VERSION})\"|" /usr/lib/os-release

echo 'DEFAULT_HOSTNAME="neev"' >>/usr/lib/os-release
echo 'VARIANT="Neev"' >>/usr/lib/os-release
echo 'VARIANT_ID=neev' >>/usr/lib/os-release

# Universal Blue akmods signing certificate (kernel + zfs/nvidia kmods)
mkdir -p /etc/pki/akmods/certs
cat >/etc/pki/akmods/certs/akmods-ublue.pem <<'EOF'
-----BEGIN CERTIFICATE-----
MIIFtjCCA56gAwIBAgIUffh69d7nONn6wvijghk3S+ChgKcwDQYJKoZIhvcNAQEL
BQAwdTEXMBUGA1UECgwOVW5pdmVyc2FsIEJsdWUxFzAVBgNVBAsMDmtlcm5lbCBz
aWduaW5nMRUwEwYDVQQDDAx1Ymx1ZSBrZXJuZWwxKjAoBgkqhkiG9w0BCQEWG3Nl
Y3VyaXR5QHVuaXZlcnNhbC1ibHVlLm9yZzAgFw0yNDA3MTEwMzA3MDlaGA8yMTI0
MDYxNzAzMDcwOVowdTEXMBUGA1UECgwOVW5pdmVyc2FsIEJsdWUxFzAVBgNVBAsM
Dmtlcm5lbCBzaWduaW5nMRUwEwYDVQQDDAx1Ymx1ZSBrZXJuZWwxKjAoBgkqhkiG
9w0BCQEWG3NlY3VyaXR5QHVuaXZlcnNhbC1ibHVlLm9yZzCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBAJrjC/NmzXRnUWisoRu8vUKr8jq7QqlYWVSdT2jv
suA9qyQ/GKBg5A7kBV+XpKJCV1M7QkiUvQ7nn2pAYZAjWbRABBcoHlN1eFg7wTVP
1C+wV5mdsXO/fBs896GCRcI2Na+HJQ3o2m8PdCWGzgOYJCe9zHIwdbm6mPjgw56p
Ic50c7OHqU3qFsFZTXrJkq/cvyyr+Ue6j4JcJERm1IVMktRJ6nZ7NmmWjYTGSlBQ
l9YIT2DktSzihxM9f23R1RujdFmy6I6pMwSB3F4ehhFWlgvZa1/AGaXg7dE06RwT
8A5U+fb3iV/V66JaisiL8rISvmY7a5LMRMGRNlVF54JeF08N/w/ylOQb6cSE6H6U
g60hn2sbFy0S7rHQKXb8ZA5Y59na4EfLRnGGJQDWT+znsBTkJ730GvrbWzA1Hfzw
azeHQXSzyWf3h+d7tRM9DwjGz3RZ4YNQuttD3NcBBo/x8QZtOjbJGmPNg3k1OQ6m
0nSBCf7lbtD9KMoGfAf2hF0y+Pw43AARhJyhrzzIvhUYXtj/jPn+qQa7x+h/LBqd
RVXqYRTnDddqM8OW8/m2oNRWAAqfrCxfNZjD5x1/1trzuw4flLM4xMxEele8x0d1
rLoAfUIWU0FjWIJF1mCtrpXKNtfSpAyXylxzGTADGPAW+JrALu5/nVZGq8aBtQJO
Slp7AgMBAAGjPDA6MAwGA1UdEwEB/wQCMAAwCwYDVR0PBAQDAgeAMB0GA1UdDgQW
BBQsJQYVWLUCDEsNnKVgYuAMbNsEajANBgkqhkiG9w0BAQsFAAOCAgEAUp+arzHK
6qsFtCL++BSJCManvz9tb5IwiqQXyQgh2XmOcALh/JN63evdc2/ECdBBD9qO/0H+
a8u59A9C4EqghKFtTsb50vbMgJe/naAxuWU98oT9eqnAMnHJnr4FWY5rGP3hbxbt
51h5nUmcX5dpgOfFmu3bPpPYii9Ky/wN/KGAQBB7eOErbwRZHVFBtlKdN9Vz1UH0
LVa1LyPyz8F60Yfjz0waQxm7T0Idx74yCJbb1PX/1s71FHSOqSlFFycYsN5bBbS8
DPTThxjcQjMpRHR+hhW6vPVflphRExGtBY3FP/rOZbWS+LlEJlWmkBD8WPMbt71f
DSpf3R9St7NJu6KtuiCAbrGpkGmhKYQOVVNNO5Uz127UlC7Llt7KUh+ftfIVPGuF
yBAhV5jW2T+5FbT9fARITlD33TaAXgzALkchz1+koiYhxW3SPVdjbkzowae5V+D9
yp7kemY3yBT269D7BOwlPAzr2ncSbm6v54s59Wx60rOKq087FakK33YDPdd7guqw
m5lQWiEMWIS5MHsNDcqeaisz3KPe5KEaP2BEkBuVdZGBLwelO8SCJDoQH3ULK3mh
L0nu7LfehYBEdj0ZaBIO6V2ej+Cx1uR7Cf4PKlLja/IAymEj6a8OJMN6+0pfX3u8
DaO51gzKIn1Aumx5L76B64rp7LVWRpnwGPs=
-----END CERTIFICATE-----
EOF
openssl x509 -inform PEM -outform DER \
  -in /etc/pki/akmods/certs/akmods-ublue.pem \
  -out /etc/pki/akmods/certs/akmods-ublue.der
