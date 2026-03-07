#!/usr/bin/env python3

from __future__ import annotations

import os
import sys
import unicodedata
from pathlib import Path


EXCLUDED = {
    ".git",
}


def is_excluded(path: Path, root: Path) -> bool:
    try:
        relative = path.relative_to(root)
    except ValueError:
        return True
    return any(part in EXCLUDED for part in relative.parts)


def rename_to_nfc(path: Path) -> bool:
    normalized_name = unicodedata.normalize("NFC", path.name)
    if normalized_name == path.name:
        return False

    parent = path.parent
    target = parent / normalized_name
    temp = parent / f".__nfc_tmp__{normalized_name}"

    os.rename(path, temp)
    os.rename(temp, target)
    return True


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".").resolve()
    paths = [
        path
        for path in root.rglob("*")
        if not is_excluded(path, root)
    ]
    paths.sort(key=lambda p: len(p.parts), reverse=True)

    renamed = 0
    for path in paths:
        if rename_to_nfc(path):
            renamed += 1

    print(f"Renamed {renamed} paths to NFC under {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
