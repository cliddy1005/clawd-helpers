# Clawd helpers

Connect **Clawd**, a little desk companion with a touch screen, to **Claude Code** and **opencode**.
Clawd shows a status light while your coding agent works and flashes **"Claude needs you"** with a chime when it's waiting on you.

| Your agent | Clawd shows |
|---|---|
| Session starts | Blue light (idle) |
| Working (you sent a prompt, a tool ran) | Pulsing amber light |
| Asks permission or waits for your reply | "Claude needs you" alert and chime |
| Finished | Green light, done chime and a happy squish |

Full guides: [user guide](https://clawd.beerbot.uk) · [build guide](https://clawd.beerbot.uk/build)

## Install

On the computer that runs Claude Code (Mac or Linux):

```sh
curl -fsSL https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main/install.sh | sh
```

or from a clone:

```sh
git clone https://github.com/cliddy1005/clawd-helpers.git
cd clawd-helpers
./install.sh
```

The installer:

- copies `clawd-notify.sh` to `~/.claude/`
- adds five hooks to `~/.claude/settings.json`, keeping your other settings and a timestamped backup (it never adds a hook twice, and stops without changes if your settings file isn't valid JSON)
- installs the opencode plugin to `~/.config/opencode/plugins/` if opencode is on the computer

Restart Claude Code (and opencode) afterwards.

## Reaching Clawd

The helpers send every event two ways. Clawd ignores the duplicate when both arrive.

**Wi-Fi (recommended).** Put Clawd on your home Wi-Fi: join Clawd's own network `Clawd` (password `clawd1234`), open `http://192.168.4.1/setup` and enter your Wi-Fi details. Your computer then reaches it at `clawd.local`.
If `.local` names don't work on your network, swipe to Clawd's Info view for its IP address and set:

```sh
export CLAWD_HOST=192.168.1.42   # your Clawd's IP
```

**Bluetooth (no Wi-Fi needed).** Run the bridge and leave it open:

```sh
python3 -m pip install -r bluetooth/requirements.txt
python3 bluetooth/clawd-ble-bridge.py
```

Allow Bluetooth access when asked. Don't pair Clawd in your Bluetooth settings: it doesn't need pairing.

## Test

```sh
curl "http://clawd.local/cc?state=waiting&msg=Hello&project=test"      # Wi-Fi
curl "http://127.0.0.1:8765/cc?state=waiting&msg=Hello&project=test"    # Bluetooth bridge
```

Clawd flashes the alert and chimes; tap the screen to dismiss. Try `working`, `done` and `idle` too.

## What's in here

| Path | What it does |
|---|---|
| `install.sh` | One-step installer |
| `claude-code/clawd-notify.sh` | Hook script. Reads Claude Code's event JSON and sends state, message and project to Clawd, in the background with a 2-second timeout so it never slows Claude down |
| `claude-code/settings-snippet.json` | The hooks: `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Notification`, `Stop` |
| `claude-code/merge_hooks.py` | Safely merges the hooks into `settings.json` |
| `opencode/clawd.js` | opencode plugin (session, tool and permission events) |
| `bluetooth/clawd-ble-bridge.py` | Bluetooth LE bridge on `127.0.0.1:8765` |

### Clawd's HTTP API

`GET /cc?state=working|waiting|done|idle&msg=TEXT&project=NAME` on `clawd.local` (or the bridge).
Over Bluetooth, write `state|project|message` to characteristic `6c617764-636c-6177-6400-000000000002`
(service `6c617764-636c-6177-6400-000000000001`, device name `Clawd`).

## Windows

Claude Code runs hooks through Git Bash, so `clawd-notify.sh` works as-is: copy it to `%USERPROFILE%\.claude\` and add the hooks from `settings-snippet.json` to `%USERPROFILE%\.claude\settings.json`. Set `CLAWD_HOST` to Clawd's IP address.

---

Clawd is a fan-made desk companion based on [clawd-mochi](https://github.com/yousifamanuel/clawd-mochi). Not affiliated with or endorsed by Anthropic.
