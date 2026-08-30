#!/usr/bin/env bash
# Refresh package-owned scripts/helpers in an existing staged runtime and
# repackage it. This avoids rebuilding libdrm/amdgpu_top when only SPK
# integration code changes.
set -euo pipefail

STAGE=${1:?staging root required}
PLATFORM=${2:?platform required}
DSM_VERSION=${3:?DSM version required}
KERNEL_FLAVOR=${4:-${KERNEL_FLAVOR:-kernel5.10.55}}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PREFIX=/var/packages/syno-amdgpu-top/target
TOOLCHAIN=${TOOLCHAIN_BIN:-/opt/${PLATFORM}/bin}/x86_64-pc-linux-gnu-gcc

[[ -d "$STAGE$PREFIX" ]] || { echo "Missing staged runtime: $STAGE$PREFIX" >&2; exit 2; }
[[ -x $TOOLCHAIN ]] || { echo "Synology toolchain missing for $PLATFORM" >&2; exit 2; }

mkdir -p "$STAGE$PREFIX/bin/helper"
"$TOOLCHAIN" -O2 -Wall -Wextra -Werror \
  "$ROOT/spk/package/bin/helper/amdgpu-path-helper.c" \
  -o "$STAGE$PREFIX/bin/helper/amdgpu-path-helper"
# Package lifecycle scripts run as the package account on DSM. This narrow
# helper is intentionally setuid-root so it can modify only the fixed
# /usr/bin/amdgpu_top shim and nothing else.
chown root:root "$STAGE$PREFIX/bin/helper/amdgpu-path-helper"
chmod 4755 "$STAGE$PREFIX/bin/helper/amdgpu-path-helper"

"$ROOT/scripts/package-spk.sh" "$STAGE" "$PLATFORM" "$DSM_VERSION" "$KERNEL_FLAVOR"
