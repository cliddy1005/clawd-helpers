// Clawd plugin for opencode 2.x
// Install for all projects:  ./install.sh --opencode   (copies this file to ~/.config/opencode/plugins/)
// Install for one project:   ./install.sh --opencode-project   (copies it to ./.opencode/plugins/)
// Restart opencode afterwards. (opencode 1.x needs clawd-v1.js; the installer picks the right one.)
//
// Sends status to Clawd over Wi-Fi (clawd.local) and, when Clawd is plugged into this computer, over USB:
//   session.created                     -> idle
//   session.execution.started, tools    -> working   (at most every 5 s)
//   permission.asked                    -> waiting   ("Claude needs you" alert with opencode's question)
//   permission.replied                  -> working
//   session.execution.failed            -> waiting   (so you notice)
//   session.execution.succeeded         -> done
//   session.execution.interrupted       -> idle
// Optional settings: CLAWD_HOST (Clawd's IP), CLAWD_PORT (USB port, or "none").
// opencode keeps a background server running; restart it after changing these settings.
import { readdirSync, existsSync } from "node:fs"
import { appendFile } from "node:fs/promises"
import { basename } from "node:path"

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
export function send(state, msg = "", project = "") {
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

// opencode 2 permission requests carry { action: "shell", resources: ["npm install"] }
function permissionText(p) {
  const what = (p.resources || []).join(", ")
  if (p.action === "shell" && what) return "Run: " + what
  if (p.action && what) return p.action + ": " + what
  return p.title || p.message || p.action || "opencode needs your permission"
}

export function handle(event, fallbackProject) {
  const p = event.properties ?? event.data ?? event
  const project = basename(event.location?.directory || "") || fallbackProject
  switch (event.type) {
    case "session.created":               return send("idle", "", project)
    case "session.execution.started":
    case "session.tool.called":           return send("working", "", project)
    case "permission.asked":              return send("waiting", permissionText(p), project)
    case "permission.replied":            return send("working", "", project)
    case "session.execution.failed":
    case "session.error":                 return send("waiting", "opencode hit an error" + (p.error?.message ? ": " + p.error.message : ""), project)
    case "session.execution.succeeded":
    case "session.idle":                  return send("done", "opencode finished", project)
    case "session.execution.interrupted": return send("idle", "", project)
  }
}

export default {
  id: "clawd",
  async setup(ctx) {
    const dir = ctx.location?.project?.directory || ctx.location?.directory || ""
    const project = basename(dir) || "opencode"
    const stop = new AbortController()
    ;(async () => {
      try {
        for await (const event of ctx.event.subscribe({ signal: stop.signal })) handle(event, project)
      } catch {}
    })()
    return () => stop.abort()
  },
}
