#!/usr/bin/env bash
# Build the dedicated native x86_64 amdgpu_top builder.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

# Docker Desktop records `credsStore: desktop` in ~/.docker/config.json.  The
# Desktop helper is not always on the shell PATH when this script is launched
# from a terminal or an IDE, which otherwise makes even public base-image pulls
# fail.  Keep this local to the build process; do not alter the user's Docker
# configuration.
if ! command -v docker-credential-desktop >/dev/null 2>&1 && \
   [[ -x /Applications/Docker.app/Contents/Resources/bin/docker-credential-desktop ]]; then
  export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

docker build --platform linux/amd64 \
  -t "${BUILDER_IMAGE:-syno-amdgpu-top-builder:generic-x86_64}" \
  -f "$ROOT/docker/Dockerfile" "$ROOT"
