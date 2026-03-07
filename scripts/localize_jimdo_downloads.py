#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import urllib.parse
import urllib.request
from pathlib import Path


SITE_BASE = "https://enfantskara.jimdofree.com"
DOWNLOAD_PATTERN = re.compile(
    r"(https://enfantskara\.jimdofree\.com/app/download/[^)\s\"']+|/app/download/[^)\s\"']+)"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download Jimdo documents locally and rewrite Markdown links.")
    parser.add_argument("--content", type=Path, default=Path("content"))
    parser.add_argument("--static", type=Path, default=Path("static/downloads"))
    parser.add_argument("--timeout", type=int, default=30)
    return parser.parse_args()


def normalize_url(url: str) -> str:
    if url.startswith("/"):
        return f"{SITE_BASE}{url}"
    return url


def file_name_for_url(url: str) -> str:
    split = urllib.parse.urlsplit(url)
    base = Path(urllib.parse.unquote(split.path)).name or "download"
    stem = Path(base).stem or "download"
    ext = Path(base).suffix or ".bin"
    safe_stem = re.sub(r"[^a-zA-Z0-9._-]+", "-", stem).strip("-") or "download"
    digest = hashlib.sha1(url.encode("utf-8")).hexdigest()[:10]
    return f"{safe_stem}-{digest}{ext.lower()}"


def download(url: str, destination: Path, timeout: int) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        destination.write_bytes(response.read())


def main() -> None:
    args = parse_args()
    content_root = args.content.resolve()
    static_root = args.static.resolve() if args.static.is_absolute() else (Path.cwd() / args.static).resolve()
    if static_root.exists():
        shutil.rmtree(static_root)
    static_root.mkdir(parents=True, exist_ok=True)

    mapping: dict[str, str] = {}
    for md_file in content_root.rglob("*.md"):
        text = md_file.read_text(encoding="utf-8")
        for match in DOWNLOAD_PATTERN.findall(text):
            remote = normalize_url(match)
            mapping[match] = f"/downloads/{file_name_for_url(remote)}"

    downloaded: dict[str, Path] = {}
    for original, local in mapping.items():
        remote = normalize_url(original)
        destination = static_root / Path(local).name
        if remote not in downloaded:
            download(remote, destination, args.timeout)
            downloaded[remote] = destination

    for md_file in content_root.rglob("*.md"):
        text = md_file.read_text(encoding="utf-8")
        updated = text
        for original, local in mapping.items():
            updated = updated.replace(original, local)
        if updated != text:
            md_file.write_text(updated, encoding="utf-8")

    print(f"Localized {len(downloaded)} downloads into {static_root}")


if __name__ == "__main__":
    main()
