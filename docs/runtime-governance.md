# amdgpu_top runtime governance

This document records the current binary audit and proposes how
`syno-amdgpu-top` should become the source of the `amdgpu_top` executable,
its private libdrm, and DSM kernel compatibility policy. A user-space ELF
has no kernel-module `vermagic`; kernel labels need build records and runtime
validation.

## Audited state (2026-09-25)

| Artifact | `amdgpu_top` SHA-256 | Status |
| --- | --- | --- |
| `syno-amdgpu-top` v0.1.1 K4 SPK | `ad9ef91a4bc5b765823309b3e02b672b3f7a549f015e3cbb3efe0b5128e979d3` | Published; build provenance and K4 stability need renewed validation |
| `syno-amdgpu-top` v0.1.1 K5 SPK/runtime bundle | `939cda71bc14e8425bd4adecea05821f5166ef28172cc552cfc84c62df668145` | Matches current kvmx64 build stage |
| `syno-amdgpu-driver` v0.5.2 K4 and K5 SPKs | `3f3844bc681cc7b51201a5ef45f1689aaf62bb9c16fba06ff0729c74b83b9cae` | Legacy duplicate; same ELF in both packages, matching the 2026-09-24 EPYC7002 pilot stage |

The v0.1.1 K4 and K5 top SPKs contain different ELFs. The current
`repackage-kernel-flavors.sh` creates both flavors from one input SPK without
recompilation, so it does not guarantee that distinct K4 and K5 payloads
are retained. Hash matching proves which bytes were packaged, not which
kernel is safe to run them on. A timeout cannot terminate a process blocked
in kernel `D` state.

## Consumer plan (not yet implemented)

| Repository | Intended source | Kernel 4 policy | Kernel 5 policy |
| --- | --- | --- | --- |
| `syno-amdgpu-driver` | No `amdgpu_top` payload; users install this package separately | No bundled top | No bundled top |
| `mshell-manager` | Pinned `syno-amdgpu-top` runtime bundle | Use direct DRM collector; do not invoke the embedded K5 top | Use pinned K5 bundle for console and JSON fallback |
| `syno-gpu-monitor` | Pinned release artifacts from this repository | Direct DRM collector; keep K4 top diagnostic-only until validated | Use pinned K5 bundle for console and VRAM fallback |

The current `mshell-manager` build embeds only the K5 runtime and uses it
without a kernel gate. The current `syno-gpu-monitor` build embeds both
flavors and selects one by `uname -r`. The current `syno-amdgpu-driver`
source removes `amdgpu_top` through its refresh/repackage paths, while its
released v0.5.2 K4 and K5 packages still contain the legacy duplicate.

After K4 stability is resolved, each consumer should verify both its archive
SHA-256 and the extracted ELF SHA-256. A shared release manifest should
record source revision, toolchain image digest, kernel flavor, file digests,
and runtime policy. Consumers should select an exact supported kernel rather
than defaulting unknown kernels to the K5 binary. Until that manifest exists,
the consumers keep their current pinned v0.1.1 URLs.

## K4 release gate

1. Rebuild K4 from locked source and recorded toolchain; compare the new ELF
   with the published K4 hash or document and review the difference.
2. Check `--json -n 1` and interactive startup on a K4 test NAS with one
   collector process, then verify that exit leaves no `D`-state process,
   kernel fault, or reboot hang.
3. If K4 hangs or faults, isolate whether the trigger is this ELF, its
   private libdrm, the kernel DRM ioctl, or a consumer's repeated polling.
   Do not enable automatic K4 polling or console integration before a stable
   result is demonstrated.
4. Once validated, publish two runtime archives and a release manifest with
   per-flavor hashes. Update the three consumers to pin that release in one
   coordinated change; rebuild and validate each resulting SPK before release.

Do not overwrite existing v0.1.1 assets while their build provenance is being
audited. New binaries require a new, explicitly chosen package version.
