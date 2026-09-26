FROM debian:12-slim

# amdgpu_top/libdrm are userspace x86_64 projects. Build natively instead of
# binding the artifact to a Synology platform toolchain. DSM support remains
# bounded by package metadata and the userspace ABI; no Mesa/LLVM/VA-API here.

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      libpciaccess-dev \
      libudev-dev \
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
