# syno-amdgpu-top 빌드

[syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)에서 분리된 빌드 파이프라인으로, 소스는 `libdrm`과 `amdgpu_top`(Rust) 둘뿐입니다. Mesa/LLVM/libva/OpenCL 빌드가 전혀 없어서 훨씬 빠르고 결과물도 작습니다.

## Build container prerequisites

`syno-amdgpu-driver`와 동일한 `dante90/syno-compiler:7.4`(→ `syno-amdgpu-builder:7.4`) 이미지를 그대로 재사용합니다. 이 이미지는 이미 아래를 제공합니다.

- Meson, Ninja, pkg-config
- Rust/Cargo 및 `x86_64-unknown-linux-gnu` Rust target
- 각 DSM 플랫폼의 Synology 툴체인 (`/opt/<platform>`)

이 저장소 전용 경량 빌더 이미지는 아직 없습니다 — LLVM/Mesa 툴체인까지 포함된 기존 이미지를 그대로 쓰는 것뿐이라 이미지 자체는 무겁지만, 빌드 자체는 libdrm+amdgpu_top만 컴파일하므로 빠릅니다.

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
