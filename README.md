# syno-amdgpu-top

Synology DSM용 독립형 `amdgpu_top` GPU 모니터 SPK.

## Reproducible builder

`amdgpu_top`과 `libdrm`은 KVM64/Synology 툴체인 교차 컴파일 없이 Docker의 Debian 12 x86_64 환경에서 네이티브 빌드합니다. DSM 플랫폼별 커널 모듈이 아닌 사용자 공간 프로그램이므로, 이 패키지는 지원 아키텍처 목록을 공유하는 단일 SPK로 패키징됩니다.

```bash
./scripts/fetch-sources.sh
./scripts/run-spk-build.sh
```

이미지 구성과 수동 생성 방법은 [빌드 문서](docs/build.md)를 참조하세요. 빌더는 libdrm과 Rust 기반 `amdgpu_top`의 빌드 도구만 포함하며 Mesa/LLVM/VA-API는 포함하지 않습니다.

빌드가 완료되면 `dist/syno-amdgpu-top-0.1.2-x86_64.spk`가 생성됩니다. SPK 이름에는 DSM 버전이나 커널 버전을 넣지 않습니다. Manager 내장용 runtime bundle이 필요할 때만 `BUILD_RUNTIME_BUNDLE=1 ./scripts/run-spk-build.sh`로 별도 생성할 수 있습니다.

패키지 메타데이터의 최소 DSM은 7.2로 설정했습니다. 실제 설치 검증은 DSM 7.4.1에서 진행 중이며, DSM 7.2 및 커널 4.x 환경은 별도 실기 검증이 필요합니다.

[syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)(AMD VA-API/RADV Vulkan 런타임)에서 `amdgpu_top`만 분리한 패키지입니다. `amdgpu_top`은 `libdrm_amdgpu`를 통해 커널의 `amdgpu.ko` 드라이버와 DRM ioctl/sysfs로 직접 통신하는 **모니터링 전용 도구**로, Mesa(RadeonSI/RADV)나 libva 같은 무거운 렌더링/트랜스코딩 스택에 전혀 의존하지 않습니다. 그래서:

- GPU 사용률, VRAM, 클럭, 온도, 팬, 프로세스별 GPU 점유율을 보는 것만이 목적이라면 이 패키지 하나로 충분합니다.
- Jellyfin/Plex 하드웨어 트랜스코딩(VA-API)이 필요하면 [syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver)를 설치하세요 — 그쪽은 Mesa/LLVM까지 포함해 훨씬 큽니다.

## 설치 후 사용

```bash
amdgpu_top
```

`/usr/bin/amdgpu_top` 심볼릭 링크가 자동으로 등록됩니다. 패키지는 `/dev/dri/renderD*` 노드를 모두 검색하므로, AMD 노드 번호가 `renderD128`이 아니어도 찾습니다. AMD DRM render node가 없는 NAS(Intel iGPU만 있는 경우 등)에서는 설치는 되지만 PATH 등록 없이 no-op으로 끝납니다.

> [!WARNING]
> 현재 패키지는 AMD render node가 확인되면 커널 버전과 관계없이 `/usr/bin/amdgpu_top` 심볼릭 링크를 등록합니다. K4 백포트 드라이버에서의 실행 안정성은 K5와 별개로 검증이 필요하므로, K4 환경에서는 사용 시 주의하세요.

## 빌드

자세한 내용은 [docs/build.md](docs/build.md) 참고. 요약:

```bash
./scripts/fetch-sources.sh
./scripts/run-spk-build.sh
```

바이너리 출처와 파생 패키지의 사용 규칙은 [런타임 관리 설계](docs/runtime-governance.md)에 기록합니다.

## 라이선스

MIT — [LICENSE](LICENSE) 참고.
