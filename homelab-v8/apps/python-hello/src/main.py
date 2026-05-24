import os
import json
import socket
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
            return

        body = json.dumps({
            "message": "Hello from Python! v2",
            "version": os.getenv("APP_VERSION", "dev"),
            "runtime": f"Python {sys.version.split()[0]}",
            "hostname": socket.gethostname(),
        }).encode()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    server = HTTPServer(("", port), Handler)
    print(f"Listening on http://0.0.0.0:{port}")
    server.serve_forever()
