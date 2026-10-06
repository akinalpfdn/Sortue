#!/usr/bin/env python3
"""Generates fastlane/metadata/<locale>/*.txt from appstore/listing/<locale>.md.

The markdown files are the source of truth; fastlane/metadata is generated and git-ignored.
URLs and categories come from fastlane/listing-config.json (same for every locale).

  python3 fastlane/prepare.py
"""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LISTING = ROOT / "appstore" / "listing"
OUT = ROOT / "fastlane" / "metadata"
CONFIG = ROOT / "fastlane" / "listing-config.json"

SECTIONS = {
    "Name": "name.txt",
    "Subtitle": "subtitle.txt",
    "Promotional Text": "promotional_text.txt",
    "Description": "description.txt",
    "Keywords": "keywords.txt",
    "What's New": "release_notes.txt",
}
BLOCK = re.compile(r"^## (?P<title>[^\n]+)\n+```text\n(?P<body>.*?)\n```", re.M | re.S)


def parse(md: str) -> dict[str, str]:
    found = {m.group("title").strip(): m.group("body") for m in BLOCK.finditer(md)}
    missing = [s for s in SECTIONS if s not in found]
    if missing:
        raise SystemExit(f"missing sections {missing}")
    return {SECTIONS[s]: found[s] for s in SECTIONS}


def main() -> None:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    urls = {k: config.get(k, "") for k in ("support_url", "privacy_url", "marketing_url")}
    empty = [k for k in ("support_url", "privacy_url") if not urls[k]]
    if empty:
        raise SystemExit(f"fill in {empty} in {CONFIG.relative_to(ROOT)} first; App Store Connect requires them for every new locale")

    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    for key in ("primary_category", "secondary_category"):
        if config.get(key):
            (OUT / f"{key}.txt").write_text(config[key], encoding="utf-8")

    files = sorted(LISTING.glob("*.md"))
    if not files:
        raise SystemExit(f"no listing files in {LISTING}")
    for path in files:
        if path.stem == "README":
            continue
        locale = path.stem
        fields = parse(path.read_text(encoding="utf-8"))
        folder = OUT / locale
        folder.mkdir()
        for name, text in fields.items():
            (folder / name).write_text(text, encoding="utf-8")
        for name, url in urls.items():
            url = config.get(f"{name}_overrides", {}).get(locale, url)
            if url:
                (folder / f"{name}.txt").write_text(url, encoding="utf-8")
        print(f"{locale:8} name {len(fields['name.txt']):2}  subtitle {len(fields['subtitle.txt']):2}  keywords {len(fields['keywords.txt']):3}")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
