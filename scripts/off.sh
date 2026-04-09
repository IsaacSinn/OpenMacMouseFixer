#!/usr/bin/env bash
# Disable the mouse-button mapping and make the "off" state persistent.
set -euo pipefail

HS_DIR="$HOME/.hammerspoon"
FLAG="$HS_DIR/.mmtmc_enabled"

# Persist "off" state across reboots.
rm -f "$FLAG"

# Flip the live state without a full reload if possible.
if pgrep -x Hammerspoon >/dev/null && command -v hs >/dev/null 2>&1; then
  hs -c "mmtmc.stop()" >/dev/null 2>&1 || hs -c "hs.reload()" >/dev/null 2>&1 || true
fi

echo "✓ Mouse mapping DISABLED (persistent)"
echo "  Hammerspoon is still running in the menu bar; quit it there if you want it gone."
