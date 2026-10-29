#!/bin/sh
# Simulates opencode events against the plugin and prints what Clawd would receive.
cd "$(dirname "$0")"
python3 sink.py 18080 > /tmp/clawd-wifi.log 2>&1 & W=$!
python3 sink.py 18081 > /tmp/clawd-ble.log 2>&1 & B=$!
sleep 1
node opencode-plugin.mjs
kill $W $B; wait $W $B 2>/dev/null
echo "Wi-Fi target received:"; cat /tmp/clawd-wifi.log
echo "Bluetooth bridge received: $(wc -l < /tmp/clawd-ble.log | tr -d ' ') requests"
