#!/usr/bin/env bash

###
#
# Starts the Hugo development server on the local network.
# Displays its address and its QR code if qrencode is available.
#
# # USAGE
#   bash scripts/preview.sh [--openBrowser]
#
# # OPTIONS
#   --openBrowser  Opens the preview in the default browser.
#
# # DEPENDENCIES
#   Hugo
#   qrencode
#
# # INSTALLATION — macOS
#   brew install hugo qrencode
#
# # INSTALLATION — UBUNTU
#   sudo apt install hugo qrencode
#
# # INSTALLATION — WINDOWS
#   winget install Hugo.Hugo.Extended
#   winget install -e --id PedroAlbanese.QREncode
#
##

set -euo pipefail

OPEN_BROWSER=false

while (($# > 0)); do
    case "$1" in
        --openBrowser)
            OPEN_BROWSER=true
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HUGO_DIR="$PROJECT_DIR/.hugo"
IP="$(bash "$SCRIPT_DIR/get_ip_of_default_interface.sh")"
PORT="1313"
BASE_URL="http://$IP"
FULL_URL="$BASE_URL:$PORT"

# Retry because macOS Finder can briefly recreate .DS_Store files while the
# generated directory is being removed.
for ((i = 1; i <= 10; i++)); do
    if rm -rf "$HUGO_DIR"; then
        break
    fi
    sleep 0.1
done

if [[ -e "$HUGO_DIR" ]]; then
    printf 'Warning: unable to fully delete %s before starting Hugo.\n' "$HUGO_DIR" >&2
fi

if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSI "$FULL_URL"
else
    printf '\n\n%s\n' '!!! INSTALL QRENCODE TO SEE THE QR CODE OF THE URL !!!'
fi

printf '\n\n%s\n\n\n' "$FULL_URL"

OPTIONS=(
    --watch
    --gc  #  Run some cleanup tasks after the build.
    --buildDrafts
    --disableFastRender
    --baseURL "$BASE_URL"
    --bind "$IP"
    --port "$PORT"
)

if [[ "$OPEN_BROWSER" == true ]]; then
    OPTIONS+=(--openBrowser)
fi

hugo server "${OPTIONS[@]}"
