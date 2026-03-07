#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import unicodedata
from dataclasses import dataclass
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import SplitResult, quote, unquote, urlsplit, urlunsplit


SITE_HOSTS = {"enfantskara.jimdofree.com", "www.enfantskara.jimdofree.com"}
VOID_ELEMENTS = {
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
}


class ContentAreaExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self._capturing = False
        self._depth = 0
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attrs_dict = dict(attrs)
        if not self._capturing:
            if tag == "div" and attrs_dict.get("id") == "content_area":
                self._capturing = True
                self._depth = 0
            return
        self.parts.append(self.get_starttag_text())
        if tag not in VOID_ELEMENTS:
            self._depth += 1

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if self._capturing:
            self.parts.append(self.get_starttag_text())

    def handle_endtag(self, tag: str) -> None:
        if not self._capturing:
            return
        if self._depth == 0 and tag == "div":
            self._capturing = False
            return
        self.parts.append(f"</{tag}>")
        if tag not in VOID_ELEMENTS and self._depth > 0:
            self._depth -= 1

    def handle_data(self, data: str) -> None:
        if self._capturing:
            self.parts.append(data)

    def handle_comment(self, data: str) -> None:
        if self._capturing:
            self.parts.append(f"<!--{data}-->")

    def handle_entityref(self, name: str) -> None:
        if self._capturing:
            self.parts.append(f"&{name};")

    def handle_charref(self, name: str) -> None:
        if self._capturing:
            self.parts.append(f"&#{name};")


@dataclass
class PageMeta:
    title: str
    description: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert HTML pages to Hugo Markdown.")
    parser.add_argument("--source", type=Path, default=Path("."))
    parser.add_argument("--output", type=Path, default=Path("content"))
    return parser.parse_args()


def slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_only = normalized.encode("ascii", "ignore").decode("ascii")
    lowered = ascii_only.lower()
    slug = re.sub(r"[^a-z0-9]+", "-", lowered).strip("-")
    return slug or "page"


def collect_html_files(root: Path) -> list[Path]:
    excluded_roots = {
        ".git",
        "archetypes",
        "assets",
        "content",
        "data",
        "i18n",
        "layouts",
        "public",
        "resources",
        "scripts",
        "static",
    }
    return sorted(
        path
        for path in root.rglob("*.html")
        if path.is_file()
        and not any(part in excluded_roots for part in path.parts)
        and not should_skip_source(path.relative_to(root))
    )


def should_skip_source(relative_path: Path) -> bool:
    posix = relative_path.as_posix()
    if posix == "_downloads.html":
        return True
    if posix == "sitemap/index.html":
        return True
    if posix.startswith("protected/"):
        return True
    return False


def has_child_pages(html_path: Path, all_files: set[Path]) -> bool:
    if html_path.name != "index.html":
        return False
    for candidate in all_files:
        if candidate == html_path:
            continue
        try:
            candidate.relative_to(html_path.parent)
        except ValueError:
            continue
        return True
    return False


def read_meta(html: str) -> PageMeta:
    title_match = re.search(r"<title>(.*?)</title>", html, flags=re.IGNORECASE | re.DOTALL)
    title = unescape(title_match.group(1).strip()) if title_match else ""
    title = re.sub(r"\s*-\s*Enfants-Kara\s*$", "", title).strip()

    desc_match = re.search(
        r'<meta\s+name="description"\s+content="(.*?)"\s*/?>',
        html,
        flags=re.IGNORECASE | re.DOTALL,
    )
    description = unescape(desc_match.group(1).strip()) if desc_match else ""
    return PageMeta(title=title, description=description)


