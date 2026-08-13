#!/usr/bin/env python3

###
# Sert tous les builds de comparaison, un port par sous-dossier de builds/.
# Avec --build : rebuilde tous les thèmes (toute branche != hugo) avant de servir.
#
# Usage:
#   python3 scripts/maintenance/compare_themes.py           # sert uniquement
#   python3 scripts/maintenance/compare_themes.py --build   # rebuilde puis sert
##

import functools
import os
import subprocess
import sys
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
BUILDS_DIR = os.path.join(PROJECT_DIR, "builds")


def run(cmd, **kwargs):
    subprocess.run(cmd, check=True, cwd=PROJECT_DIR, **kwargs)


def build_themes():
    result = subprocess.run(
        ["git", "branch", "--format=%(refname:short)"],
        capture_output=True, text=True, cwd=PROJECT_DIR, check=True
    )
    branches = [b.strip() for b in result.stdout.splitlines() if b.strip()]
    theme_branches = [
        b for b in branches
        if os.path.isdir(os.path.join(PROJECT_DIR, "themes", b))
    ]

    current = subprocess.run(
        ["git", "branch", "--show-current"],
        capture_output=True, text=True, cwd=PROJECT_DIR, check=True
    ).stdout.strip()

    for branch in sorted(theme_branches):
        print(f"\n── Build : {branch}")
        run(["git", "checkout", branch])
        run(["hugo", "--environment", "compare", "--gc",
             "--destination", f"builds/{branch}"])

    run(["git", "checkout", current])


# --- Kill old instances ---
import signal
result = subprocess.run(
    ["pgrep", "-f", "compare_themes.py"],
    capture_output=True, text=True
)
for pid in result.stdout.splitlines():
    pid = int(pid.strip())
    if pid != os.getpid():
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass

# --- Build ---
if "--build" in sys.argv:
    build_themes()

# --- Serve ---
if not os.path.isdir(BUILDS_DIR) or not any(
    e.is_dir() for e in os.scandir(BUILDS_DIR)
):
    print("Aucun build trouvé dans builds/")
    print("Lance d'abord : python3 scripts/maintenance/compare_themes.py --build")
    sys.exit(1)

builds = sorted([e for e in os.scandir(BUILDS_DIR) if e.is_dir()], key=lambda e: e.name)


class SilentHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def serve(directory, port):
    handler = functools.partial(SilentHandler, directory=directory)
    server = HTTPServer(("localhost", port), handler)
    server.serve_forever()


print()
for i, entry in enumerate(builds):
    port = 8080 + i
    url = f"http://localhost:{port}"
    print(f"  {entry.name:<20} → {url}")
    threading.Thread(target=serve, args=(entry.path, port), daemon=True).start()
    subprocess.Popen(["open", url])

print("\nCtrl+C pour arrêter\n")
try:
    threading.Event().wait()
except KeyboardInterrupt:
    pass
