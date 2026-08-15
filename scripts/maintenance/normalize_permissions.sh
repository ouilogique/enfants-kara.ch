#!/usr/bin/env bash

##
# Uniformise les permissions POSIX du projet.
#
# Règles appliquées :
# - dossiers : 0755 ;
# - tous les fichiers, scripts compris : 0644.
#
# Le dossier .git et les liens symboliques ne sont pas modifiés.
#
# USAGE
#   bash scripts/maintenance/normalize_permissions.sh
#   bash scripts/maintenance/normalize_permissions.sh --check
##

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

usage() {
    printf 'Usage : %s [--check]\n' "${0##*/}"
    printf '  Sans option  Uniformise les permissions.\n'
    printf '  --check      Signale les permissions non conformes sans les modifier.\n'
}

find_bad_directories() {
    find "$PROJECT_DIR" \
        -path "$PROJECT_DIR/.git" -prune -o \
        -type d ! -perm 0755 -print
}

find_bad_regular_files() {
    find "$PROJECT_DIR" \
        -path "$PROJECT_DIR/.git" -prune -o \
        -type f \
        ! -perm 0644 -print
}

check_permissions() {
    local has_errors=0
    local results

    results="$(find_bad_directories)"
    if [[ -n "$results" ]]; then
        printf 'Dossiers qui ne sont pas en 0755 :\n%s\n' "$results"
        has_errors=1
    fi

    results="$(find_bad_regular_files)"
    if [[ -n "$results" ]]; then
        printf 'Fichiers ordinaires qui ne sont pas en 0644 :\n%s\n' "$results"
        has_errors=1
    fi

    if ((has_errors != 0)); then
        return 1
    fi

    printf 'Toutes les permissions sont conformes.\n'
}

normalize_permissions() {
    find "$PROJECT_DIR" \
        -path "$PROJECT_DIR/.git" -prune -o \
        -type d -exec chmod 0755 {} +

    find "$PROJECT_DIR" \
        -path "$PROJECT_DIR/.git" -prune -o \
        -type f -exec chmod 0644 {} +

    printf 'Permissions uniformisées dans %s\n' "$PROJECT_DIR"
}

case "${1:-}" in
    '')
        normalize_permissions
        ;;
    --check)
        check_permissions
        ;;
    -h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
