# syno-amdgpu-top 빌드

[syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)에서 분리된 빌드 파이프라인으로, 소스는 `libdrm`과 `amdgpu_top`(Rust) 둘뿐입니다. Mesa/LLVM/libva/OpenCL 빌드가 전혀 없어서 훨씬 빠르고 결과물도 작습니다.

## Build container prerequisites

이 저장소는 KVM64/Synology 툴체인 교차 컴파일을 사용하지 않습니다. Docker의 Debian 12 x86_64 환경에서 `libdrm`과 `amdgpu_top`을 네이티브 빌드합니다. 두 구성 요소는 사용자 공간 x86_64 바이너리이며 커널 모듈이나 플랫폼별 커널 헤더에 링크되지 않습니다. 이미지 정의는 [`docker/Dockerfile`](../docker/Dockerfile)에 있습니다.

- Meson, Ninja, pkg-config
- Rust/Cargo 및 `x86_64-unknown-linux-gnu` Rust target
- 네이티브 x86_64 C/C++ 컴파일러와 시스템 개발 헤더

LLVM, Mesa, libva, OpenCL은 이미지에 포함하지 않습니다. `run-spk-build.sh` 실행 시 로컬 builder image가 없으면 Dockerfile로 생성합니다.

```bash
./scripts/build-builder.sh
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
./scripts/run-spk-build.sh
```

이미지를 명시적으로 바꾸어 시험할 때만 다음 환경 변수를 사용합니다.

```bash
BUILDER_IMAGE=my-amdgpu-builder:generic-x86_64 ./scripts/run-spk-build.sh
```

패키지 버전 0.1.2의 산출물은 `dist/syno-amdgpu-top-0.1.2-x86_64.spk`입니다. 파일명에는 DSM/커널 버전이 포함되지 않으며, `INFO`의 플랫폼 목록과 DSM 최소 버전은 별도로 관리됩니다. 선언된 최소 DSM은 7.2입니다. DSM 7.2 이하 및 K4 환경의 실기 검증은 별도 확인 대상입니다.

Manager 내장용 runtime bundle도 함께 만들 필요가 있을 때만 다음처럼 요청합니다.

```bash
BUILD_RUNTIME_BUNDLE=1 ./scripts/run-spk-build.sh
```

단일 SPK가 `/dev/dri/renderD*` 노드를 모두 검색하고, AMD render node(PCI vendor `0x1002`)가 있으면 `/usr/bin/amdgpu_top` 심볼릭 링크를 생성합니다. K4/K5 실행 안정성은 동일하다고 가정하지 않으며, K4에서의 구체적인 동작 검증은 별도 과제입니다.
