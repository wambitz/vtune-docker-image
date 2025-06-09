#!/usr/bin/env bash
set -euo pipefail

# Ensure ptrace_scope is open (requires sudo)
if [[ $(cat /proc/sys/kernel/yama/ptrace_scope) -ne 0 ]]; then
    echo "[vtune-run] Temporarily setting kernel.yama.ptrace_scope=0"
    sudo sysctl -w kernel.yama.ptrace_scope=0
fi

docker run --rm \
  --name vtune_hotspots \
  --cap-add=SYS_PTRACE --cap-add=SYS_ADMIN \
  --security-opt seccomp=unconfined \
  --pid=host \
  -u $(id -u):$(id -g) \
  -v "$PWD":/workspace \
  -w /workspace/build \
  vtune-docker \
  vtune -collect hotspots \
        -result-dir /workspace/vtune_results \
        -- ./prime_counter

vtune -report hotspots -r vtune_results