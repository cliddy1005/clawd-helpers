#!/bin/sh
# Checks both helpers without Clawd attached. A local server stands in for Clawd's Wi-Fi address
# and a plain file stands in for its USB port. Needs Node and Python 3.
cd "$(dirname "$0")"
USB=/tmp/clawd-usb-test.txt; : > "$USB"
python3 sink.py 18080 > /tmp/clawd-wifi.log 2>&1 & W=$!
sleep 1
echo "== opencode plugin"
node opencode-plugin.mjs
echo "== Claude Code hook"
printf '{"message":"Claude needs your permission to use Bash","cwd":"/Users/x/code/my-app"}' \
  | CLAWD_HOST=127.0.0.1:18080 CLAWD_PORT="$USB" sh ../claude-code/clawd-notify.sh waiting
sleep 1
kill $W; wait $W 2>/dev/null
echo; echo "Wi-Fi received:"; cat /tmp/clawd-wifi.log
echo; echo "USB received:"; cat "$USB"