def extract_content_fragment(html: str) -> str:
    parser = ContentAreaExtractor()
    parser.feed(html)
    parser.close()
    fragment = "".join(parser.parts)
    if not fragment.strip():
        body_match = re.search(r"<body.*?>(.*)</body>", html, flags=re.IGNORECASE | re.DOTALL)
        fragment = body_match.group(1) if body_match else html
    fragment = re.sub(r"<div[^>]*id=\"content_start\"[^>]*>\s*</div>", "", fragment, flags=re.IGNORECASE)
    fragment = re.sub(r"<form\b.*?</form>", "", fragment, flags=re.IGNORECASE | re.DOTALL)
    fragment = re.sub(r"<script\b.*?</script>", "", fragment, flags=re.IGNORECASE | re.DOTALL)
    fragment = re.sub(r"<style\b.*?</style>", "", fragment, flags=re.IGNORECASE | re.DOTALL)
    fragment = re.sub(r"<!--.*?-->", "", fragment, flags=re.DOTALL)
    return fragment.strip()


def run_pandoc(fragment: str) -> str:
    result = subprocess.run(
        [
            "pandoc",
            "--from=html",
            "--to=gfm-raw_html",
            "--wrap=none",
            "--strip-comments",
        ],
        input=fragment,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout.strip() + "\n"


def rewrite_path(path: str) -> str:
    if path.endswith("/index.html"):
        return path[: -len("index.html")]
    if path == "index.html":
        return "./"
    return path


def rewrite_link_target(target: str) -> str:
    if not target or target.startswith(("#", "mailto:", "tel:", "data:", "javascript:")):
        return target

    split = urlsplit(target)
    if split.scheme in {"http", "https"}:
        if split.netloc not in SITE_HOSTS:
            return target
        path = rewrite_path(split.path.lstrip("/"))
        new_path = "/" + path if path else "/"
        return urlunsplit(SplitResult("", "", new_path, split.query, split.fragment))

    path = rewrite_path(split.path)
    return urlunsplit(SplitResult("", "", path, split.query, split.fragment))


def split_markdown_target(target: str) -> tuple[str, str]:
    match = re.match(r"^(<[^>]+>|[^\s]+)(\s+.+)?$", target)
    if not match:
        return target, ""
    return match.group(1), match.group(2) or ""


def rewrite_internal_links(markdown: str) -> str:
    pattern = re.compile(r"(!?\[[^\]]*\]\()([^)]+)(\))")

    def repl(match: re.Match[str]) -> str:
        prefix, target, suffix = match.groups()
        url_part, suffix_part = split_markdown_target(target)
        rewritten = rewrite_link_target(url_part.strip("<>"))
        if url_part.startswith("<") and url_part.endswith(">"):
            rewritten = f"<{rewritten}>"
        return f"{prefix}{rewritten}{suffix_part}{suffix}"

    return pattern.sub(repl, markdown)


def build_output_path(html_path: Path, output_root: Path, all_files: set[Path]) -> Path:
    if html_path == Path("index.html"):
        return output_root / "_index.md"
    if html_path.name == "index.html":
        parent = output_root / html_path.parent
        filename = "_index.md" if has_child_pages(html_path, all_files) else "index.md"
        return parent / filename
    slug = slugify(html_path.stem)
    return output_root / html_path.parent / slug / "index.md"


def original_alias(html_path: Path) -> str:
    if html_path == Path("index.html"):
        return "/index.html"
    encoded = quote(unquote(html_path.as_posix()), safe="/")
    return f"/{encoded}"


def format_front_matter(meta: PageMeta, alias: str) -> str:
    lines = ["---"]
    lines.append(f'title: "{escape_yaml(meta.title or "Sans titre")}"')
    if meta.description:
        lines.append(f'description: "{escape_yaml(meta.description)}"')
    lines.append("draft: false")
    lines.append("aliases:")
    lines.append(f'  - "{escape_yaml(alias)}"')
    lines.append("---")
    return "\n".join(lines) + "\n\n"


def escape_yaml(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").strip()


def is_thumbnail_gallery_line(line: str) -> bool:
    stripped = line.strip()
    if not stripped or "dimension=25x25:mode=crop" not in stripped:
        return False
    return bool(re.fullmatch(r"(?:!\[[^\]]*\]\([^)]+\)\s*)+", stripped))


def derive_title(markdown: str, fallback: str) -> str:
    for line in markdown.splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        match = re.match(r"^#\s+(.+?)\s*$", stripped)
        if match:
            heading = match.group(1).strip()
            if heading:
                return heading
            break
    return fallback or "Sans titre"


def humanize_slug(value: str) -> str:
    text = unicodedata.normalize("NFC", value)
    text = text.replace("-", " ")
    if not text:
        return "Sans titre"
    return text[0].upper() + text[1:]


def choose_title(markdown: str, fallback: str, relative_path: Path) -> str:
    derived = derive_title(markdown, fallback)
    if "photos-" in relative_path.as_posix() and "photos" not in derived.lower():
        return humanize_slug(relative_path.parent.name)
    return derived


def markdown_has_meaningful_content(markdown: str) -> bool:
    text = re.sub(r"!\[[^\]]*\]\([^)]+\)", "", markdown)
    text = re.sub(r"\[[^\]]+\]\([^)]+\)", "", text)
    text = re.sub(r"^#+\s*", "", text, flags=re.MULTILINE)
    text = text.strip()
    return bool(text)


def clean_markdown(markdown: str) -> str:
    markdown = rewrite_internal_links(markdown)
    markdown = re.sub(r"\[(!\[[^\]]*\]\([^)]+\))\]\(javascript:[^)]*\)", r"\1", markdown)
    markdown = re.sub(r"\[(!\[[^\]]*\]\([^)]+\))\]\(\)", r"\1", markdown)
    filtered_lines = []
    for line in markdown.splitlines():
        line = line.replace("\xa0", " ").rstrip()
        if re.fullmatch(r"\s*\\\s*", line):
            continue
        if "javascript:" in line or "/app/common/captcha/" in line or is_thumbnail_gallery_line(line):
            continue
        line = re.sub(r"^\\-\s*", "- ", line)
        line = re.sub(r"\s{2,}", " ", line) if not re.match(r"^\s{4,}", line) else line
        filtered_lines.append(line)
    markdown = "\n".join(filtered_lines)
    markdown = re.sub(r"\n[ \t]+\n", "\n\n", markdown)
    markdown = re.sub(r"\n{3,}", "\n\n", markdown)
    return markdown.strip() + "\n"


def convert_file(html_path: Path, source_root: Path, output_root: Path, all_files: set[Path]) -> Path:
    relative_path = html_path.relative_to(source_root)
    html = html_path.read_text(encoding="utf-8")
    meta = read_meta(html)
    fragment = extract_content_fragment(html)
    markdown = clean_markdown(run_pandoc(fragment))
    meta.title = choose_title(markdown, meta.title, relative_path)
    if not markdown_has_meaningful_content(markdown) and relative_path.name == "index.html" and relative_path != Path("index.html"):
        return output_root / ".skip"
    destination = build_output_path(relative_path, output_root, all_files)
    destination.parent.mkdir(parents=True, exist_ok=True)
    front_matter = format_front_matter(meta, original_alias(relative_path))
    destination.write_text(front_matter + markdown, encoding="utf-8")
    return destination


def main() -> None:
    args = parse_args()
    source_root = args.source.resolve()
    output_root = (source_root / args.output).resolve() if not args.output.is_absolute() else args.output.resolve()
    if shutil.which("pandoc") is None:
        raise SystemExit("pandoc is required")

    html_files = collect_html_files(source_root)
    relative_files = {path.relative_to(source_root) for path in html_files}

    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True, exist_ok=True)

    converted: list[Path] = []
    for html_file in html_files:
        destination = convert_file(html_file, source_root, output_root, relative_files)
        if destination.name != ".skip":
            converted.append(destination)

    print(f"Converted {len(converted)} HTML files to {output_root}")


if __name__ == "__main__":
    main()
