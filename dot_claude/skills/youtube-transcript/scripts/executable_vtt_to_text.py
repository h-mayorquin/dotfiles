#!/usr/bin/env python3
"""Convert a YouTube VTT caption file to clean plain text.

YouTube's VTT output has several quirks this script handles:
- Per-word inline timestamps like <00:00:05.839><c> is</c>
- <c>/</c> style tags
- Rolling-caption duplication (each line appears ~twice as captions scroll)
- HTML entity leakage (&amp; for &, etc.)
- Position/alignment metadata on cue headers
"""

import html
import re
import sys
from pathlib import Path


def vtt_to_text(vtt_path: Path) -> str:
    content = vtt_path.read_text(encoding="utf-8")

    # Strip WEBVTT header
    content = re.sub(r"^WEBVTT.*?\n\n", "", content, flags=re.DOTALL)

    text_lines = []
    for line in content.split("\n"):
        stripped = line.strip()
        if not stripped:
            continue
        # Skip cue timing lines (and their position metadata)
        if "-->" in stripped:
            continue
        # Skip cue identifier lines (bare integers)
        if stripped.isdigit():
            continue
        # Strip inline word-level timestamps and <c> markup
        cleaned = re.sub(r"<\d{2}:\d{2}:\d{2}\.\d{3}>", "", stripped)
        cleaned = re.sub(r"</?c[^>]*>", "", cleaned)
        cleaned = html.unescape(cleaned)
        cleaned = cleaned.strip()
        if cleaned:
            text_lines.append(cleaned)

    # Dedupe consecutive identical lines (rolling caption duplication)
    deduped = []
    for line in text_lines:
        if not deduped or deduped[-1] != line:
            deduped.append(line)

    text = " ".join(deduped)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def main():
    if len(sys.argv) < 2:
        print("usage: vtt_to_text.py <input.vtt> [output.txt]", file=sys.stderr)
        sys.exit(2)

    in_path = Path(sys.argv[1])
    if not in_path.exists():
        print(f"error: {in_path} not found", file=sys.stderr)
        sys.exit(1)

    text = vtt_to_text(in_path)

    if len(sys.argv) >= 3:
        out_path = Path(sys.argv[2])
        out_path.write_text(text + "\n", encoding="utf-8")
        words = len(text.split())
        print(f"wrote {out_path}: {len(text):,} chars, {words:,} words")
    else:
        sys.stdout.write(text + "\n")


if __name__ == "__main__":
    main()
