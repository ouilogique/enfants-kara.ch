#!/usr/bin/env bash

set -euo pipefail

os_name="$(uname -s 2>/dev/null || printf '%s' 'unknown')"

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

getIPofDefaultInterface
