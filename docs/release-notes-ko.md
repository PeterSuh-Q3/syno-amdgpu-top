# 릴리즈 노트

## 0.1.1

`kernel5.10.55` 패키지가 실제로 5.10.55 커널에서 실행 중인지 `postinst`/`start-stop-status`에서 `uname -r`로 확인하도록 추가했습니다. 이전에는 커널별 분리가 "어느 `.spk` 파일을 설치하는가"라는 사용자 선택에만 의존해서, 실수로 `kernel5.10.55.spk`를 4.4 커널 기기에 설치하면 검증 없이 `amdgpu_top`을 PATH에 등록해버렸습니다. 이제 실행 중인 커널이 5.10.55가 아니면 PATH 등록/자가 치유를 건너뜁니다.

## 0.1.0

[syno-amdgpu-driver](https://github.com/PeterSuh-Q3/syno-amdgpu-driver) 0.4.1에서 `amdgpu_top` 관련 코드(바이너리, `amdgpu-path-helper` setuid 도구, PATH 자가 치유, 커널별 정책)를 그대로 분리해 독립 패키지로 최초 배포합니다.

- `amdgpu_top`은 `libdrm_amdgpu`(런타임 dlopen)를 통해 커널의 `amdgpu.ko`와만 통신하며, Mesa/RadeonSI/RADV/libva에 의존하지 않습니다. 그래서 GPU 모니터링만 필요한 사용자는 무거운 VA-API 런타임 없이 이 패키지 하나로 충분합니다.
- `kernel5.10.55` / `kernel4.4.x` 두 플레이버로 나뉘며, 정책은 `syno-amdgpu-driver`와 동일합니다(4.4는 `/usr/bin` 미등록).
- AMD DRM render node가 없는 NAS(Intel iGPU 등)에서는 설치는 되지만 아무것도 건드리지 않는 no-op으로 동작합니다.
- `/usr/bin/amdgpu_top` 심볼릭 링크는 `amdgpu-path-helper`(setuid, symlink 스와핑 방지 로직 포함)가 관리하며, 최초 설치 시 실패해도 패키지 시작 시마다 자가 치유합니다.
