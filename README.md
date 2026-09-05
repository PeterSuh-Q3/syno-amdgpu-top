# syno-amdgpu-top

Synology DSM용 독립형 `amdgpu_top` GPU 모니터 SPK.

## Reproducible builder

AMD 런타임은 Docker Hub의 전용 이미지 `dante90/syno-amdgpu-top-builder:7.4`에서 빌드합니다. 이미지가 없으면 아래 빌드 명령이 자동으로 pull하며, 공개 이미지 조회가 실패할 때만 로컬 Dockerfile로 재생성합니다.

```bash
./scripts/fetch-sources.sh
./scripts/run-spk-build.sh 7.4 kvmx64
```

이미지 구성과 수동 생성 방법은 [빌드 문서](docs/build.md)를 참조하세요. Intel 빌더와 마찬가지로 `syno-compiler:7.4`의 `/opt/kvmx64`만 복사하며, `libdrm`과 Rust 기반 `amdgpu_top`을 빌드하는 데 필요한 도구만 포함합니다. Mesa/LLVM/VA-API는 포함하지 않습니다.

빌드가 완료되면 SPK와 함께 `syno-amdgpu-top-runtime-*-kernel5.10.55.tar.gz` 및 sidecar `*.manifest.json`도 `dist/`에 생성됩니다. runtime bundle은 Manager 내장용이며 `amdgpu_top`, 전용 libdrm, DRM ID 데이터와 archive/file SHA-256 검증 정보를 포함합니다.

[syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)(AMD VA-API/RADV Vulkan 런타임)에서 `amdgpu_top`만 분리한 패키지입니다. `amdgpu_top`은 `libdrm_amdgpu`를 통해 커널의 `amdgpu.ko` 드라이버와 DRM ioctl/sysfs로 직접 통신하는 **모니터링 전용 도구**로, Mesa(RadeonSI/RADV)나 libva 같은 무거운 렌더링/트랜스코딩 스택에 전혀 의존하지 않습니다. 그래서:

- GPU 사용률, VRAM, 클럭, 온도, 팬, 프로세스별 GPU 점유율을 보는 것만이 목적이라면 이 패키지 하나로 충분합니다.
- Jellyfin/Plex 하드웨어 트랜스코딩(VA-API)이 필요하면 [syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)를 설치하세요 — 그쪽은 Mesa/LLVM까지 포함해 훨씬 큽니다.

## 설치 후 사용

```bash
amdgpu_top
```

`/usr/bin/amdgpu_top` 심볼릭 링크가 자동으로 등록됩니다. AMD DRM render node(`/dev/dri/renderD128`, PCI vendor `0x1002`)가 없는 NAS(Intel iGPU만 있는 경우 등)에서는 패키지 설치는 되지만 PATH 등록 없이 no-op으로 끝납니다.

> [!WARNING]
> DSM 커널 4.4 환경은 `amdgpu_top`이 DRM 컨텍스트를 닫을 때 커널의 백포트된 AMDGPU 스케줄러가 불안정할 수 있다는 [syno-amdgpu-driver 쪽 관찰](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)에 따라, `kernel4.4.x` 패키지에서는 바이너리는 유지하되 `/usr/bin`에 등록하지 않습니다(실험적 진단 도구로만 보관).

## 빌드

자세한 내용은 [docs/build.md](docs/build.md) 참고. 요약:

```bash
./scripts/fetch-sources.sh
./scripts/run-spk-build.sh 7.4 kvmx64
```

패키지 스크립트/버전만 바뀐 경우(라이브러리 재컴파일 불필요)에는:

```bash
./scripts/repackage-kernel-flavors.sh dist/syno-amdgpu-top-<version>-7.4-x86_64-kernel5.10.55.spk kvmx64 7.4
```

## 라이선스

MIT — [LICENSE](LICENSE) 참고.
