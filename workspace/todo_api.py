"""Minimal TODO API -- test target for Cline + Ollama refactoring tasks."""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json

todos = []
next_id = 1


class TodoHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(todos).encode())

    def do_POST(self):
        global next_id
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length))
        todo = {"id": next_id, "title": body.get("title", ""), "done": False}
        todos.append(todo)
        next_id += 1
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(todo).encode())


if __name__ == "__main__":
    server = HTTPServer(("localhost", 8080), TodoHandler)
    print("TODO server running on http://localhost:8080")
    server.serve_forever()
