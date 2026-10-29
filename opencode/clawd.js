// Clawd plugin for opencode
// Install for all projects:  ./install.sh --opencode   (copies this file to ~/.config/opencode/plugins/)
// Install for one project:   ./install.sh --opencode-project   (copies it to ./.opencode/plugins/)
// Restart opencode afterwards.
//
// Sends status to Clawd over Wi-Fi (clawd.local) and the Bluetooth bridge (127.0.0.1:8765):
//   session.created            -> idle
//   session.status busy, tools -> working   (at most every 5 s)
//   permission.asked           -> waiting   ("Claude needs you" alert with opencode's question)
//   permission.replied         -> working
//   session.error              -> waiting   (so you notice)
//   session.idle               -> done
const TARGETS = [process.env.CLAWD_HOST || "clawd.local", process.env.CLAWD_BRIDGE || "127.0.0.1:8765"]

let last = { state: "", at: 0 }
function send(state, msg = "", project = "") {
  // tools fire constantly while working; send "working" at most every 5 s
  const now = Date.now()
  if (state === last.state && state === "working" && now - last.at < 5000) return
  last = { state, at: now }
  const q = new URLSearchParams({ state, msg: String(msg).slice(0, 200), project })
  for (const host of TARGETS) {
    fetch(`http://${host}/cc?${q}`, { signal: AbortSignal.timeout(2000) }).catch(() => {})
  }
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
