#!/usr/bin/env bash
# Build .rbxlx place file using Rojo
set -euo pipefail

OUTPUT="${1:-AngelCloud.rbxlx}"

echo "=== Installing Wally packages ==="
wally install
mkdir -p Packages/Server

echo "=== Building place file ==="
rojo build -o "$OUTPUT"

echo "Build complete: $OUTPUT"
ls -lh "$OUTPUT"
