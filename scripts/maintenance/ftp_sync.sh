#!/usr/bin/env bash

##
# @file ftp_sync.sh
# @brief Synchronise le dossier `.hugo/public/` vers l’hébergement SFTP avec `rclone`.
#
# @details
# Utilise les variables d’environnement suivantes pour l’authentification :
# - `FTP_SYNC_USER` : nom d’utilisateur SFTP
# - `FTP_SYNC_PASSWORD` : mot de passe SFTP en clair
#
# @code{.sh}
# FTP_SYNC_USER="mon_user" FTP_SYNC_PASSWORD="mon_mot_de_passe" bash ./scripts/maintenance/ftp_sync.sh
# @endcode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HAS_ERROR=0

if [[ -z "${FTP_SYNC_USER:-}" ]]; then
    echo "Erreur : la variable d'environnement FTP_SYNC_USER doit etre definie." >&2
    HAS_ERROR=1
fi

if [[ -z "${FTP_SYNC_PASSWORD:-}" ]]; then
    echo "Erreur : la variable d'environnement FTP_SYNC_PASSWORD doit etre definie." >&2
    HAS_ERROR=1
fi

if [[ "$HAS_ERROR" -ne 0 ]]; then
    echo "Exemple : FTP_SYNC_USER=\"mon_user\" FTP_SYNC_PASSWORD=\"mon_mot_de_passe\" bash ./scripts/maintenance/ftp_sync.sh" >&2
    exit 1
fi

rclone sync "$PROJECT_DIR/.hugo/public" :sftp:/data/enfants-kara.ch/public \
    -v \
    --progress \
    --sftp-host ftp.ouilogique.ch \
    --sftp-port 22 \
    --sftp-shell-type none \
    --sftp-disable-hashcheck \
    --sftp-user "$FTP_SYNC_USER" \
    --sftp-pass "$(rclone obscure "$FTP_SYNC_PASSWORD")"
