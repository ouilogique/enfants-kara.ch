#!/usr/bin/env bash

###
# Usage:
# bash scripts/hugo_preview.sh
#
# Windows Installation
# winget install Hugo.Hugo.Extended
# winget install -e --id PedroAlbanese.QREncode
##

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IP="$(bash "$SCRIPT_DIR/get_ip_of_default_interface.sh")"

rm -rf "$PROJECT_DIR/public"

PORT="1313"
BASE_URL="http://$IP"
FULL_URL="$BASE_URL:$PORT"

if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSI "$FULL_URL"
else
    echo -e "\n\nINSTALL QRENCODE TO SEE THE QR CODE OF THE URL."
fi

echo -e "\n\n$FULL_URL\n\n"

hugo server                 \
    --environment dev-local \
    --watch                 \
    -D                      \
    --gc                    \
    --disableFastRender     \
    --baseURL=$BASE_URL     \
    --bind=$IP              \
    --port=$PORT            \
    --appendPort=true       \
    --openBrowser
