#!/bin/bash

# Alin's Omarchy Extensions - Main Installer
# Runs all individual extension installers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/install"

echo "╔═══════════════════════════════════════════╗"
echo "║   Alin's Omarchy Extensions Installer     ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Ensure ~/.local/bin is available
mkdir -p "$HOME/.local/bin"

# ─────────────────────────────────────────────────────────────
# Run all installers in install/ directory
# ─────────────────────────────────────────────────────────────

for installer in "$INSTALL_DIR"/*.sh; do
  if [[ -f "$installer" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$installer"
    echo ""
  fi
done

# ─────────────────────────────────────────────────────────────
# Restart waybar to apply changes
# ─────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Restarting waybar..."
omarchy-restart-waybar 2>/dev/null && echo "   ✓ Waybar restarted" || echo "   ⚠ Run 'omarchy-restart-waybar' manually"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ All extensions installed!"
echo "═══════════════════════════════════════════════════════════"
