ARG DSM_VERSION=7.4
FROM dante90/syno-compiler:${DSM_VERSION} AS synology-toolchain

FROM debian:12-slim

# The released AMD monitor is the portable DSM x86_64 kvmx64 build.  Copy only
# that representative Synology toolchain, as syno-intel-gpu-top does, rather
# than cloning every /opt platform into Docker Desktop.
#
# Unlike syno-amdgpu-driver this image deliberately excludes LLVM, Mesa and
# VA-API: amdgpu_top only needs libdrm, Meson/Ninja and Rust/Cargo.
COPY --from=synology-toolchain /opt/kvmx64 /opt/kvmx64

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      meson \
      ninja-build \
      pkg-config \
      python3 \
      python3-pip \
      xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m pip install --no-cache-dir --break-system-packages meson==1.5.2 \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && /root/.cargo/bin/rustup target add x86_64-unknown-linux-gnu

ENV PATH=/root/.cargo/bin:${PATH}
WORKDIR /work
