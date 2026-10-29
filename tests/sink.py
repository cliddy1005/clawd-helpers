import http.server, sys, urllib.parse
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        q=urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        print(self.server.server_port, {k:v[0] for k,v in q.items()}, flush=True)
        self.send_response(200); self.end_headers(); self.wfile.write(b'{"ok":1}')
    def log_message(self,*a): pass
http.server.ThreadingHTTPServer(('127.0.0.1',int(sys.argv[1])),H).serve_forever()
