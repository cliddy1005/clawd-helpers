#!/bin/sh
# Sends Claude Code events to Clawd, over Wi-Fi and (if the bridge is running) Bluetooth.
# Usage (from a Claude Code hook):  clawd-notify.sh working|waiting|done|idle
# Claude Code passes the event as JSON on stdin; we forward its message and project name.
# Runs in the background with a 2-second timeout, so it never slows Claude Code down.
# Clawd ignores the duplicate when both routes deliver.

STATE="$1"
HOST="${CLAWD_HOST:-clawd.local}"          # Wi-Fi; set to Clawd's IP if .local names don't work
BRIDGE="${CLAWD_BRIDGE:-127.0.0.1:8765}"         # Bluetooth bridge (clawd-ble-bridge.py)

INPUT=$(cat)
MSG=$(printf '%s' "$INPUT" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | cut -c1-200)
CWD=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
PROJECT=$(basename "${CWD:-$PWD}")

for target in "$HOST" "$BRIDGE"; do
  ( curl -s -m 2 -o /dev/null -G "http://$target/cc" \
      --data-urlencode "state=$STATE" \
      --data-urlencode "msg=$MSG" \
      --data-urlencode "project=$PROJECT" & ) >/dev/null 2>&1
done
exit 0
