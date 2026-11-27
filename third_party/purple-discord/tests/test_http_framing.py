#!/usr/bin/env python3
"""Local HTTP framing regressions using the classifier called by http.c."""

import ctypes
import pathlib
import socketserver
import subprocess
import tempfile
import threading
import time
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
NONE, CHUNKED, CONTENT_LENGTH, CLOSE_DELIMITED = range(4)
KEEPALIVE_DELAY = 1.0


class FixtureHandler(socketserver.BaseRequestHandler):
    def handle(self):
        request = b""
        while b"\r\n\r\n" not in request:
            part = self.request.recv(4096)
            if not part:
                return
            request += part
        line = request.split(b"\r\n", 1)[0].decode("ascii")
        method, path, _ = line.split(" ", 2)

        if path == "/200":
            self.reply(b"HTTP/1.1 200 OK\r\nContent-Length: 8\r\nConnection: close\r\n\r\n{\"ok\":1}")
        elif path == "/204-keepalive":
            self.reply(b"HTTP/1.1 204 No Content\r\nConnection: keep-alive\r\n\r\n")
            time.sleep(KEEPALIVE_DELAY)
        elif path == "/204-close":
            self.reply(b"HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n")
        elif path == "/304-keepalive":
            self.reply(b"HTTP/1.1 304 Not Modified\r\nConnection: keep-alive\r\n\r\n")
            time.sleep(KEEPALIVE_DELAY)
        elif path == "/head" and method == "HEAD":
            self.reply(b"HTTP/1.1 200 OK\r\nContent-Length: 100\r\nConnection: keep-alive\r\n\r\n")
            time.sleep(KEEPALIVE_DELAY)
        elif path == "/chunked":
            self.reply(b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n3\r\nabc\r\n0\r\n\r\n")
        else:
            self.reply(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")

    def reply(self, data):
        self.request.sendall(data)


def read_response(sock, method, classifier):
    data = bytearray()
    while b"\r\n\r\n" not in data:
        data.extend(sock.recv(4096))
    header, body = bytes(data).split(b"\r\n\r\n", 1)
    lines = header.decode("ascii").split("\r\n")
    status = int(lines[0].split(" ")[1])
    headers = {}
    for line in lines[1:]:
        name, value = line.split(":", 1)
        headers[name.lower()] = value.strip()
    has_length = "content-length" in headers
    is_chunked = headers.get("transfer-encoding", "").lower() == "chunked"
    mode = classifier(method.encode("ascii"), status, has_length, is_chunked)

    if mode == NONE:
        return status, b"", mode
    if mode == CONTENT_LENGTH:
        expected = int(headers["content-length"])
        while len(body) < expected:
            body += sock.recv(expected - len(body))
        return status, body[:expected], mode
    if mode == CHUNKED:
        while b"\r\n0\r\n\r\n" not in body:
            body += sock.recv(4096)
        payload = bytearray()
        rest = body
        while True:
            size_end = rest.index(b"\r\n")
            size = int(rest[:size_end], 16)
            rest = rest[size_end + 2:]
            if size == 0:
                break
            payload.extend(rest[:size])
            rest = rest[size + 2:]
        return status, bytes(payload), mode

    while True:
        part = sock.recv(4096)
        if not part:
            return status, bytes(body), mode
        body.extend(part)


class HttpFramingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="purple-discord-http-test-")
        library = pathlib.Path(cls.temp.name) / "http-framing.so"
        subprocess.run([
            "cc", "-shared", "-fPIC", "-std=c99", "-Wall", "-Wextra",
            "-I", str(ROOT / "purple2compat"),
            str(ROOT / "purple2compat" / "http-framing.c"), "-o", str(library),
        ], check=True)
        cls.lib = ctypes.CDLL(str(library))
        cls.classify = cls.lib.purple_http_get_body_mode
        cls.classify.argtypes = [ctypes.c_char_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        cls.classify.restype = ctypes.c_int
        cls.server = socketserver.ThreadingTCPServer(("127.0.0.1", 0), FixtureHandler)
        cls.server.daemon_threads = True
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.temp.cleanup()

    def request(self, path, method="GET"):
        sock = socketserver.socket.socket()
        sock.settimeout(1.5)
        sock.connect(self.server.server_address)
        sock.sendall(f"{method} {path} HTTP/1.1\r\nHost: localhost\r\nConnection: keep-alive\r\n\r\n".encode("ascii"))
        started = time.monotonic()
        result = read_response(sock, method, self.classify)
        elapsed = time.monotonic() - started
        sock.close()
        return result, elapsed

    def test_content_length_json(self):
        (status, body, mode), _ = self.request("/200")
        self.assertEqual((status, body, mode), (200, b'{"ok":1}', CONTENT_LENGTH))

    def test_204_without_length_completes_while_connection_stays_open(self):
        (status, body, mode), elapsed = self.request("/204-keepalive")
        self.assertEqual((status, body, mode), (204, b"", NONE))
        self.assertLess(elapsed, KEEPALIVE_DELAY / 2)

    def test_204_with_connection_close(self):
        (status, body, mode), _ = self.request("/204-close")
        self.assertEqual((status, body, mode), (204, b"", NONE))

    def test_304_without_length_completes_while_connection_stays_open(self):
        (status, body, mode), elapsed = self.request("/304-keepalive")
        self.assertEqual((status, body, mode), (304, b"", NONE))
        self.assertLess(elapsed, KEEPALIVE_DELAY / 2)

    def test_head_content_length_has_no_body(self):
        (status, body, mode), elapsed = self.request("/head", "HEAD")
        self.assertEqual((status, body, mode), (200, b"", NONE))
        self.assertLess(elapsed, KEEPALIVE_DELAY / 2)

    def test_chunked_body(self):
        (status, body, mode), _ = self.request("/chunked")
        self.assertEqual((status, body, mode), (200, b"abc", CHUNKED))


if __name__ == "__main__":
    unittest.main()
