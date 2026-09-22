#!/usr/bin/env bash

###
#
# Network helpers used by preview.sh.
#
# Cross-platform: macOS, Linux and Windows (Git Bash / MSYS / MINGW).
#
# # USAGE
#   ./scripts/network_utils.sh            Print the default interface IP.
#   ./scripts/network_utils.sh ip         Same as above.
#   ./scripts/network_utils.sh port N [n] Print the first free port starting
#                                         at N, probing at most n ports
#                                         (n defaults to 10). The probe is
#                                         done against 127.0.0.1 by default.
#   ./scripts/network_utils.sh port N n IP
#                                         Same, probing the given IP address
#                                         (used when the server binds to a
#                                         specific interface). Fails when no
#                                         free port is found.
#
##

set -euo pipefail

os_name="$(uname -s 2>/dev/null || printf '%s' 'unknown')"

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

function getIPofDefaultInterfaceMacOS()
{
    local default_interface
    local ip_address

    default_interface="$(route -n get 0.0.0.0 2>/dev/null | awk '/interface: / {print $2}' || true)"
    if [ -n "$default_interface" ]; then
        ip_address="$(ipconfig getifaddr "$default_interface" 2>/dev/null || true)"
        printf '%s\n' "${ip_address:-0.0.0.0}"
    else
        printf '%s\n' '0.0.0.0'
    fi
}

function getIPofDefaultInterfaceLinux()
{
    local ip_address

    ip_address="$(hostname -I 2>/dev/null | awk '{print $1}')"
    printf '%s\n' "${ip_address:-0.0.0.0}"
}

function getIPofDefaultInterfaceWindows()
{
    local ip_address

    if command -v powershell.exe >/dev/null 2>&1; then
        ip_address="$(
            powershell.exe -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { \$_.IPv4DefaultGateway -ne \$null -and \$_.IPv4Address -ne \$null } | Select-Object -First 1 -ExpandProperty IPv4Address).IPAddress" 2>/dev/null | tr -d '\r'
        )"
    fi

    if [ -z "${ip_address:-}" ] && command -v ipconfig.exe >/dev/null 2>&1; then
        ip_address="$(
            ipconfig.exe 2>/dev/null | awk -F': ' '/IPv4 Address|Adresse IPv4/ {print $2; exit}' | tr -d '\r'
        )"
    fi

    printf '%s\n' "${ip_address:-0.0.0.0}"
}

function getIPofDefaultInterface()
{
  case "$os_name" in
    Darwin)
      getIPofDefaultInterfaceMacOS
      ;;
    Linux)
      getIPofDefaultInterfaceLinux
      ;;
    CYGWIN*|MINGW*|MSYS*)
      getIPofDefaultInterfaceWindows
      ;;
    *)
      return 1
      ;;
  esac
}

# Returns 0 when the port is free, 1 when it is in use. The port is probed on
# PROBE_HOST (default 127.0.0.1): the server under test binds to a specific
# interface IP, so probing 127.0.0.1 would miss a server listening only on
# that interface (e.g. the LAN IP).
test_port_available() {
    local candidate_port="$1"
    local probe_host="${2:-127.0.0.1}"
    local probe_ip="$probe_host"

    # 0.0.0.0 means "listen on every interface": probe the loopback instead.
    if [ "$probe_ip" = "0.0.0.0" ]; then
        probe_ip="127.0.0.1"
    fi

    if is_windows; then
        # Git Bash cannot rely on /dev/tcp: use Windows PowerShell's TcpListener.
        if command -v powershell.exe >/dev/null 2>&1; then
            if powershell.exe -NoProfile -Command "try { \$l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse(\"$probe_ip\"), $candidate_port); \$l.Start(); \$l.Stop(); exit 0 } catch { exit 1 }" >/dev/null 2>&1; then
                return 0
            fi
            return 1
        fi
        # Cannot test: assume the port is free.
        return 0
    fi

    # macOS/Linux: use bash's /dev/tcp. If unsupported, assume the port is free.
    if (exec 3<>"/dev/tcp/$probe_ip/$candidate_port") 2>/dev/null; then
        return 1
    fi
    return 0
}

# Prints the first free port starting at PREFERRED_PORT, probing at most
# SCAN_LIMIT ports on PROBE_HOST (default 127.0.0.1). Exits with an error
# when none is free.
find_free_port() {
    local preferred_port="$1"
    local scan_limit="${2:-10}"
    local probe_host="${3:-127.0.0.1}"
    local candidate_port="$preferred_port"

    case "$preferred_port" in
        ''|*[!0-9]*)
            printf 'Invalid port: %s\n' "$preferred_port" >&2
            return 2
            ;;
    esac
    local end_port=$((preferred_port + scan_limit - 1))

    while [ "$candidate_port" -le "$end_port" ]; do
        if test_port_available "$candidate_port" "$probe_host"; then
            printf '%s\n' "$candidate_port"
            return 0
        fi
        candidate_port=$((candidate_port + 1))
    done

    local host_suffix=""
    if [ "$probe_host" != "127.0.0.1" ]; then
        host_suffix=" on $probe_host"
    fi
    printf 'No free port found between %s and %s%s.\n' "$preferred_port" "$end_port" "$host_suffix" >&2
    return 1
}

case "${1:-ip}" in
    ip)
        getIPofDefaultInterface
        ;;
    port)
        if [ -z "${2:-}" ]; then
            printf 'Usage: %s port <preferred_port> [scan_limit] [host]\n' "$0" >&2
            exit 2
        fi
        find_free_port "$2" "${3:-10}" "${4:-127.0.0.1}"
        ;;
    *)
        printf 'Unknown option: %s\nUsage: %s [ip|port <preferred_port> [scan_limit] [host]]\n' "$1" "$0" >&2
        exit 2
        ;;
esac
