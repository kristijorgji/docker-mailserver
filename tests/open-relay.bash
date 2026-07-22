#!/usr/bin/env bash
set -euo pipefail

RELAY_TO="${MAIL_TEST_RELAY_TO:-relay-test@example.org}"
FROM_ADDR="${MAIL_TEST_FROM:-attacker@example.org}"

echo "==> Checking open relay is blocked (unauthenticated relay to external domain)"

docker compose exec -T ms python3 - "$RELAY_TO" "$FROM_ADDR" <<'PY'
import socket
import subprocess
import sys

relay_to = sys.argv[1]
from_addr = sys.argv[2]
host = subprocess.check_output(["hostname", "-I"], text=True).split()[0]

sock = socket.create_connection((host, 25), timeout=15)

def smtp_cmd(command: str) -> str:
    sock.sendall((command + "\r\n").encode())
    data = b""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            break
        data += chunk
        lines = data.decode(errors="replace").split("\r\n")
        for line in reversed(lines):
            if len(line) >= 4 and line[3] == " ":
                return line
    return data.decode(errors="replace").strip()

print("HELO:", smtp_cmd("HELO relay-test.example.org"))
print("MAIL FROM:", smtp_cmd(f"MAIL FROM:<{from_addr}>"))
rcpt = smtp_cmd(f"RCPT TO:<{relay_to}>")
print("RCPT TO:", rcpt)
smtp_cmd("QUIT")
sock.close()

if rcpt.startswith("250"):
    print("FAIL: unauthenticated relay was accepted")
    sys.exit(1)
lower = rcpt.lower()
if any(token in lower for token in ("relay", "denied", "not permitted", "unauth", "554", "550", "530", "553", "450", "451")):
    print("Open relay correctly rejected")
    sys.exit(0)
print(f"FAIL: could not confirm relay rejection (response: {rcpt})")
sys.exit(1)
PY
