# Synology AMDGPU Top 0.1.3

## English

This release keeps one x86_64 `amdgpu_top` SPK for supported DSM platforms and publishes a matching runtime bundle plus a per-file SHA-256 manifest for downstream packages.

- Removed the obsolete K4/K5 package-flavor branch that could suppress `/usr/bin/amdgpu_top` on K4. The package uses one PATH policy: register the command when an AMD DRM render node is present.
- Built the userspace executable and private libdrm libraries with the native x86_64 builder. No Synology kvmx64 cross-toolchain or kernel-specific binary is used.
- Existing downstream packages remain pinned to runtime v0.1.2; publishing v0.1.3 does not force their rebuild.

The preceding v0.1.2 SPK was verified on DSM 7.4.1 with Linux 5.10.55 and Linux 4.4.302 after GPU-module stabilization. The new v0.1.3 SPK has passed build and package-integrity checks, but has not yet been reinstalled on those NAS devices. An active AMD DRM driver is required.

SPK SHA-256: `0ea12d2e6b1dd0108739f05607ab575a4b183815ecaeaec939db1990d3c8f9ee`  
Runtime archive SHA-256: `42a0b89484903f09280aba96f438801831003a0348cdb6d657e9c327a8e7eee4`

## 한국어

지원되는 DSM 플랫폼에서 사용할 단일 x86_64 `amdgpu_top` SPK와 파생 패키지용 런타임 번들·파일별 SHA-256 매니페스트를 제공합니다.

- K4에서 `/usr/bin/amdgpu_top` 등록을 막을 수 있었던 기존 K4/K5 분리 패키징 분기를 제거했습니다. AMD DRM 렌더 노드가 있으면 커널 버전과 관계없이 동일한 PATH 정책을 적용합니다.
- 네이티브 x86_64 빌더로 실행 파일과 전용 libdrm을 빌드했습니다. Synology kvmx64 교차 툴체인과 커널별 바이너리는 사용하지 않습니다.
- 기존 파생 패키지는 런타임 v0.1.2에 계속 고정되어 있으며, v0.1.3 배포만으로 재빌드할 필요는 없습니다.

이전 v0.1.2 SPK는 GPU 모듈 안정화 이후 DSM 7.4.1의 커널 5.10.55와 4.4.302에서 검증했습니다. 새 v0.1.3 SPK는 빌드·패키지 무결성 검사를 통과했지만 해당 NAS에 재설치해 검증하지는 않았습니다. AMD DRM 드라이버가 활성화되어 있어야 합니다.
