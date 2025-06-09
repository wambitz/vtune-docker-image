# VTune + a bare Ubuntu toolchain
FROM intel/oneapi-vtune:2025.1.3-0-devel-ubuntu24.04

# Basic build deps — nothing fancy
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        build-essential cmake && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
