# syno-amdgpu-top 빌드

[syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)에서 분리된 빌드 파이프라인으로, 소스는 `libdrm`과 `amdgpu_top`(Rust) 둘뿐입니다. Mesa/LLVM/libva/OpenCL 빌드가 전혀 없어서 훨씬 빠르고 결과물도 작습니다.

## Build container prerequisites

이 저장소는 전용 Docker 이미지 `syno-amdgpu-top-builder:7.4`를 사용합니다.
기반은 `dante90/syno-compiler:7.4`이며, Intel 빌더와 같이 그 안의 `/opt/kvmx64`만 가져온 뒤 깨끗한 Debian 12 레이어에 필요한 도구만 설치합니다. 이미지 정의는 [`docker/Dockerfile`](../docker/Dockerfile)에 있으므로 Docker Desktop 또는 Linux Docker 환경에서 같은 결과를 재현할 수 있습니다.

- Meson, Ninja, pkg-config
- Rust/Cargo 및 `x86_64-unknown-linux-gnu` Rust target
- 각 DSM 플랫폼의 Synology 툴체인 (`/opt/<platform>`)

LLVM, Mesa, libva, OpenCL은 이미지에 포함하지 않습니다. 즉, 기존 `syno-amdgpu-driver` 공용 빌더보다 작고 목적이 분명합니다. 최초 `run-spk-build.sh` 실행 시 이미지가 없으면 자동으로 빌드하며, 수동으로 준비하려면 아래를 실행합니다.

```bash
./scripts/build-builder.sh 7.4
```

현재 AMD 런타임의 최초 빌드 기록은 `192.168.45.228` Docker 호스트에서 수행됐습니다. 호스트 OS는 빌드 결과에 영향을 주지 않으며, Docker 엔진과 이 Dockerfile이 재현 가능한 빌드 환경을 정의합니다.

macOS Docker Desktop은 이미지 풀 시 `docker-credential-desktop`을 요구합니다. 빌더 스크립트는 해당 도우미가 일반 셸 `PATH`에 없더라도 Docker.app의 표준 위치를 자동으로 추가하며, Docker 설정 파일은 변경하지 않습니다.

## Sources and reproducibility

`build/versions.env`의 두 upstream archive를 내려받아 다음 이름으로 `sources/`에 푼다.

```text
sources/libdrm
sources/amdgpu_top
```

각 archive의 SHA-256은 `build/sources.lock`에 기록되어 있다. `RELEASE=1` 빌드는 `TODO`가 남아있으면 중단한다.

```bash
./scripts/fetch-sources.sh
```

## Build

```bash
./scripts/run-spk-build.sh 7.4 kvmx64
```

이미지를 명시적으로 바꾸어 시험할 때만 다음 환경 변수를 사용합니다.

```bash
BUILDER_IMAGE=my-amdgpu-builder:7.4 ./scripts/run-spk-build.sh 7.4 kvmx64
```

이 경량 이미지는 의도적으로 `kvmx64`만 포함하므로, 두 번째 인자는 항상 `kvmx64`여야 합니다. `amdgpu_top`은 사용자 공간 x86_64 도구이며, DSM 패키지의 지원 플랫폼 목록은 별도로 관리됩니다.

`dist/syno-amdgpu-top-<version>-7.4-x86_64-kernel5.10.55.spk`와 `...-kernel4.4.x.spk`가 생성됩니다.

## 패키지 통합 코드만 바뀐 경우 (재컴파일 불필요)

`spk/scripts/*`, `spk/conf/*`, `spk/package/bin/helper/amdgpu-path-helper.c`처럼 패키징 계층만 바뀌었다면, 이미 빌드된 SPK를 재사용해 훨씬 빠르게 재패키징할 수 있습니다.

```bash
# 커널 플레이버 하나만
./scripts/repackage-existing-spk.sh dist/syno-amdgpu-top-<version>-7.4-x86_64-kernel5.10.55.spk kvmx64 7.4 kernel5.10.55

# kernel5.10.55 / kernel4.4.x 둘 다
./scripts/repackage-kernel-flavors.sh dist/syno-amdgpu-top-<version>-7.4-x86_64-kernel5.10.55.spk kvmx64 7.4
```

## 커널별 정책

- `kernel5.10.55`: `amdgpu_top`을 `/usr/bin`에 정상 등록. 심볼릭 링크가 누락되면 `start-stop-status`가 패키지 시작 시마다 자가 치유.
- `kernel4.4.x`: 바이너리는 포함하되 `/usr/bin`에 등록하지 않음 (진단용). `start-stop-status`에 자가 치유 로직 자체가 없음.

두 플레이버 모두 AMD DRM render node(`renderD128`의 PCI vendor `0x1002`)가 없으면 postinst/start-stop-status가 조기 종료(no-op)합니다.
