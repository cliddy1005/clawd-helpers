// Feeds opencode 2 events to the Clawd plugin through a stand-in plugin context. A local server
// stands in for Clawd's Wi-Fi address and a plain file for its USB port.
process.env.CLAWD_HOST = "127.0.0.1:18080"
process.env.CLAWD_PORT = process.env.CLAWD_TEST_USB || "/tmp/clawd-usb-test.txt"
const plugin = (await import(new URL("../opencode/clawd.js", import.meta.url))).default
const sleep = ms => new Promise(r => setTimeout(r, ms))
const events = [
  { type: "session.created", properties: {} },
  { type: "session.execution.started", properties: {} },
  { type: "session.tool.called", properties: { tool: "read" } },          // throttled: no second "working"
  { type: "permission.asked", data: { title: "Run npm install?" } },     // payload under "data" also handled
  { type: "permission.replied", properties: { reply: "once" } },
  { type: "session.execution.succeeded", properties: {} },
  { type: "session.text.delta", properties: {} },                        // ignored
]
const ctx = {
  location: { directory: "/Users/x/code/my-app", project: { directory: "/Users/x/code/my-app" } },
  event: { async *subscribe({ signal }) { for (const e of events) { if (signal.aborted) return; await sleep(150); yield e } } },
}
if (plugin.id !== "clawd" || typeof plugin.setup !== "function") throw new Error("not an opencode 2 plugin definition")
const cleanup = await plugin.setup(ctx)
await sleep(events.length * 150 + 600)
cleanup()
