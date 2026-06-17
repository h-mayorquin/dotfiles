---
name: youtube-transcript
description: Transcribe YouTube videos into clean plain text (via YouTube's caption track or Whisper), and search YouTube from the command line using yt-dlp. Use this skill whenever the user references a YouTube URL and wants its content, asks to transcribe a talk/lecture/webinar, asks to pull captions or subtitles, wants to take notes from a video, or asks to search YouTube for videos on a topic. Also use when the user pastes a YouTube URL and asks "what is this about" or "summarize this video".
---

# YouTube transcript and search

This skill covers three related workflows the user does against YouTube from the terminal:

1. Fetch a clean plain-text transcript of a video
2. Search YouTube for videos by keyword
3. Download audio from a video (often a side-effect of workflow 1)

All three are built on `yt-dlp`. The transcription workflow optionally adds `whisper` for better quality on technical content.

## Decision tree: which transcript path?

Before running anything, decide the quality you need.

- **Quick transcript, casual content (interviews, vlogs, mainstream talks)** — use YouTube's caption track (option A below). Takes ~5 seconds. Fine for getting the gist.
- **Technical or scientific content with proper names, jargon, or acronyms** — use Whisper (option B). Worth the ~6 minutes for a 1-hour video on a GPU. YouTube auto-captions mangle proper nouns ("Jülich" → "ulish"), researcher names ("Dickscheid" → "Timodikshed"), and acronyms (renders "MNI" as the HTML entity `M&amp;I`). These are exactly the words the user wants to cite in notes.
- **Video has real human-authored subtitles** — always use those. They are the gold standard and nothing beats them. Check first with `yt-dlp --list-subs`.
- **Animation-only / music video / no speech** — there is nothing useful to transcribe. Tell the user.

Run `yt-dlp --list-subs <URL>` first to see what the video has. The header tells you whether the listed tracks are "Available subtitles" (human-authored, rare) or "Available automatic captions" (ASR).

## Option A: YouTube caption track via yt-dlp

Fast, works offline of the GPU, good enough for non-technical content.

```bash
# Download the English caption track (auto or human) as VTT
yt-dlp --write-auto-sub --write-sub --sub-lang en --sub-format vtt \
  --skip-download -o "<basename>.%(ext)s" "<URL>"

# Convert VTT to clean plain text (handles YouTube's rolling-caption duplication)
python3 ~/.claude/skills/youtube-transcript/scripts/vtt_to_text.py \
  <basename>.en.vtt <basename>_youtube.txt
```

The `--write-sub --write-auto-sub` combo means: prefer human subs if they exist, fall back to auto. No need to branch in your calling code.

The VTT cleanup script removes:
- Per-word `<00:00:05.839>` timestamp markup YouTube injects into captions
- `<c>` / `</c>` style tags
- Rolling-caption duplication (every line appears twice, once partial and once complete, as the caption scrolls)
- Empty cues and position metadata

## Option B: Whisper transcription

Better quality, especially for technical content. Requires audio download + GPU time.

```bash
# 1. Extract audio (save to /tmp to keep the working directory clean)
yt-dlp -x --audio-format mp3 --audio-quality 0 \
  -o "/tmp/<basename>.%(ext)s" "<URL>"

# 2. Transcribe with Whisper. Default model is `turbo` — near large-v3 quality,
#    ~10x faster on a recent consumer GPU. Use --initial_prompt to seed
#    domain-specific vocabulary (researcher names, Latin anatomy terms, tool
#    names, etc.) so Whisper has a stronger prior on them.
whisper /tmp/<basename>.mp3 \
  --model turbo --device cuda --language en \
  --output_format srt --output_dir . \
  --initial_prompt "<5-20 domain-specific terms relevant to the video>"

# 3. Convert SRT to plain text, trimming the trailing hallucination
python3 ~/.claude/skills/youtube-transcript/scripts/srt_to_text.py \
  <basename>.srt <basename>_whisper.txt
```

### Seeding the initial prompt

Ask or infer what the video is about. Good initial prompts name:
- Proper nouns: speaker names, lab names, project names
- Technical acronyms: MNI, DTI, fMRI, CUDA, etc.
- Domain vocabulary: cytoarchitecture, cerebellum, autoradiography, etc.
- Tool/library names, especially those that sound like common words (e.g. `siibra` sounds like "zebra" and Whisper gets it wrong even with seeding — flag this to the user)

Keep the prompt short (one sentence, under 250 tokens). Whisper uses it as a soft prior, not a hard constraint.

### Tail-hallucination trim

Whisper often hallucinates 10-60 seconds of garbage at the end of a video when the speaker stops but the audio track continues in silence. Typical symptoms:
- Sudden appearance of non-ASCII characters (Japanese, Cyrillic, Arabic) in an English video
- Repetitive phrases ("and these regions of interest are raised, the terms of interest in interest of others")
- Nonsense tokens in ALL CAPS ("FROMCOLAPONE")

The `srt_to_text.py` script auto-detects and trims these. It also prints a warning so the user knows to sanity-check the ending.

## Option C: Search YouTube

`yt-dlp` can query YouTube's search endpoint directly, no API key needed.

```bash
# Quick search, print title/duration/uploader/URL
bash ~/.claude/skills/youtube-transcript/scripts/search.sh 10 "anatomical localization lecture"

# Or directly:
yt-dlp "ytsearch10:<query>" \
  --print "%(title)s | %(duration_string)s | %(uploader)s | %(webpage_url)s" \
  --skip-download

# Filter by duration (10 min - 1 hour, for example)
yt-dlp "ytsearch50:<query>" \
  --match-filters "duration > 600 & duration < 3600" \
  --print "%(title)s | %(duration_string)s | %(webpage_url)s" \
  --skip-download
```

Scraping the search page is slower and less structured than the official YouTube Data API v3, but it works with zero setup. The official API is only worth it for high-volume automated use (10k/day quota, 100 units per search).

## Quality caveats to surface

When the user wants accurate text, proactively mention these known failure modes rather than letting them discover problems later in their notes:

- **Tool/library names that sound like common words** — Both YouTube and Whisper fail on these (e.g. `siibra` → "Zebra" / "Zeepra"). Initial-prompt seeding helps Whisper but doesn't fully fix it. Recommend a final find/replace pass if the name appears in the user's notes.
- **German/Latin anatomy terms with umlauts** — Whisper generally handles these well (got "Jülich" right, with the ü character). YouTube does not.
- **Silent tails** — Always trim Whisper output. The SRT-to-text script does this automatically.
- **HTML entity leakage in YouTube VTT** — Characters like `&` are rendered as `&amp;` in the raw VTT. The `vtt_to_text.py` script decodes these.

## Output conventions

When working in an Obsidian vault or note-taking directory, save outputs with clear names:

- `<topic>_youtube.txt` — YouTube caption track plain text
- `<topic>_whisper.txt` — Whisper plain text (tail-trimmed)
- `<topic>.srt` — Whisper timestamped SRT (useful for linking back to moments in the video)
- `<topic>.en.vtt` — YouTube raw VTT (delete after cleanup unless explicitly kept)

Put audio files in `/tmp/` (not the vault) since they are large and regenerable.

## Dependencies expected to be present

- `yt-dlp` installed via `uv tool` (not the system apt package, which is usually years out of date). Update with `uv tool upgrade yt-dlp`.
- `whisper` (openai-whisper) installed via `uv tool`, with CUDA available. On a laptop GPU like an RTX 3070 Ti, `--model turbo` runs at ~10x real-time. Without a GPU, drop to `--model small` or `--model base` on CPU and expect roughly real-time.
- `python3` with only the standard library for the helper scripts.

If any of these are missing, say so and point the user at `uv tool install yt-dlp` / `uv tool install openai-whisper` rather than guessing with the system package manager.
