#!/bin/sh
# Installs the Clawd helpers for Claude Code and/or opencode.
#
#   ./install.sh                  install for whichever of Claude Code / opencode is on this computer
#   ./install.sh --claude-code    Claude Code only
#   ./install.sh --opencode       opencode only (global plugin, all projects)
#   ./install.sh --opencode-project   opencode plugin for the current project only (./.opencode/plugins)
#
# One line, no clone:
#   curl -fsSL https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main/install.sh | sh -s -- --opencode
set -e

REPO_RAW="https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main"
WANT_CC=""; WANT_OC=""; OC_PROJECT=""
for arg in "$@"; do
  case "$arg" in
    --claude-code)      WANT_CC=1 ;;
    --opencode)         WANT_OC=1 ;;
    --opencode-project) WANT_OC=1; OC_PROJECT=1 ;;
    --all)              WANT_CC=1; WANT_OC=1 ;;
    -h|--help)          sed -n '2,11p' "$0" 2>/dev/null || true; exit 0 ;;
    *) echo "Unknown option: $arg (use --claude-code, --opencode, --opencode-project or --all)"; exit 1 ;;
  esac
done
if [ -z "$WANT_CC$WANT_OC" ]; then
  # no option: detect what's installed; default to Claude Code if neither is found
  { command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; } && WANT_CC=1
  { command -v opencode >/dev/null 2>&1 || [ -d "$HOME/.config/opencode" ]; } && WANT_OC=1
  [ -z "$WANT_CC$WANT_OC" ] && WANT_CC=1
fi

SRC=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
TMP=""
if [ ! -f "$SRC/claude-code/clawd-notify.sh" ]; then
  # running through curl | sh: fetch the files we need
  TMP=$(mktemp -d); SRC="$TMP"
  mkdir -p "$SRC/claude-code" "$SRC/opencode"
  for f in claude-code/clawd-notify.sh claude-code/settings-snippet.json claude-code/merge_hooks.py opencode/clawd.js opencode/clawd-v1.js; do
    curl -fsSL "$REPO_RAW/$f" -o "$SRC/$f"
  done
fi

if [ -n "$WANT_CC" ]; then
  command -v python3 >/dev/null 2>&1 || { echo "python3 is needed to update Claude Code's settings. Install it, then run this again."; exit 1; }
  echo "Claude Code: installing the Clawd hook..."
  mkdir -p "$HOME/.claude"
  cp "$SRC/claude-code/clawd-notify.sh" "$HOME/.claude/clawd-notify.sh"
  chmod +x "$HOME/.claude/clawd-notify.sh"
  python3 "$SRC/claude-code/merge_hooks.py" "$HOME/.claude/settings.json" "$SRC/claude-code/settings-snippet.json"
fi

if [ -n "$WANT_OC" ]; then
  if [ -n "$OC_PROJECT" ]; then DEST="$PWD/.opencode/plugins"; else DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins"; fi
  # opencode 2.x changed the plugin format; 1.x needs the legacy plugin
  PLUGIN="clawd.js"
  case "$(opencode --version 2>/dev/null | sed 's/^[^0-9]*//')" in 1.*) PLUGIN="clawd-v1.js" ;; esac
  echo "opencode: installing the Clawd plugin ($PLUGIN) to $DEST"
  mkdir -p "$DEST"
  cp "$SRC/opencode/$PLUGIN" "$DEST/clawd.js"
fi

[ -n "$TMP" ] && rm -rf "$TMP"

echo
[ -n "$WANT_CC" ] && echo "Restart Claude Code to load the hook."
[ -n "$WANT_OC" ] && echo "Restart opencode to load the plugin (opencode 2 keeps a background server: run 'pkill -f \"opencode serve\"' if it's already running)."
echo "Test it:  curl \"http://clawd.local/cc?state=waiting&msg=Hello&project=test\""
