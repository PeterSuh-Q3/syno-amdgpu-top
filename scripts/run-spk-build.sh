#!/usr/bin/env bash
set -euo pipefail

DSM_VERSION=${1:-7.4}
PLATFORM=${2:-kvmx64}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
# Dedicated AMD monitor builder.  It has the DSM toolchains plus only the
# libdrm/Rust build dependencies; it intentionally excludes Mesa/LLVM/VA-API.
BUILDER_IMAGE=${BUILDER_IMAGE:-dante90/syno-amdgpu-top-builder:${DSM_VERSION}}

[[ $PLATFORM == kvmx64 ]] || {
  echo 'This compact builder contains only the kvmx64 toolchain; use kvmx64.' >&2
  exit 2
}

"$ROOT/scripts/generate-cross-file.sh" "$PLATFORM" "$DSM_VERSION" >/dev/null

if ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
  docker pull "$BUILDER_IMAGE" || "$ROOT/scripts/build-builder.sh" "$DSM_VERSION"
fi

SUDO=()
docker info >/dev/null 2>&1 || SUDO=(sudo)
"${SUDO[@]}" docker run --rm -t -u 0 \
  -v "$ROOT:/work" \
  -e PLATFORM -e DSM_VERSION \
  -e COMPILE_JOBS="${COMPILE_JOBS:-}" \
  "$BUILDER_IMAGE" \
  bash /work/scripts/build-runtime.sh
