#!/usr/bin/env bash
set -euo pipefail

ROOT=${ROOT:-/work}
BUILD_ID=${BUILD_ID:-generic-x86_64-0.1.2}
KERNEL_FLAVOR=${KERNEL_FLAVOR:-kernel5.10.55}
PREFIX=/var/packages/syno-amdgpu-top/target
BUILD_ROOT=$ROOT/work/${BUILD_ID}
SOURCE_ROOT=$ROOT/sources
STAGE=$BUILD_ROOT/stage
COMPILE_JOBS=${COMPILE_JOBS:-$(nproc)}

[[ $(uname -m) == x86_64 ]] || { echo "Native builder must run on x86_64 (got $(uname -m))" >&2; exit 1; }
command -v cc >/dev/null
command -v meson >/dev/null
command -v ninja >/dev/null
command -v cargo >/dev/null
mkdir -p "$BUILD_ROOT" "$SOURCE_ROOT"
rm -rf "$STAGE"
mkdir -p "$STAGE"

progress() {
  [[ -n ${STATUS_FILE:-} ]] || return 0
  local phase="$1"
  case "$phase" in
    libdrm) phase='1/2 libdrm'; case "$3" in configure) set -- "$1" "$2" '1/3 configure';; build) set -- "$1" "$2" '2/3 build';; install) set -- "$1" "$2" '3/3 install';; esac ;;
    amdgpu_top) phase='2/2 amdgpu_top'; case "$3" in cargo) set -- "$1" "$2" '1/2 cargo';; package) set -- "$1" "$2" '2/2 package';; esac ;;
  esac
  printf '%s\t%s\t%s\t%s\n' "$phase" "$2" "${3:-}" "$(date +%s)" > "$STATUS_FILE"
}

# Populate sources/ with the exact archives in build/versions.env, unpacked as
# libdrm/ and amdgpu_top/. Release builds require locked hashes.
if [[ ${RELEASE:-0} == 1 ]] && grep -q ' TODO$' "$ROOT/build/sources.lock"; then
  echo "sources.lock is incomplete; refusing a release build" >&2
  exit 1
fi
for required in libdrm amdgpu_top; do
  [[ -d $SOURCE_ROOT/$required ]] || { echo "missing source: $SOURCE_ROOT/$required" >&2; exit 1; }
done

export PATH="$(dirname "$(command -v cargo)"):$PATH"
progress libdrm running configure
# amdgpu_top only talks to the kernel driver through libdrm_amdgpu - no other
# libdrm backend (intel/radeon/nouveau/vmwgfx) is needed here.
if [[ -f "$BUILD_ROOT/libdrm/meson-private/coredata.dat" ]]; then
  meson setup --wipe "$BUILD_ROOT/libdrm" "$SOURCE_ROOT/libdrm" --prefix="$PREFIX" --libdir=lib \
    -Damdgpu=enabled -Dintel=disabled -Dradeon=disabled -Dnouveau=disabled -Dvmwgfx=disabled \
    -Dvalgrind=disabled -Dfreedreno=disabled -Detnaviv=disabled -Dexynos=disabled -Domap=disabled \
    -Dtegra=disabled -Dvc4=disabled -Dcairo-tests=disabled -Dman-pages=disabled
else
  meson setup "$BUILD_ROOT/libdrm" "$SOURCE_ROOT/libdrm" --prefix="$PREFIX" --libdir=lib \
  -Damdgpu=enabled -Dintel=disabled -Dradeon=disabled -Dnouveau=disabled -Dvmwgfx=disabled \
  -Dvalgrind=disabled -Dfreedreno=disabled -Detnaviv=disabled -Dexynos=disabled -Domap=disabled \
  -Dtegra=disabled -Dvc4=disabled -Dcairo-tests=disabled -Dman-pages=disabled
fi
ninja -C "$BUILD_ROOT/libdrm" -j"$COMPILE_JOBS"
progress libdrm running build
DESTDIR="$STAGE" ninja -C "$BUILD_ROOT/libdrm" install
progress libdrm running install

# amdgpu_top's "dynamic_loading_package" feature dlopen()s libdrm at runtime
# instead of link-time linking, so the package can carry its own ABI-matched
# copy without touching any DSM global library. RUSTFLAGS' rpath points the
# resulting binary at ../lib (this package's own staged libdrm.so).
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=cc
export RUSTFLAGS="-C link-arg=-Wl,-rpath,\$ORIGIN/../lib"
export PKG_CONFIG_PATH="$STAGE$PREFIX/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$STAGE$PREFIX/lib/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="$STAGE"
progress amdgpu_top running cargo
pushd "$SOURCE_ROOT/amdgpu_top" >/dev/null
CARGO_BUILD_JOBS="$COMPILE_JOBS" CARGO_TARGET_DIR="$BUILD_ROOT/cargo-target" cargo build --release --target x86_64-unknown-linux-gnu --no-default-features --features dynamic_loading_package
install -Dm755 "$BUILD_ROOT/cargo-target/x86_64-unknown-linux-gnu/release/amdgpu_top" "$STAGE$PREFIX/bin/amdgpu_top"
progress amdgpu_top running package
popd >/dev/null

# DSM applies root ownership and setuid only to the explicitly declared
# privilege tool. Refresh this integration file immediately before packaging
# so package-only updates remain reproducible.
"$ROOT/scripts/refresh-spk-stage.sh" "$STAGE" x86_64 7.4 "$KERNEL_FLAVOR"
progress complete success
