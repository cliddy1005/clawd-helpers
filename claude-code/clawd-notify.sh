#!/bin/sh
# Sends Claude Code events to Clawd over Wi-Fi and, if Clawd is plugged into this computer, over USB.
# Usage (from a Claude Code hook):  clawd-notify.sh working|waiting|done|idle
# Claude Code passes the event as JSON on stdin; we forward its message and project name.
# Nothing runs in the background between events: this exits straight away, and the sends
# finish on their own within 2 seconds, so Claude Code is never slowed down.
# Clawd ignores the duplicate when both routes deliver.
#
# Settings (optional, e.g. in ~/.zshrc):
#   CLAWD_HOST=192.168.1.42     Clawd's IP, if clawd.local doesn't work on your network
#   CLAWD_PORT=/dev/cu.usbmodem101   Clawd's USB port, if you have other USB boards plugged in
#   CLAWD_PORT=none             never use USB

STATE="$1"
HOST="${CLAWD_HOST:-clawd.local}"

INPUT=$(cat)
MSG=$(printf '%s' "$INPUT" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | cut -c1-200)
CWD=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
PROJECT=$(basename "${CWD:-$PWD}")

# Wi-Fi
( curl -s -m 2 -o /dev/null -G "http://$HOST/cc" \
    --data-urlencode "state=$STATE" \
    --data-urlencode "msg=$MSG" \
    --data-urlencode "project=$PROJECT" & ) >/dev/null 2>&1

# USB: Clawd shows up as a serial port; write one line "state|project|message"
usb_ports() {
  if [ -n "$CLAWD_PORT" ]; then [ "$CLAWD_PORT" != none ] && echo "$CLAWD_PORT"; return; fi
  case "$(uname -s)" in
    Darwin) ls /dev/cu.usbmodem* 2>/dev/null ;;
    Linux)  ls /dev/serial/by-id/*[Ee]spressif* 2>/dev/null ;;
  esac
}
LINE=$(printf '%s|%s|%s' "$STATE" "$PROJECT" "$MSG" | tr '\n\r' '  ')
for p in $(usb_ports); do
  [ -w "$p" ] || continue
  ( { case "$(uname -s)" in Darwin) stty -f "$p" -hupcl ;; *) stty -F "$p" -hupcl ;; esac
      printf '%s\n' "$LINE" >> "$p"; } & ) >/dev/null 2>&1
done
exit 0
