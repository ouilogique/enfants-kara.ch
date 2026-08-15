#!/usr/bin/env bash

###
#
# Starts the Hugo development server on the local network.
# Displays its address and its QR code if qrencode is available.
#
# # USAGE
#   bash scripts/preview.sh
#
# # OPTIONS
#   --openBrowser     Open the preview in the default browser.
#   --buildDrafts     Include content marked as draft.
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

parse_arguments() {
    OPEN_BROWSER=false
    BUILD_DRAFTS=false

    while (($# > 0)); do
        case "$1" in
            --buildDrafts)
                BUILD_DRAFTS=true
                ;;
            --openBrowser)
                OPEN_BROWSER=true
                ;;
            *)
                printf 'Unknown option: %s\nAvailable options: --buildDrafts, --openBrowser\n' "$1" >&2
                exit 2
                ;;
        esac
        shift
    done
}

resolve_preview_context() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    HUGO_DIR="$PROJECT_DIR/.hugo"
    IP="$(bash "$SCRIPT_DIR/get_ip_of_default_interface.sh")"
    PORT="1313"
    BASE_URL="http://$IP"
    FULL_URL="$BASE_URL:$PORT"
}

remove_generated_files() {
    # On macOS, Finder may recreate a .DS_Store file after rm has emptied
    # the directory but before rm removes it, causing a temporary race condition.
    # Retry the removal to handle this case.
    local i
    for ((i = 1; i <= 10; i++)); do
        if rm -rf "$HUGO_DIR"; then break; fi
        sleep 0.1
    done

    if [[ -e "$HUGO_DIR" ]]; then
        printf 'Warning: unable to fully delete %s before starting Hugo.\n' "$HUGO_DIR" >&2
    fi
}

display_preview_address() {
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t ANSI "$FULL_URL"
    else
        printf '\n\n%s\n' '!!! INSTALL QRENCODE TO SEE THE QR CODE OF THE URL !!!'
    fi
    printf '\n\n%s\n\n\n' "$FULL_URL"
}

start_hugo_server() {
    local options=(
        --baseURL="$BASE_URL"          # Set the base URL used by the development server.
        --bind="$IP"                   # Bind the server to the local network interface.
        --buildDrafts="$BUILD_DRAFTS"  # Include content marked as draft when requested.
        --disableFastRender            # Fully rerender the site after each change.
        --gc                           # Run cleanup tasks after each build.
        --openBrowser="$OPEN_BROWSER"  # Open the preview in the default browser when requested.
        --port="$PORT"                 # Listen on the selected TCP port.
        --watch                        # Watch the filesystem for changes and rebuild as needed.
    )

    cd "$PROJECT_DIR"
    hugo server "${options[@]}"
}

main() {
    parse_arguments "$@"
    resolve_preview_context
    remove_generated_files
    display_preview_address
    start_hugo_server
}

main "$@"
