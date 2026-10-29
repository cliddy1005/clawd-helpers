// Feeds opencode-style events to the Clawd plugin. A local server stands in for Clawd's Wi-Fi
// address and a plain file stands in for its USB port, so you can see what Clawd would receive.
process.env.CLAWD_HOST = "127.0.0.1:18080"
process.env.CLAWD_PORT = process.env.CLAWD_TEST_USB || "/tmp/clawd-usb-test.txt"
const { ClawdPlugin } = await import(new URL("../opencode/clawd.js", import.meta.url))
const hooks = await ClawdPlugin({ directory: "/Users/x/code/my-app", project: {}, client: {}, $: null, worktree: "" })
const sleep = ms => new Promise(r => setTimeout(r, ms))
const ev = async (type, properties = {}) => { await hooks.event({ event: { type, properties } }); await sleep(150) }
await ev("session.created")
await ev("session.status", { status: { type: "busy" } })
await hooks["tool.execute.before"]({ tool: "bash" }, {}); await sleep(150)
await hooks["tool.execute.before"]({ tool: "read" }, {}); await sleep(150)   // throttled: no second "working"
await ev("permission.asked", { title: "Run npm install?" })
await ev("permission.replied")
await ev("session.idle")
await ev("message.updated")                                                  // ignored
await sleep(500)
