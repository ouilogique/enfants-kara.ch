#!/usr/bin/env bash

## @file hugo_preview.sh
## @brief Starts a local Hugo preview server and prints a QR code for the URL.
##
## Usage:
## `bash scripts/hugo_preview.sh`
##
## Windows installation:
## `winget install Hugo.Hugo.Extended`
## `winget install -e --id PedroAlbanese.QREncode`

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IP="$(bash "$SCRIPT_DIR/get_ip_of_default_interface.sh")"

# Retry deleting the output directory because macOS Finder can briefly recreate
# .DS_Store files while the directory is being removed.
for ((i = 1; i <= 10; i++)); do
    if rm -rf "$PROJECT_DIR/public"; then
        break
    fi
    sleep 0.1
done

if [[ -e "$PROJECT_DIR/public" ]]; then
    echo "Warning: unable to fully delete $PROJECT_DIR/public before starting Hugo."
fi

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
