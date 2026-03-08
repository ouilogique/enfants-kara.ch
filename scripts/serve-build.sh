#!/usr/bin/env bash

###
# Sert un build de comparaison sur un port local et ouvre le navigateur.
#
# Usage:
#   bash scripts/serve-build.sh [theme] [port]
#
# Exemples:
#   bash scripts/serve-build.sh kara        # port 8080
#   bash scripts/serve-build.sh congo       # port 8081
#   bash scripts/serve-build.sh papermod    # port 8082
##

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

THEME="${1:-kara}"
BUILD_DIR="$PROJECT_DIR/builds/$THEME"

# Port par défaut selon le thème, surchargeable en 2e argument
case "$THEME" in
  kara)     DEFAULT_PORT=8080 ;;
  congo)    DEFAULT_PORT=8081 ;;
  papermod) DEFAULT_PORT=8082 ;;
  *)        DEFAULT_PORT=8080 ;;
esac
PORT="${2:-$DEFAULT_PORT}"

if [ ! -d "$BUILD_DIR" ]; then
  echo "Répertoire introuvable : $BUILD_DIR"
  echo "Lance d'abord : hugo --environment compare --gc --destination builds/$THEME"
  exit 1
fi

URL="http://localhost:$PORT"
echo "Serving $THEME → $URL"

# Ouvre le navigateur après un court délai pour laisser le serveur démarrer
(sleep 0.5 && open "$URL") &

python3 -m http.server "$PORT" --directory "$BUILD_DIR"
