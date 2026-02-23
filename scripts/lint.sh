#!/usr/bin/env bash
# Run Selene linter on all Luau source files
set -euo pipefail

echo "=== Selene Lint ==="
selene ServerScriptService/ StarterPlayerScripts/ ReplicatedStorage/
echo "All files passed lint check."
