#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMAGE=${BUILDER_IMAGE:-dante90/syno-amdgpu-top-builder:7.4}
mkdir -p "$ROOT/dist"

docker run --rm --user "$(id -u):$(id -g)" \
  -v "$ROOT:/work" -w /work "$IMAGE" \
  /opt/kvmx64/bin/x86_64-pc-linux-gnu-gcc \
  -std=c11 -D_GNU_SOURCE -O0 -g -Wall -Wextra -Werror \
  -I /work/sources/libdrm/amdgpu \
  /work/tests/k4-drm-close-repro.c -ldl \
  -o /work/dist/k4-drm-close-repro-x86_64

echo "$ROOT/dist/k4-drm-close-repro-x86_64"
