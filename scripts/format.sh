#!/usr/bin/env bash
# Format all Luau source files with StyLua
set -euo pipefail

MODE="${1:---check}"

if [ "$MODE" = "--fix" ] || [ "$MODE" = "-f" ]; then
    echo "=== StyLua Format (fix mode) ==="
    stylua ServerScriptService/ StarterPlayerScripts/ ReplicatedStorage/
    echo "All files formatted."
else
    echo "=== StyLua Format Check ==="
    stylua --check ServerScriptService/ StarterPlayerScripts/ ReplicatedStorage/
    echo "All files properly formatted."
fi
