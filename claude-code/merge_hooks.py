#!/usr/bin/env python3
"""Merge the Clawd hooks into a Claude Code settings.json without touching anything else.

Usage: merge_hooks.py SETTINGS_JSON SNIPPET_JSON
Keeps a timestamped backup, never duplicates a hook, and stops without changes
if the existing settings file isn't valid JSON.
"""
import json, os, shutil, sys, time

settings_path, snippet_path = sys.argv[1], sys.argv[2]
snippet = json.load(open(snippet_path))

settings = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path) as f:
            text = f.read().strip()
        settings = json.loads(text) if text else {}
    except json.JSONDecodeError as e:
        sys.exit(f"Your {settings_path} isn't valid JSON ({e}). Fix it, then run the installer again. Nothing was changed.")
    backup = f"{settings_path}.before-clawd-{time.strftime('%Y%m%d-%H%M%S')}"
    shutil.copy2(settings_path, backup)
    print(f"Backed up your settings to {backup}")

hooks = settings.setdefault("hooks", {})
added = 0
for event, entries in snippet["hooks"].items():
    current = hooks.setdefault(event, [])
    existing = {h.get("command") for e in current for h in e.get("hooks", [])}
    for entry in entries:
        if all(h["command"] in existing for h in entry["hooks"]):
            continue
        current.append(entry)
        added += 1

os.makedirs(os.path.dirname(settings_path) or ".", exist_ok=True)
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
print(f"Added {added} Clawd hook(s) to {settings_path}" if added else "Clawd hooks were already installed")
