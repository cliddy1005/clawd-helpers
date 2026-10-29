# Clawd helpers

Connect **Clawd**, a little desk companion with a touch screen, to **Claude Code** and **opencode**.
Clawd shows a status light while your coding agent works and flashes **"Claude needs you"** with a chime when it's waiting on you.
It works over **Wi-Fi** or simply **plugged into your computer by USB**, and nothing runs in the background: Claude Code or opencode fires the helper only when something happens.

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

With no options, the installer sets up whichever of Claude Code and opencode it finds on the computer. Choose explicitly with:

| Option | Installs |
|---|---|
| `--claude-code` | Claude Code hook only |
| `--opencode` | opencode plugin for all projects (`~/.config/opencode/plugins/`) |
| `--opencode-project` | opencode plugin for the current project only (`./.opencode/plugins/`) |
| `--all` | Both |

With the one-line install, pass options after `sh -s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/cliddy1005/clawd-helpers/main/install.sh | sh -s -- --opencode
```

For Claude Code, the installer copies `clawd-notify.sh` to `~/.claude/` and adds five hooks to `~/.claude/settings.json`, keeping your other settings and a timestamped backup. It never adds a hook twice, and stops without changes if your settings file isn't valid JSON. Running it again is safe.

Restart Claude Code or opencode afterwards.

## opencode

The plugin listens to opencode's events and drives the same light and alerts as Claude Code. opencode 2 changed its plugin format, so there are two versions and the installer picks the right one:

- `opencode/clawd.js`: opencode **2.x** (default export with `id` and `setup`, events from `ctx.event.subscribe`)
- `opencode/clawd-v1.js`: opencode **1.x** (the older hook-function format)

| opencode 2 event | Clawd shows |
|---|---|
| `session.created` | Blue light (idle) |
| `session.execution.started`, `session.tool.called` | Pulsing amber (working), sent at most every 5 seconds |
| `permission.asked` | "Claude needs you" alert with opencode's question |
| `permission.replied` | Amber (working) again |
| `session.execution.failed` | Alert, so you notice the error |
| `session.execution.succeeded` | Green light and done chime |
| `session.execution.interrupted` | Blue light (idle) |

To install by hand, copy the right file into `~/.config/opencode/plugins/clawd.js` (all projects) or `.opencode/plugins/clawd.js` in a project, then restart opencode. It uses the same `CLAWD_HOST` and `CLAWD_PORT` settings as the Claude Code hook.
opencode 2 keeps a background server running between sessions, and the plugin runs inside it. After installing or changing those settings, stop it with `pkill -f "opencode serve"` so it restarts with them.

## Reaching Clawd

The helpers send every event both ways. Clawd ignores the duplicate when both arrive, so you can use either or both.

**Plugged in by USB (no setup).** Plug Clawd into the computer that runs Claude Code or opencode with a USB-C data cable. The helpers find Clawd's USB port by themselves (`/dev/cu.usbmodem…` on a Mac, the Espressif device in `/dev/serial/by-id/` on Linux) and write one line per event.
If you have other USB dev boards plugged in, tell the helpers which port is Clawd, or turn USB off:

```sh
export CLAWD_PORT=/dev/cu.usbmodem101   # Clawd's port
export CLAWD_PORT=none                  # never use USB
```

**Wi-Fi.** Use this when Clawd sits away from the computer, powered by any charger. Put Clawd on your home Wi-Fi: join Clawd's own network `Clawd` (password `clawd1234`), open `http://192.168.4.1/setup` and enter your Wi-Fi details. Your computer then reaches it at `clawd.local`.
If `.local` names don't work on your network, swipe to Clawd's Info view for its IP address and set:

```sh
export CLAWD_HOST=192.168.1.42   # your Clawd's IP
```

## Test

```sh
curl "http://clawd.local/cc?state=waiting&msg=Hello&project=test"   # Wi-Fi
echo "waiting|test|Hello" >> /dev/cu.usbmodem101                     # USB (use your port)
```

Clawd flashes the alert and chimes; tap the screen to dismiss. Try `working`, `done` and `idle` too.
`tests/run.sh` checks both helpers without Clawd attached.

## What's in here

| Path | What it does |
|---|---|
| `install.sh` | One-step installer |
| `claude-code/clawd-notify.sh` | Hook script. Reads Claude Code's event JSON and sends state, message and project to Clawd over Wi-Fi and USB. Returns immediately, so it never slows Claude down |
| `claude-code/settings-snippet.json` | The hooks: `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Notification`, `Stop` |
| `claude-code/merge_hooks.py` | Safely merges the hooks into `settings.json` |
| `opencode/clawd.js` | opencode 2.x plugin (session, tool and permission events) |
| `opencode/clawd-v1.js` | Same for opencode 1.x |
| `tests/run.sh` | Runs both helpers against a stand-in Wi-Fi address and USB port and shows what Clawd would receive (needs Node and Python) |

### Talking to Clawd directly

- Wi-Fi: `GET http://clawd.local/cc?state=working|waiting|done|idle&msg=TEXT&project=NAME`
- USB: write a line `state|project|message` to Clawd's serial port (any baud rate). Also accepts `view:next`, `view:prev`.

## Windows

Claude Code runs hooks through Git Bash, so `clawd-notify.sh` works as-is: copy it to `%USERPROFILE%\.claude\` and add the hooks from `settings-snippet.json` to `%USERPROFILE%\.claude\settings.json`. Use Wi-Fi on Windows and set `CLAWD_HOST` to Clawd's IP address; the USB route is Mac and Linux only for now.

---

Clawd is a fan-made desk companion based on [clawd-mochi](https://github.com/yousifamanuel/clawd-mochi). Not affiliated with or endorsed by Anthropic.
