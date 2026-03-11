#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/usr/local/lib/dart-sass"
BIN_LINK="/usr/local/bin/sass"

case "$(uname -s)" in
    Linux) ;;
    *)
        printf 'Ce script ne fonctionne que sur Linux.\n' >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    x86_64|amd64) archive_suffix="linux-x64" ;;
    aarch64|arm64) archive_suffix="linux-arm64" ;;
    armv7l|armv6l|armhf) archive_suffix="linux-arm" ;;
    *)
        printf 'Architecture non supportee: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

for cmd in curl tar mktemp; do
    command -v "$cmd" >/dev/null 2>&1 || {
        printf 'Commande requise manquante: %s\n' "$cmd" >&2
        exit 1
    }
done

latest_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/sass/dart-sass/releases/latest)"
version="${latest_url##*/}"
archive_url="https://github.com/sass/dart-sass/releases/download/${version}/dart-sass-${version}-${archive_suffix}.tar.gz"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl -fL "$archive_url" -o "$tmp_dir/dart-sass.tar.gz"
tar -xzf "$tmp_dir/dart-sass.tar.gz" -C "$tmp_dir"

if [ ! -x "$tmp_dir/dart-sass/sass" ]; then
    printf 'Archive Dart Sass invalide.\n' >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    rm -rf "$INSTALL_DIR"
    mv "$tmp_dir/dart-sass" "$INSTALL_DIR"
    ln -sfn "$INSTALL_DIR/sass" "$BIN_LINK"
else
    sudo rm -rf "$INSTALL_DIR"
    sudo mv "$tmp_dir/dart-sass" "$INSTALL_DIR"
    sudo ln -sfn "$INSTALL_DIR/sass" "$BIN_LINK"
fi

"$BIN_LINK" --version
