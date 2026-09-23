#!/usr/bin/env bash

###
#
# Starts the Hugo development server on the local network.
# Displays its address and its QR code if qrencode is available.
#
# Cross-platform: macOS, Linux and Windows (Git Bash / MSYS / MINGW).
#
# # USAGE
#   ./scripts/preview-mac.command (macOS)
#   scripts\preview-win.cmd    (Windows)
#
# # OPTIONS
#   --buildDrafts     Include content marked as draft.
#   --openBrowser     Open the preview in the default browser (default: on).
#   --port N          Prefer port N (default: 1313); the next free port is
#                     used automatically if N is already taken, scanning at
#                     most PORT_SCAN_LIMIT ports (default: 10).
#
# # DEPENDENCIES
#   Hugo
#   qrencode (optional, for the terminal QR code)
#
# # INSTALLATION — macOS
#   brew install hugo qrencode
#
# # INSTALLATION — UBUNTU
#   sudo apt install hugo qrencode
#
# # INSTALLATION — WINDOWS (Git Bash)
#   winget install Hugo.Hugo.Extended
#   winget install -e --id PedroAlbanese.QREncode
#
##

set -euo pipefail

os_name="$(uname -s 2>/dev/null || printf '%s' 'unknown')"

parse_arguments() {
    OPEN_BROWSER=true
    BUILD_DRAFTS=false
    PREFERRED_PORT="1313"
    PORT_SCAN_LIMIT="${PORT_SCAN_LIMIT:-10}"

    while (($# > 0)); do
        case "$1" in
            --buildDrafts)
                BUILD_DRAFTS=true
                ;;
            --openBrowser)
                OPEN_BROWSER=true
                ;;
            --port)
                PREFERRED_PORT="${2:-}"
                shift
                ;;
            *)
                printf 'Unknown option: %s\nAvailable options: --buildDrafts, --openBrowser, --port N\n' "$1" >&2
                exit 2
                ;;
        esac
        shift
    done

    if [ -z "$PREFERRED_PORT" ]; then
        printf 'Option --port requires a port number.\n' >&2
        exit 2
    fi
}

is_windows() {
    case "$os_name" in
        CYGWIN*|MINGW*|MSYS*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

resolve_preview_context() {
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
    HUGO_DIR="$PROJECT_DIR/.hugo"
    IP="$(bash "$SCRIPT_DIR/network_utils.sh" ip)"
    BASE_URL="http://$IP"
}

# Prints the first free port starting at PREFERRED_PORT, probed on the bind
# IP; at most PORT_SCAN_LIMIT ports are tested (network_utils.sh).
resolve_port() {
    PORT="$(bash "$SCRIPT_DIR/network_utils.sh" port "$1" "$PORT_SCAN_LIMIT" "$IP")"
}

# Locates a runnable Hugo: PATH first, then the WinGet package folder on
# Windows (where the PATH link may be broken).
resolve_hugo() {
    local candidate

    if command -v hugo >/dev/null 2>&1; then
        candidate="$(command -v hugo)"
        if "$candidate" version >/dev/null 2>&1; then
            HUGO_BIN="$candidate"
            return
        fi
        # The PATH entry may be a broken WinGet link; fall back to the
        # WinGet package folder below.
    fi

    if is_windows && [ -n "${LOCALAPPDATA:-}" ]; then
        while IFS= read -r candidate; do
            [ -n "$candidate" ] || continue
            [ -x "$candidate" ] || continue
            if "$candidate" version >/dev/null 2>&1; then
                HUGO_BIN="$candidate"
                return
            fi
        done <<< "$(find "$LOCALAPPDATA/Microsoft/WinGet/Packages" -iname 'hugo.exe' -type f 2>/dev/null || true)"
    fi

    printf 'Hugo executable not found or not runnable. Install Hugo Extended first.\n' >&2
    exit 1
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
    local full_url="$1"

    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t ANSI "$full_url"
    else
        printf '\n\n%s\n' '!!! INSTALL QRENCODE TO SEE THE QR CODE OF THE URL !!!'
    fi
    printf '\n\n%s\n' "$full_url"
    if [ "$PORT" != "$PREFERRED_PORT" ]; then
        printf 'Port %s unavailable, using %s.\n' "$PREFERRED_PORT" "$PORT"
    fi
    printf '\n'
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
        --appendPort=true              # Append ":port" to the served URLs.
        --watch                        # Watch the filesystem for changes and rebuild as needed.
    )

    cd "$PROJECT_DIR"
    if is_windows; then
        # Git Bash does not reliably terminate a native hugo.exe when its
        # terminal closes. A Windows job object ties Hugo to the launcher.
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File \
            "$(cygpath -w "$SCRIPT_DIR/preview-windows.ps1")" \
            "$(cygpath -w "$HUGO_BIN")" "$(cygpath -w "$PROJECT_DIR")" \
            server "${options[@]}"
    else
        exec "$HUGO_BIN" server "${options[@]}"
    fi
}

main() {
    parse_arguments "$@"
    resolve_preview_context
    resolve_port "$PREFERRED_PORT"
    resolve_hugo
    remove_generated_files
    display_preview_address "$BASE_URL:$PORT"
    start_hugo_server
}

main "$@"
