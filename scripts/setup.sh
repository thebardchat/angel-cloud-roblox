#!/usr/bin/env bash
# First-time project setup — installs all tools and dependencies
set -euo pipefail

echo "=== Angel Cloud ROBLOX — Project Setup ==="
echo ""

# Check for Foreman
if ! command -v foreman &> /dev/null; then
    echo "Foreman not found. Installing via cargo..."
    if command -v cargo &> /dev/null; then
        cargo install foreman
    else
        echo "ERROR: Neither foreman nor cargo found."
        echo "Install Foreman from: https://github.com/Roblox/foreman/releases"
        exit 1
    fi
fi

echo "1/4 Installing Foreman tools (Rojo, Wally, Selene, StyLua)..."
foreman install
echo "    Done."

echo "2/4 Installing Wally packages..."
wally install
mkdir -p Packages/Server
echo "    Done."

echo "3/4 Verifying tools..."
echo "    Rojo:   $(rojo --version 2>/dev/null || echo 'NOT FOUND')"
echo "    Wally:  $(wally --version 2>/dev/null || echo 'NOT FOUND')"
echo "    Selene: $(selene --version 2>/dev/null || echo 'NOT FOUND')"
echo "    StyLua: $(stylua --version 2>/dev/null || echo 'NOT FOUND')"

echo "4/4 Quick lint check..."
selene ServerScriptService/ StarterPlayerScripts/ ReplicatedStorage/ 2>/dev/null && echo "    Lint: PASSED" || echo "    Lint: Issues found (run scripts/lint.sh for details)"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Open Roblox Studio"
echo "  2. Run: rojo serve"
echo "  3. In Studio: Plugins → Rojo → Connect"
echo "  4. Start building!"
