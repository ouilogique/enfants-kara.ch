#!/usr/bin/env bash

set -euo pipefail

PORT="${1:-1313}"
OS_NAME="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HUGO_CONFIG="${PROJECT_ROOT}/config.yaml"
if [[ -f "${PROJECT_ROOT}/config.test_ouilogique_nogit.yaml" ]]; then
  HUGO_CONFIG="${HUGO_CONFIG},${PROJECT_ROOT}/config.test_ouilogique_nogit.yaml"
fi
USE_LAN_BASEURL="${USE_LAN_BASEURL:-0}"
PREVIEW_DIR="${PROJECT_ROOT}/.hugo_preview"

if ! command -v hugo >/dev/null 2>&1; then
  echo "hugo introuvable dans le PATH." >&2
  exit 1
fi

if [[ "${OS_NAME}" == "Darwin" ]]; then
  if ! command -v route >/dev/null 2>&1; then
    echo "route introuvable." >&2
    exit 1
  fi

  if ! command -v ipconfig >/dev/null 2>&1; then
    echo "ipconfig introuvable." >&2
    exit 1
  fi

  if ! command -v ifconfig >/dev/null 2>&1; then
    echo "ifconfig introuvable." >&2
    exit 1
  fi
elif [[ "${OS_NAME}" == "Linux" ]]; then
  if ! command -v ip >/dev/null 2>&1; then
    echo "ip introuvable (paquet iproute2 requis)." >&2
    exit 1
  fi
else
  echo "OS non supporte: ${OS_NAME}. Utiliser Darwin ou Linux." >&2
  exit 1
fi

if [[ "${OS_NAME}" == "Darwin" ]]; then
  DEFAULT_IFACE="$(
    route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}'
  )"
else
  DEFAULT_IFACE="$(
    ip route show default 2>/dev/null | awk '/default/{print $5; exit}'
  )"
fi

if [[ -z "${DEFAULT_IFACE}" ]]; then
  echo "Impossible de determiner l'interface par defaut." >&2
  exit 1
fi

if [[ "${OS_NAME}" == "Darwin" ]]; then
  LAN_IP="$(ipconfig getifaddr "${DEFAULT_IFACE}" 2>/dev/null || true)"

  if [[ -z "${LAN_IP}" ]]; then
    LAN_IP="$(
      ifconfig "${DEFAULT_IFACE}" 2>/dev/null | awk '/inet /{print $2; exit}'
    )"
  fi
else
  LAN_IP="$(
    ip -4 -o addr show dev "${DEFAULT_IFACE}" scope global 2>/dev/null \
      | awk '{print $4}' \
      | cut -d/ -f1 \
      | head -n1
  )"
fi

if [[ -z "${LAN_IP}" ]]; then
  echo "Impossible de recuperer l'adresse IP de ${DEFAULT_IFACE}." >&2
  exit 1
fi

BASE_URL="http://${LAN_IP}:${PORT}/"

echo "Interface par defaut : ${DEFAULT_IFACE}"
echo "URL locale : ${BASE_URL}"
if [[ "${USE_LAN_BASEURL}" == "1" ]]; then
  echo "Mode baseURL: LAN (USE_LAN_BASEURL=1)"
else
  echo "Mode baseURL: config Hugo (par defaut)"
fi
echo

if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ANSIUTF8 "${BASE_URL}"
  echo
else
  echo "qrencode introuvable, QR code non affiche."
  if [[ "${OS_NAME}" == "Linux" ]]; then
    echo "Installation (Ubuntu/Debian): sudo apt update && sudo apt install -y qrencode"
  elif [[ "${OS_NAME}" == "Darwin" ]]; then
    echo "Installation (macOS/Homebrew): brew install qrencode"
  fi
  echo
fi

HUGO_ARGS=(
  server
  --source "${PROJECT_ROOT}"
  --config "${HUGO_CONFIG}"
  --destination "${PREVIEW_DIR}"
  --bind 0.0.0.0
  --port "${PORT}"
  --appendPort=false
  --noBuildLock
  --disableFastRender
)

if [[ "${USE_LAN_BASEURL}" == "1" ]]; then
  HUGO_ARGS+=(--baseURL "${BASE_URL}")
fi

exec hugo "${HUGO_ARGS[@]}"
