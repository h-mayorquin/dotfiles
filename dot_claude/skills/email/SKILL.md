---
name: email
description: This skill should be used when the user asks to search emails, find emails from a sender, look for emails about a topic, read an email or thread, check inbox, browse Gmail categories (social, updates, promotions), or download email attachments. Use when the user says things like "find emails from X", "search my email for Y", "read that thread", "check if I got an email about Z", "what's in my inbox".
allowed-tools: Bash(msgvault *), Bash(gws *)
---

Use `msgvault` for all search, read, thread, and attachment operations. It queries a local SQLite archive for millisecond responses with no rate limits.

Use `gws` only for Gmail categories (Social, Updates, Promotions, Forums) since msgvault does not sync those.

The authenticated Gmail account is h.mayorquin@gmail.com.

## Always sync before searching

Run an incremental sync first to ensure the archive is current. This is fast - it only fetches changes since the last sync via the Gmail History API:

```bash
msgvault sync h.mayorquin@gmail.com
```

## Search

Full Gmail-like syntax, all offline:

```bash
# By subject
msgvault search "subject:neuroconv"

# By sender
msgvault search "from:robert@pitt.edu"

# Full text
msgvault search "neuroconv ophys metadata"

# Unread
msgvault search "label:UNREAD subject:neuroconv"

# Date range
msgvault search "after:2026-01-01 before:2026-03-14"

# Relative date
msgvault search "from:github newer_than:7d"

# Has attachment
msgvault search "from:robert has:attachment"

# Combined
msgvault search "subject:NWB from:ben.dichter@catalystneuro.com after:2025-01-01"

# JSON output for programmatic use
msgvault search "neuroconv" --json
```

Output columns: `ID`, `DATE`, `FROM`, `SUBJECT`, `SIZE`. Use `ID` with `show-message`.

## Read a Message

```bash
msgvault show-message <id>

# JSON output - includes body_text, body_html, labels, attachments
msgvault show-message <id> --json
```

## Analytics

```bash
# Top senders
msgvault list-senders --limit 20

# Top domains
msgvault list-domains

# Labels with counts
msgvault list-labels
```

## Download Attachments

```bash
# Export all attachments from a message
msgvault export-attachments <id> -o ~/Downloads/msgvault_attachments

# Export a specific attachment by content hash (from show-message --json)
msgvault export-attachment <content-hash> -o filename.pdf
```

## Gmail Categories (gws only)

msgvault does not sync Gmail categories. Use gws for these:

```bash
gws gmail +triage --query "category:updates" --format table
gws gmail +triage --query "category:social" --format table
gws gmail +triage --query "category:promotions" --format table
gws gmail +triage --query "category:forums" --format table
```

`gws gmail +triage` fetches message summaries (date, from, id, subject) using full Gmail search syntax. The `id` returned is a Gmail hex ID, not a msgvault numeric ID.
