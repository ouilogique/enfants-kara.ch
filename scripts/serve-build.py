#!/usr/bin/env python3

###
# Sert tous les builds de comparaison, un port par sous-dossier de builds/.
#
# Usage:
#   python3 scripts/serve-build.sh
##

import functools
import os
import subprocess
import sys
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BUILDS_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "builds"))

builds = sorted([e for e in os.scandir(BUILDS_DIR) if e.is_dir()], key=lambda e: e.name)

if not builds:
    print("Aucun build trouvé dans builds/")
    print("Lance d'abord : hugo --environment compare --gc --destination builds/<theme>")
    sys.exit(1)


class SilentHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def serve(directory, port):
    handler = functools.partial(SilentHandler, directory=directory)
    server = HTTPServer(("localhost", port), handler)
    server.serve_forever()


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
