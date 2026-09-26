#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD_ID=generic-x86_64-0.1.2
KERNEL_FLAVOR=${KERNEL_FLAVOR:-kernel5.10.55}
BUILDER_IMAGE=${BUILDER_IMAGE:-syno-amdgpu-top-builder:generic-x86_64}

if ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
  "$ROOT/scripts/build-builder.sh"
fi

SUDO=()
docker info >/dev/null 2>&1 || SUDO=(sudo)
"${SUDO[@]}" docker run --rm --platform linux/amd64 -u 0 \
  -v "$ROOT:/work" \
  -e BUILD_ID="$BUILD_ID" -e KERNEL_FLAVOR="$KERNEL_FLAVOR" \
  -e CARGO_HOME=/work/work/cargo-home \
  -e COMPILE_JOBS="${COMPILE_JOBS:-}" \
  "$BUILDER_IMAGE" \
  bash /work/scripts/build-runtime.sh

if [[ ${BUILD_RUNTIME_BUNDLE:-0} == 1 ]]; then
  VERSION=$(sed -n 's/^version="\([^"]*\)"$/\1/p' "$ROOT/spk/INFO" | head -n 1)
  "$ROOT/scripts/create-runtime-bundle.sh" "$ROOT/dist/syno-amdgpu-top-${VERSION}-x86_64.spk"
fi
