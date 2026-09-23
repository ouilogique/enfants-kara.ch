#!/usr/bin/env bash

# Lance la previsualisation depuis le Finder ou en ligne de commande.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" || exit 1
exec bash "$SCRIPT_DIR/internal/preview.sh" "$@"
