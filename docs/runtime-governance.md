# amdgpu_top runtime governance

## Current source of truth (v0.1.2)

[`syno-amdgpu-top` v0.1.2](https://github.com/PeterSuh-Q3/syno-amdgpu-top/releases/tag/v0.1.2)
publishes one native x86_64 `amdgpu_top` runtime bundle and a per-file SHA-256
manifest. The executable and its private libdrm libraries are built once;
there are no separate K4/K5 binaries or Synology kvmx64 cross-compiler inputs.
The standalone SPK is `syno-amdgpu-top-0.1.2-x86_64.spk` and declares DSM 7.2
as its minimum version.

The v0.1.2 release reports installation, AMD render-node detection, PATH
registration, and operation verified on DSM 7.4.1 with both Linux 5.10.55 and
Linux 4.4.302 after the GPU module stabilization work. These are tested
configurations, not a guarantee for every DRM backport or GPU. `amdgpu_top` is
a user-space ELF and has no kernel-module
`vermagic`; runtime compatibility depends on the installed AMD DRM driver and
its ioctl/sysfs behavior.

| Consumer | Current integration |
| --- | --- |
| `syno-amdgpu-driver` | No bundled `amdgpu_top`; directs users to the standalone SPK. |
| `mshell-manager` | Pins the v0.1.2 runtime archive and installs its files privately for the AMD console. |
| `syno-gpu-monitor` AMD 0.4.4 | Pins the v0.1.2 runtime archive; verifies archive and manifest file hashes during packaging. |

The shared archive is
`syno-amdgpu-top-runtime-0.1.2-x86_64.tar.gz` (SHA-256
`e784dad38728591906532760bcdedd3a536f03aad80b5650c2cd206cdd482a7f`).
Consumers should pin an exact release URL and archive checksum, verify the
manifest's individual file hashes, and keep the private libraries with the
executable. A consumer's telemetry permissions and polling policy remain its
own responsibility.

## Historical audit (v0.1.1 and earlier)

The 2026-09-25 audit found different ELF hashes in the v0.1.1 K4 and K5 SPKs,
and a duplicate `amdgpu_top` in older `syno-amdgpu-driver` packages. Those
findings explain why the single-source runtime was introduced; they do not
describe the current v0.1.2 release or its migrated consumers. Preserve old
release assets for reproducibility rather than replacing their bytes in place.

For future runtime changes, publish a new version with a build record, source
revision, archive hash, per-file manifest, and real-device validation. Update
each consumer's pinned URL and hash, rebuild its SPK, and verify packaged
bytes against the central manifest before release.
