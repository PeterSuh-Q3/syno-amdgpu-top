#!/usr/bin/env bash
# Repackage a released SPK after a package-integration-only change. The
# target libdrm/amdgpu_top binaries remain untouched; only package-owned
# scripts/helpers are updated.
set -euo pipefail

INPUT=${1:?existing SPK required}
PLATFORM=${2:?platform required}
DSM_VERSION=${3:?DSM version required}
KERNEL_FLAVOR=${4:-kernel5.10.55}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PACKAGE=syno-amdgpu-top
WORK="$ROOT/work/repackage-${PLATFORM}-${DSM_VERSION}"
STAGE="$WORK/stage"
TARGET="$STAGE/var/packages/$PACKAGE/target"
TOOLCHAIN=${TOOLCHAIN_BIN:-/opt/${PLATFORM}/bin}/x86_64-pc-linux-gnu-gcc

[[ -f "$INPUT" ]] || { echo "Missing input SPK: $INPUT" >&2; exit 2; }
[[ -x $TOOLCHAIN ]] || { echo "Synology toolchain missing for $PLATFORM" >&2; exit 2; }
rm -rf "$WORK"
mkdir -p "$WORK/assembly" "$TARGET"
tar -xf "$INPUT" -C "$WORK/assembly"
[[ -f "$WORK/assembly/package.tgz" ]] || { echo 'Input SPK has no package.tgz' >&2; exit 2; }
tar -xzf "$WORK/assembly/package.tgz" -C "$TARGET"

mkdir -p "$TARGET/bin/helper"
"$TOOLCHAIN" -O2 -Wall -Wextra -Werror \
  "$ROOT/spk/package/bin/helper/amdgpu-path-helper.c" \
  -o "$TARGET/bin/helper/amdgpu-path-helper"
chmod 0755 "$TARGET/bin/helper/amdgpu-path-helper"
chown root:root "$TARGET/bin/helper/amdgpu-path-helper"
chmod 4755 "$TARGET/bin/helper/amdgpu-path-helper"

"$ROOT/scripts/package-spk.sh" "$STAGE" "$PLATFORM" "$DSM_VERSION" "$KERNEL_FLAVOR"
