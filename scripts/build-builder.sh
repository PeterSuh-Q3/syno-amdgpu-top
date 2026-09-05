#!/usr/bin/env bash
# Build the dedicated, reproducible amdgpu_top DSM cross-builder.
set -euo pipefail

DSM_VERSION=${1:-7.4}
[[ $DSM_VERSION == 7.4 ]] || { echo 'Supported builder profile: 7.4' >&2; exit 2; }

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

docker build --build-arg "DSM_VERSION=$DSM_VERSION" \
  -t "dante90/syno-amdgpu-top-builder:${DSM_VERSION}" \
  -f "$ROOT/docker/Dockerfile" "$ROOT"
