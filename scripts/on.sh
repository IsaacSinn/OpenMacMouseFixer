#!/usr/bin/env bash
# Enable the mouse-button mapping and make it persistent across restarts.
set -euo pipefail

HS_DIR="$HOME/.hammerspoon"
FLAG="$HS_DIR/.mmtmc_enabled"

if [[ ! -f "$HS_DIR/init.lua" ]]; then
  echo "error: $HS_DIR/init.lua not found — install the repo's init.lua first" >&2
  exit 1
fi

# Persist "on" state across reboots. init.lua checks for this file on launch.
touch "$FLAG"

# Make sure Hammerspoon is running (it will auto-launch at login after first run).
if ! pgrep -x Hammerspoon >/dev/null; then
  open -g -a Hammerspoon
  # Give it a moment to boot and install the `hs` CLI
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.3
    command -v hs >/dev/null && break
  done
fi

# Flip the live state without a full config reload if the CLI is available.
if command -v hs >/dev/null 2>&1; then
  hs -c "mmtmc.start()" >/dev/null 2>&1 || hs -c "hs.reload()" >/dev/null 2>&1 || true
fi

echo "✓ Mouse mapping ENABLED (persistent)"
echo "  Flag file: $FLAG"
echo "  Edit bindings in: $HS_DIR/init.lua"
echo
echo "First-time setup: grant Hammerspoon Accessibility permission in"
echo "System Settings → Privacy & Security → Accessibility."
