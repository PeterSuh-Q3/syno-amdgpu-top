# Synology AMDGPU Top 0.1.2

## English

`Synology AMDGPU Top 0.1.2` is a standalone, native x86_64 package for running the `amdgpu_top` command on supported Synology DSM systems.

- One generic SPK supports the listed x86_64 DSM platforms; the package filename is not tied to a DSM or kernel version.
- The minimum DSM version is set to 7.2.
- Installation scans all `/dev/dri/renderD*` nodes for an AMD GPU, so mixed Intel+AMD systems work even when the AMD device is not `renderD128`.
- When an AMD render node is found, the package safely creates `/usr/bin/amdgpu_top`; upgrade and package-start hooks retry link creation if needed.
- The package contains the standalone monitor and its required libdrm runtime files. It does not install a kernel driver, Mesa, VA-API, or a transcoding stack.

Verified on DSM 7.4.1 with Linux 5.10.55 and Linux 4.4.302. Package installation, AMD render-node detection, `/usr/bin/amdgpu_top` link creation, and stable operation were confirmed on both kernel versions.

## 한국어

`Synology AMDGPU Top 0.1.2`는 지원되는 Synology DSM 시스템에서 `amdgpu_top` 명령을 실행하는 독립형 네이티브 x86_64 패키지입니다.

- 지원 목록에 포함된 x86_64 DSM 플랫폼에서 공용 SPK 하나를 사용합니다. 패키지 파일명은 DSM 또는 커널 버전에 종속되지 않습니다.
- 최소 지원 DSM 메타데이터를 7.2로 설정했습니다.
- `/dev/dri/renderD*` 노드를 모두 검색해 AMD GPU를 찾습니다. 따라서 Intel과 AMD가 함께 있고 AMD가 `renderD128`이 아닌 노드에 연결된 시스템도 처리합니다.
- AMD 렌더 노드를 찾으면 `/usr/bin/amdgpu_top` 심볼릭 링크를 안전하게 생성합니다. 업그레이드 및 패키지 시작 훅도 링크 생성을 재시도합니다.
- 독립 모니터와 필요한 libdrm 런타임 파일을 포함합니다. 커널 드라이버, Mesa, VA-API 또는 트랜스코딩 스택을 설치하지 않습니다.

DSM 7.4.1의 Linux 5.10.55 및 Linux 4.4.302 환경에서 검증을 완료했습니다. 두 커널 버전 모두에서 패키지 설치, AMD 렌더 노드 탐색, `/usr/bin/amdgpu_top` 링크 생성과 안정적인 동작을 확인했습니다.
