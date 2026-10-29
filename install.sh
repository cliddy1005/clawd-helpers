#!/bin/sh
# Installs the Clawd helpers on the computer that runs Claude Code (and opencode, if you use it).
# Run from a clone:   ./install.sh
# Or in one line:     curl -fsSL https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main/install.sh | sh
set -e

REPO_RAW="https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main"
SRC=$(cd "$(dirname "$0")" 2>/dev/null && pwd)
TMP=""
if [ ! -f "$SRC/claude-code/clawd-notify.sh" ]; then
  # running through curl | sh: fetch the files we need
  TMP=$(mktemp -d)
  SRC="$TMP"
  mkdir -p "$SRC/claude-code" "$SRC/opencode"
  for f in claude-code/clawd-notify.sh claude-code/settings-snippet.json claude-code/merge_hooks.py opencode/clawd.js; do
    curl -fsSL "$REPO_RAW/$f" -o "$SRC/$f"
  done
fi

command -v python3 >/dev/null 2>&1 || { echo "python3 is needed to update Claude Code's settings. Install it, then run this again."; exit 1; }

echo "Installing the Claude Code hook..."
mkdir -p "$HOME/.claude"
cp "$SRC/claude-code/clawd-notify.sh" "$HOME/.claude/clawd-notify.sh"
chmod +x "$HOME/.claude/clawd-notify.sh"
python3 "$SRC/claude-code/merge_hooks.py" "$HOME/.claude/settings.json" "$SRC/claude-code/settings-snippet.json"

if command -v opencode >/dev/null 2>&1 || [ -d "$HOME/.config/opencode" ]; then
  echo "Installing the opencode plugin..."
  mkdir -p "$HOME/.config/opencode/plugins"
  cp "$SRC/opencode/clawd.js" "$HOME/.config/opencode/plugins/clawd.js"
fi

[ -n "$TMP" ] && rm -rf "$TMP"

echo
echo "Done. Restart Claude Code (and opencode) to load the helpers."
echo "Test it:  curl \"http://clawd.local/cc?state=waiting&msg=Hello&project=test\""
