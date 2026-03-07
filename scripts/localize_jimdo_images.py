#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import mimetypes
import re
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


IMAGE_PATTERN = re.compile(r"https://(?:image\.jimcdn\.com|assets\.jimstatic\.com)[^)\s\"']+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Download Jimdo images locally and rewrite Markdown links.")
    parser.add_argument("--content", type=Path, default=Path("content"))
    parser.add_argument("--static", type=Path, default=Path("static/images"))
    parser.add_argument("--timeout", type=int, default=30)
    return parser.parse_args()


def file_name_for_url(url: str) -> str:
    split = urllib.parse.urlsplit(url)
    parts = [p for p in split.path.split("/") if p]
    image_indices = [idx for idx, part in enumerate(parts) if part == "image"]
    image_id = None
    if image_indices:
        idx = image_indices[-1]
        if idx + 1 < len(parts):
            image_id = parts[idx + 1]

    base = Path(urllib.parse.unquote(parts[-1] if parts else "image")).name
    ext = Path(base).suffix.lower()
    if not ext:
        ext = mimetypes.guess_extension(split.path) or ".img"

    stem = image_id or Path(base).stem or "image"
    safe_stem = re.sub(r"[^a-zA-Z0-9._-]+", "-", stem).strip("-") or "image"
    digest = hashlib.sha1(url.encode("utf-8")).hexdigest()[:10]
    return f"{safe_stem}-{digest}{ext}"


def download(url: str, destination: Path, timeout: int) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        data = response.read()
    destination.write_bytes(data)


def rewrite_markdown(markdown: str, mapping: dict[str, str]) -> str:
    for remote, local in mapping.items():
        markdown = markdown.replace(remote, local)
    return markdown


def main() -> None:
    args = parse_args()
    content_root = args.content.resolve()
    static_root = args.static.resolve() if args.static.is_absolute() else (Path.cwd() / args.static).resolve()
    static_root.mkdir(parents=True, exist_ok=True)

    urls: dict[str, str] = {}
    for md_file in content_root.rglob("*.md"):
        text = md_file.read_text(encoding="utf-8")
        for url in IMAGE_PATTERN.findall(text):
            if url not in urls:
                urls[url] = f"/images/{file_name_for_url(url)}"

    if not urls:
        print(f"No remote Jimdo images found in {content_root}; keeping existing files in {static_root}")
        return

    for url, local_path in urls.items():
        destination = static_root / Path(local_path).name
        if not destination.exists():
            download(url, destination, args.timeout)

    for md_file in content_root.rglob("*.md"):
        text = md_file.read_text(encoding="utf-8")
        updated = rewrite_markdown(text, urls)
        if updated != text:
            md_file.write_text(updated, encoding="utf-8")

    print(f"Localized {len(urls)} images into {static_root}")


if __name__ == "__main__":
    main()
