#!/bin/zsh

set -euo pipefail

PORT="${1:-1313}"

if ! command -v hugo >/dev/null 2>&1; then
  echo "hugo introuvable dans le PATH." >&2
  exit 1
fi

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

DEFAULT_IFACE="$(
  route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}'
)"

if [[ -z "${DEFAULT_IFACE}" ]]; then
  echo "Impossible de determiner l'interface par defaut." >&2
  exit 1
fi

LAN_IP="$(ipconfig getifaddr "${DEFAULT_IFACE}" 2>/dev/null || true)"

if [[ -z "${LAN_IP}" ]]; then
  LAN_IP="$(
    ifconfig "${DEFAULT_IFACE}" 2>/dev/null | awk '/inet /{print $2; exit}'
  )"
fi

if [[ -z "${LAN_IP}" ]]; then
  echo "Impossible de recuperer l'adresse IP de ${DEFAULT_IFACE}." >&2
  exit 1
fi

BASE_URL="http://${LAN_IP}:${PORT}/"

echo "Interface par defaut : ${DEFAULT_IFACE}"
echo "URL locale : ${BASE_URL}"
echo

if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ANSIUTF8 "${BASE_URL}"
  echo
else
  echo "qrencode introuvable, QR code non affiche."
  echo
fi

exec hugo server \
  --bind 0.0.0.0 \
  --baseURL "${BASE_URL}" \
  --port "${PORT}" \
  --appendPort=false \
  --noBuildLock \
  --disableFastRender
