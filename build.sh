#!/usr/bin/env bash

# -----------------------------------------------------------
# Build on host
# ----------------------------------------------------------- 

# set -euo pipefail

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# BUILD_DIR="$SCRIPT_DIR/build"

# mkdir -p "$BUILD_DIR"
# cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR"
# cmake --build "$BUILD_DIR" -j$(nproc)

# echo "Binary ready: $BUILD_DIR/prime_counter"

# -----------------------------------------------------------
# Build inside container
# ----------------------------------------------------------- 
docker run --rm -it \
  -u $(id -u):$(id -g) \
  -v "$PWD":/workspace \
  -w /workspace \
  vtune-demo \
  bash -c "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j$(nproc)"
