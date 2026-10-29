// Clawd plugin for opencode
// Install for all projects:  ./install.sh --opencode   (copies this file to ~/.config/opencode/plugins/)
// Install for one project:   ./install.sh --opencode-project   (copies it to ./.opencode/plugins/)
// Restart opencode afterwards.
//
// Sends status to Clawd over Wi-Fi (clawd.local) and, when Clawd is plugged into this computer, over USB:
//   session.created            -> idle
//   session.status busy, tools -> working   (at most every 5 s)
//   permission.asked           -> waiting   ("Claude needs you" alert with opencode's question)
//   permission.replied         -> working
//   session.error              -> waiting   (so you notice)
//   session.idle               -> done
// Optional settings: CLAWD_HOST (Clawd's IP), CLAWD_PORT (USB port, or "none").
import { readdirSync, existsSync } from "node:fs"
import { appendFile } from "node:fs/promises"

const HOST = process.env.CLAWD_HOST || "clawd.local"

function usbPorts() {
  const forced = process.env.CLAWD_PORT
  if (forced) return forced === "none" ? [] : [forced]
  try {
    if (process.platform === "darwin")
      return readdirSync("/dev").filter(n => n.startsWith("cu.usbmodem")).map(n => "/dev/" + n)
    if (process.platform === "linux" && existsSync("/dev/serial/by-id"))
      return readdirSync("/dev/serial/by-id").filter(n => /espressif/i.test(n)).map(n => "/dev/serial/by-id/" + n)
  } catch {}
  return []
}

let last = { state: "", at: 0 }
function send(state, msg = "", project = "") {
  // tools fire constantly while working; send "working" at most every 5 s
  const now = Date.now()
  if (state === last.state && state === "working" && now - last.at < 5000) return
  last = { state, at: now }
  msg = String(msg).slice(0, 200)
  const q = new URLSearchParams({ state, msg, project })
  fetch(`http://${HOST}/cc?${q}`, { signal: AbortSignal.timeout(2000) }).catch(() => {})
  const line = `${state}|${project}|${msg}`.replace(/[\r\n]+/g, " ") + "\n"
  for (const port of usbPorts()) appendFile(port, line).catch(() => {})
}

export const ClawdPlugin = async ({ directory }) => {
  const project = (directory || "").split("/").filter(Boolean).pop() || "opencode"
  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.created":    send("idle", "", project); break
        case "session.idle":       send("done", "opencode finished", project); break
        case "permission.asked":   send("waiting", event.properties?.title || "opencode needs your permission", project); break
        case "permission.replied": send("working", "", project); break
        case "session.error":      send("waiting", "opencode hit an error" + (event.properties?.error?.message ? ": " + event.properties.error.message : ""), project); break
        case "session.status":
          if (event.properties?.status?.type === "busy") send("working", "", project)
          break
      }
    },
    "tool.execute.before": async () => send("working", "", project),
  }
}
