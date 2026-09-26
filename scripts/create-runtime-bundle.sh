#!/usr/bin/env bash
# Produce a kernel-agnostic runtime bundle from the exact built SPK.
set -euo pipefail

SPK=${1:?built SPK required}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PACKAGE=syno-amdgpu-top
OUT="$ROOT/dist"
[[ -f $SPK ]] || { echo "SPK not found: $SPK" >&2; exit 2; }
SPK=$(cd "$(dirname "$SPK")" && pwd)/$(basename "$SPK")
INFO=$(tar -xOf "$SPK" INFO)
VERSION=$(sed -n 's/^version="\([^"]*\)"$/\1/p' <<<"$INFO" | head -n 1)
MIN_DSM=$(sed -n 's/^os_min_ver="\([^"]*\)"$/\1/p' <<<"$INFO" | head -n 1)
[[ -n $VERSION && -n $MIN_DSM ]] || { echo "Missing version/DSM metadata in $SPK" >&2; exit 2; }
LIBDRM_VERSION=$(sed -n 's/^LIBDRM_VERSION=//p' "$ROOT/build/versions.env")
AMDGPU_TOP_VERSION=$(sed -n 's/^AMDGPU_TOP_VERSION=//p' "$ROOT/build/versions.env")
LIBDRM_SHA256=$(awk '$1 == "libdrm-" v ".tar.xz" {print $2}' v="$LIBDRM_VERSION" "$ROOT/build/sources.lock")
AMDGPU_TOP_SHA256=$(awk '$1 == "amdgpu_top-" v ".tar.gz" {print $2}' v="$AMDGPU_TOP_VERSION" "$ROOT/build/sources.lock")
[[ -n $LIBDRM_VERSION && -n $AMDGPU_TOP_VERSION && -n $LIBDRM_SHA256 && -n $AMDGPU_TOP_SHA256 ]] || {
  echo "Missing pinned source provenance in build/versions.env or build/sources.lock" >&2
  exit 2
}
NAME="${PACKAGE}-runtime-${VERSION}-x86_64"
WORK=$(mktemp -d "$ROOT/work/runtime-bundle.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/rootfs" "$WORK/runtime/bin" "$WORK/runtime/lib" "$WORK/runtime/share/libdrm"
tar -xOf "$SPK" package.tgz | tar -xz -C "$WORK/rootfs"
SOURCE="$WORK/rootfs/."
test -x "$SOURCE/bin/amdgpu_top"
test -d "$SOURCE/lib"
cp -a "$SOURCE/bin/amdgpu_top" "$WORK/runtime/bin/"

# Bundle only runtime libraries/symlinks, not development headers or pkg-config files.
while IFS= read -r library; do
  cp -a "$library" "$WORK/runtime/lib/"
done < <(find "$SOURCE/lib" -maxdepth 1 \( -type f -o -type l \) -name '*.so*' | sort)
test ! -f "$SOURCE/share/libdrm/amdgpu.ids" || cp -a "$SOURCE/share/libdrm/amdgpu.ids" "$WORK/runtime/share/libdrm/"
install -m 0644 "$ROOT/LICENSE" "$WORK/runtime/LICENSE"

{
  printf '{\n  "schema_version": 1,\n  "package": "%s",\n  "version": "%s",\n  "architecture": "x86_64",\n  "minimum_dsm": "%s",\n  "kernel_specific": false,\n  "source_spk": "%s",\n  "source_spk_sha256": "%s",\n  "components": [\n    {"name":"amdgpu_top","version":"%s","source_sha256":"%s"},\n    {"name":"libdrm","version":"%s","source_sha256":"%s"}\n  ],\n  "files": [\n' \
    "$PACKAGE" "$VERSION" "$MIN_DSM" "$(basename "$SPK")" "$(sha256sum "$SPK" | awk '{print $1}')" \
    "$AMDGPU_TOP_VERSION" "$AMDGPU_TOP_SHA256" "$LIBDRM_VERSION" "$LIBDRM_SHA256"
  first=1
  while IFS= read -r -d '' file; do
    rel=${file#"$WORK/runtime/"}
    checksum=$(sha256sum "$file" | awk '{print $1}')
    size=$(wc -c < "$file" | tr -d ' ')
    [ "$first" = 1 ] || printf ',\n'
    printf '    {"path":"%s","type":"file","size_bytes":%s,"sha256":"%s"}' "$rel" "$size" "$checksum"
    first=0
  done < <(find "$WORK/runtime" -type f -print0 | sort -z)
  while IFS= read -r -d '' file; do
    rel=${file#"$WORK/runtime/"}
    target=$(readlink "$file")
    [ "$first" = 1 ] || printf ',\n'
    printf '    {"path":"%s","type":"symlink","target":"%s"}' "$rel" "$target"
    first=0
  done < <(find "$WORK/runtime" -type l -print0 | sort -z)
  printf '\n  ]\n}\n'
} > "$WORK/manifest.json"

mkdir -p "$OUT"
tar -C "$WORK" -czf "$OUT/$NAME.tar.gz" runtime manifest.json
cp "$WORK/manifest.json" "$OUT/$NAME.manifest.json"
archive_sha=$(sha256sum "$OUT/$NAME.tar.gz" | awk '{print $1}')
printf '%s  %s\n' "$archive_sha" "$(basename "$OUT/$NAME.tar.gz")" > "$OUT/$NAME.tar.gz.sha256"
echo "Built $OUT/$NAME.tar.gz"
