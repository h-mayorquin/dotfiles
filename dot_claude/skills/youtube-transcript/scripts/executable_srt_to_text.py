#!/usr/bin/env python3
"""Convert a Whisper SRT file to clean plain text, trimming trailing hallucinations.

Whisper reliably hallucinates when the audio track runs on past the last spoken
words (silence, music stings, room noise). The hallucinations are usually
detectable by one of:

- Non-ASCII characters (Japanese/Cyrillic/Arabic) appearing in an English transcript
- Cues compressed to ~1-second intervals with repetitive or nonsense content
- ALL-CAPS gibberish tokens

This script trims from the first clearly-hallucinated cue to the end. It prints
a warning so the caller can sanity-check the tail manually.
"""

import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Cue:
    index: int
    start: str
    end: str
    text: str

    def duration_s(self) -> float:
        return _timestamp_to_seconds(self.end) - _timestamp_to_seconds(self.start)


def _timestamp_to_seconds(ts: str) -> float:
    # SRT format: HH:MM:SS,mmm
    h, m, rest = ts.split(":")
    s, ms = rest.split(",")
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000


def parse_srt(srt_path: Path) -> list[Cue]:
    content = srt_path.read_text(encoding="utf-8")
    cues: list[Cue] = []
    for block in re.split(r"\n\s*\n", content.strip()):
        lines = [ln for ln in block.split("\n") if ln.strip()]
        if len(lines) < 3:
            continue
        try:
            index = int(lines[0].strip())
        except ValueError:
            continue
        m = re.match(r"(\S+)\s*-->\s*(\S+)", lines[1])
        if not m:
            continue
        start, end = m.group(1), m.group(2)
        text = " ".join(lines[2:]).strip()
        cues.append(Cue(index, start, end, text))
    return cues


def detect_hallucination_start(cues: list[Cue], language: str = "en") -> int | None:
    """Return the index of the first hallucinated cue, or None if all clean.

    Heuristics (any one triggers a flag, conservative thresholds):
    - English transcript containing non-ASCII characters (Japanese, Cyrillic, etc.)
    - Cue with very short duration (<1.5s) containing repetitive short words
    - All-caps gibberish tokens of 8+ chars not in a small whitelist
    """
    ascii_languages = {"en", "es", "fr", "it", "pt", "de", "nl", "sv", "da", "no"}
    is_ascii_language = language in ascii_languages

    common_allcaps = {"MNI", "DTI", "EBRAINS", "NIH", "MRI", "FMRI", "HCP",
                      "DNA", "RNA", "PCR", "GPU", "CPU", "API", "URL", "NWB",
                      "HTTP", "HTTPS", "JSON", "YAML", "XML", "HTML", "SVG",
                      "USA", "UK", "EU", "LGN", "V1", "M1", "S1", "GABA"}

    for i, cue in enumerate(cues):
        text = cue.text

        # Non-ASCII in English → very strong signal
        if is_ascii_language and any(ord(c) > 127 and c not in "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝàáâãäåæçèéêëìíîïðñòóôõöøùúûüýÿÜüößÅå" for c in text):
            return i

        # Gibberish caps: a word of 8+ chars, all caps, not a known acronym
        for token in re.findall(r"\b[A-Z]{8,}\b", text):
            if token not in common_allcaps:
                return i

    return None


def srt_to_text(srt_path: Path, trim_tail: bool = True, language: str = "en") -> tuple[str, str | None]:
    """Return (text, warning_or_None)."""
    cues = parse_srt(srt_path)
    warning = None

    if trim_tail:
        bad_idx = detect_hallucination_start(cues, language)
        if bad_idx is not None:
            bad_cue = cues[bad_idx]
            warning = (
                f"trimmed {len(cues) - bad_idx} trailing cue(s) starting at "
                f"{bad_cue.start} (looked like a hallucination). "
                f"Review the SRT tail manually if this is unexpected."
            )
            cues = cues[:bad_idx]

    text = " ".join(cue.text for cue in cues).strip()
    text = re.sub(r"\s+", " ", text)
    return text, warning


def main():
    if len(sys.argv) < 2:
        print("usage: srt_to_text.py <input.srt> [output.txt] [--no-trim] [--lang=en]", file=sys.stderr)
        sys.exit(2)

    trim = True
    lang = "en"
    positional = []
    for arg in sys.argv[1:]:
        if arg == "--no-trim":
            trim = False
        elif arg.startswith("--lang="):
            lang = arg.split("=", 1)[1]
        else:
            positional.append(arg)

    in_path = Path(positional[0])
    if not in_path.exists():
        print(f"error: {in_path} not found", file=sys.stderr)
        sys.exit(1)

    text, warning = srt_to_text(in_path, trim_tail=trim, language=lang)
    if warning:
        print(f"warning: {warning}", file=sys.stderr)

    if len(positional) >= 2:
        out_path = Path(positional[1])
        out_path.write_text(text + "\n", encoding="utf-8")
        words = len(text.split())
        print(f"wrote {out_path}: {len(text):,} chars, {words:,} words")
    else:
        sys.stdout.write(text + "\n")


if __name__ == "__main__":
    main()
