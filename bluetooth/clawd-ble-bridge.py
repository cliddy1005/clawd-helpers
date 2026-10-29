#!/usr/bin/env python3
"""Clawd Bluetooth bridge.

Keeps a Bluetooth LE link to Clawd and accepts the same requests as Clawd's
Wi-Fi address on http://127.0.0.1:8765, e.g.
    curl "http://127.0.0.1:8765/cc?state=waiting&msg=Hello&project=demo"
The Claude Code hook script and the opencode plugin send to this bridge
automatically, so Clawd works with or without Wi-Fi.

Setup:  python3 -m pip install bleak
Run:    python3 clawd-ble-bridge.py        (leave it running; macOS asks for Bluetooth access once)
"""
import asyncio, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

from bleak import BleakClient, BleakScanner

NAME = "Clawd"
SERVICE = "6c617764-636c-6177-6400-000000000001"
COMMAND = "6c617764-636c-6177-6400-000000000002"
PORT = 8765

loop = asyncio.new_event_loop()
queue: "asyncio.Queue[str]" = asyncio.Queue()


async def ble_worker():
    client = None
    while True:
        cmd = await queue.get()
        for attempt in range(2):
            try:
                if client is None or not client.is_connected:
                    print("Looking for Clawd over Bluetooth...")
                    dev = await BleakScanner.find_device_by_filter(
                        lambda d, ad: (d.name == NAME) or (SERVICE in (ad.service_uuids or [])), timeout=8)
                    if dev is None:
                        print("Clawd not found (is it powered on and nearby?)")
                        break
                    client = BleakClient(dev)
                    await client.connect()
                    print("Connected to", dev.name or dev.address)
                await client.write_gatt_char(COMMAND, cmd.encode()[:250], response=False)
                print("sent:", cmd[:80])
                break
            except Exception as e:  # dropped link: reconnect once
                print("Bluetooth error:", e)
                client = None


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(url.query).items()}
        if url.path == "/cc" and q.get("state") in ("working", "waiting", "done", "idle"):
            cmd = f'{q["state"]}|{q.get("project", "")}|{q.get("msg", "").replace("|", "/")}'
        elif url.path == "/birthday":
            cmd = "birthday"
        elif url.path == "/view":
            cmd = "view:prev" if q.get("dir") == "-1" else "view:next"
        else:
            self.send_response(400); self.end_headers(); return
        loop.call_soon_threadsafe(queue.put_nowait, cmd)
        self.send_response(200); self.send_header("Content-Type", "application/json"); self.end_headers()
        self.wfile.write(b'{"ok":1}')

    def log_message(self, *args):
        pass


def main():
    threading.Thread(target=lambda: ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever(),
                     daemon=True).start()
    print(f"Clawd Bluetooth bridge listening on http://127.0.0.1:{PORT}")
    asyncio.set_event_loop(loop)
    loop.run_until_complete(ble_worker())


if __name__ == "__main__":
    main()
