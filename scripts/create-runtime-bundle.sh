#!/usr/bin/env bash
# Produce the minimal Manager-consumable runtime from an already built SPK stage.
set -euo pipefail

STAGE=${1:?staging root required}
KERNEL_FLAVOR=${2:-kernel5.10.55}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PACKAGE=syno-amdgpu-top
VERSION=$(sed -n 's/^version="\([^"]*\)"$/\1/p' "$ROOT/spk/INFO" | head -n 1)
SOURCE="$STAGE/var/packages/$PACKAGE/target"
OUT="$ROOT/dist"
NAME="${PACKAGE}-runtime-${VERSION}-x86_64-${KERNEL_FLAVOR}"
WORK="$ROOT/work/runtime-bundle-${KERNEL_FLAVOR}"

test -x "$SOURCE/bin/amdgpu_top"
test -d "$SOURCE/lib"
rm -rf "$WORK"
mkdir -p "$WORK/runtime/bin" "$WORK/runtime/lib" "$WORK/runtime/share/libdrm"
cp -a "$SOURCE/bin/amdgpu_top" "$WORK/runtime/bin/"
# Only the shared objects (and their symlinks) are runtime data.  Do not leak
# pkg-config metadata into the Manager bundle.
while IFS= read -r library; do
  cp -a "$library" "$WORK/runtime/lib/"
done < <(find "$SOURCE/lib" -maxdepth 1 \( -type f -o -type l \) -name '*.so*' | sort)
test ! -f "$SOURCE/share/libdrm/amdgpu.ids" || cp -a "$SOURCE/share/libdrm/amdgpu.ids" "$WORK/runtime/share/libdrm/"

{
  printf '{\n  "package": "%s",\n  "version": "%s",\n  "architecture": "x86_64",\n  "kernel_flavor": "%s",\n  "files": [\n' "$PACKAGE" "$VERSION" "$KERNEL_FLAVOR"
  first=1
  while IFS= read -r file; do
    rel=${file#"$WORK/runtime/"}
    checksum=$(sha256sum "$file" | awk '{print $1}')
    [ "$first" = 1 ] || printf ',\n'
    printf '    {"path":"%s","sha256":"%s"}' "$rel" "$checksum"
    first=0
  done < <(find "$WORK/runtime" -type f | sort)
  printf '\n  ]\n}\n'
} > "$WORK/manifest.json"

mkdir -p "$OUT"
tar -C "$WORK" -czf "$OUT/$NAME.tar.gz" runtime manifest.json
archive_sha=$(sha256sum "$OUT/$NAME.tar.gz" | awk '{print $1}')
printf '{"package":"%s","version":"%s","archive":"%s.tar.gz","sha256":"%s"}\n' \
  "$PACKAGE" "$VERSION" "$NAME" "$archive_sha" > "$OUT/$NAME.manifest.json"
echo "Built $OUT/$NAME.tar.gz"
