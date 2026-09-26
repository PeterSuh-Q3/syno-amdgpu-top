# K4 DRM close-path probe

Build on a host with Docker Desktop or Docker Engine:

```sh
./scripts/build-k4-drm-probe.sh
```

The result is `dist/k4-drm-close-repro-x86_64`. It is compiled with the
Synology DSM 7.4 `kvmx64` GCC. The source is intentionally one-shot and prints
checkpoints to stderr so the last completed operation is visible.

On a **rebooted test NAS only**, run one stage at a time as root. Set
`LD_LIBRARY_PATH` to the package-private libdrm directory for stages 2 and 3.

1. `open-close`: open and close `/dev/dri/renderD128` without libdrm.
2. `init-close`: add `amdgpu_device_initialize` and deinitialize.
3. `query-close`: additionally query basic GPU information.

Do not advance after a kernel warning, a stuck `D`-state process, or an
unsuccessful reboot. `timeout` cannot release a process blocked inside the
kernel. This test does not change driver configuration or install a package.
