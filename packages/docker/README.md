# docker (optional)

Not listed in any tier manifest. To include Docker CE in a build, add `docker`
to the relevant file in `manifests/`. The docker socket ships **disabled**;
enable it with `sudo systemctl enable --now docker.socket`.

Podman is the default container engine on Neev; only add Docker if you have a
hard dependency on it.
