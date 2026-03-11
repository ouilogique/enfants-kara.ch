#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
INSTALL_DIR="/usr/local/lib/dart-sass"
BIN_LINK="/usr/local/bin/sass"
VERSION="${1:-latest}"

usage() {
    cat <<EOF
Usage:
  bash scripts/$SCRIPT_NAME [latest|VERSION]

Examples:
  bash scripts/$SCRIPT_NAME
  bash scripts/$SCRIPT_NAME 1.98.0

Installs Dart Sass from the official GitHub release on Linux.
Supported architectures: x64, arm64, arm.
EOF
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    fi
}

detect_archive_suffix() {
    local arch
    arch="$(uname -m)"

    case "$arch" in
        x86_64|amd64)
            printf '%s\n' 'linux-x64'
            ;;
        aarch64|arm64)
            printf '%s\n' 'linux-arm64'
            ;;
        armv7l|armv6l|armhf)
            printf '%s\n' 'linux-arm'
            ;;
        *)
            printf 'Unsupported architecture: %s\n' "$arch" >&2
            exit 1
            ;;
    esac
}

build_download_url() {
    local suffix
    suffix="$1"

    if [ "$VERSION" = "latest" ]; then
        printf '%s\n' "https://github.com/sass/dart-sass/releases/latest/download/dart-sass-${suffix}.tar.gz"
    else
        printf '%s\n' "https://github.com/sass/dart-sass/releases/download/${VERSION}/dart-sass-${VERSION}-${suffix}.tar.gz"
    fi
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf 'This step requires root privileges. Re-run as root or install sudo.\n' >&2
        exit 1
    fi
}

download_archive() {
    local destination url
    destination="$1"
    url="$2"

    if command -v wget >/dev/null 2>&1; then
        wget -O "$destination" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$destination" "$url"
    else
        printf 'Missing required command: wget or curl\n' >&2
        exit 1
    fi
}

main() {
    local os_name suffix url tmp_dir archive_path extracted_dir

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        usage
        exit 0
    fi

    os_name="$(uname -s)"
    if [ "$os_name" != "Linux" ]; then
        printf 'Unsupported operating system: %s\n' "$os_name" >&2
        exit 1
    fi

    require_command uname
    require_command id
    require_command mktemp
    require_command tar

    suffix="$(detect_archive_suffix)"
    url="$(build_download_url "$suffix")"
    tmp_dir="$(mktemp -d)"
    archive_path="$tmp_dir/dart-sass.tar.gz"
    extracted_dir="$tmp_dir/dart-sass"

    trap 'rm -rf "$tmp_dir"' EXIT

    printf 'Downloading %s\n' "$url"
    download_archive "$archive_path" "$url"

    tar -xzf "$archive_path" -C "$tmp_dir"

    if [ ! -x "$extracted_dir/sass" ]; then
        printf 'Unexpected archive contents in %s\n' "$archive_path" >&2
        exit 1
    fi

    run_as_root rm -rf "$INSTALL_DIR"
    run_as_root mv "$extracted_dir" "$INSTALL_DIR"
    run_as_root ln -sf "$INSTALL_DIR/sass" "$BIN_LINK"

    printf 'Installed Dart Sass to %s\n' "$INSTALL_DIR"
    "$BIN_LINK" --version
}

main "$@"
