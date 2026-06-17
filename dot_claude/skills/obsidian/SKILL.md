---
name: obsidian
description: >
  Read, search, and write to the user's Obsidian vault. Use this skill whenever the user
  mentions Obsidian, their vault, their notes, or asks to save/capture something for later.
  Also use when the user says "check my notes", "look in obsidian", "save this to my vault",
  "I want to remember this", or when a conversation produces reusable knowledge worth
  preserving (design decisions, troubleshooting solutions, architecture documentation).
  Even if the user doesn't explicitly mention Obsidian, suggest capturing when the
  conversation produces knowledge that matches a note type from the vault conventions.
---

# Obsidian Vault Integration

The user's Obsidian vault is at `/home/heberto/MEGAsync/obsidian/heberto_vault/`.

Before creating or editing any note, read `vault_conventions.md` at the vault root. It is
the single source of truth for folder structure, frontmatter format, tag taxonomy, note
types, and writing style. Do not hardcode conventions from memory; always check the file,
as the user may have updated it.

## Reading from the vault

### Content search

Use the Grep tool for searching text inside notes and the Glob tool for finding notes by
filename pattern. These are fast, work without Obsidian running, and have auto-allowed
permissions on the vault.

```
Grep("DANDI", path="/home/heberto/MEGAsync/obsidian/heberto_vault/")
Glob("**/anatomical*.md", path="/home/heberto/MEGAsync/obsidian/heberto_vault/")
```

### Link-aware queries (Obsidian CLI)

For operations that require understanding the vault's link graph, use the Obsidian CLI.
These commands require Obsidian to be running. See `references/cli_commands.md` for full
syntax.

Use the CLI when you need:
- **Backlinks**: what notes link TO a given note
- **Tags**: query by tag (understands frontmatter, nested tags, avoids false positives)
- **Unresolved links**: broken wikilinks across the vault
- **Orphans**: notes nothing links to

Do not use the CLI for plain text search. Grep is faster and doesn't require the app.

### When to read

- The user asks to "check my notes" or "look in obsidian"
- The user asks about a topic that might be documented in the vault
- You need context about a project the user has documented (check the vault before asking
  the user to re-explain something they may have already written down)

## Writing to the vault

**Always ask before writing.** The vault is a personal knowledge base. Propose the note
title, location, and a brief summary of what you'd write. Wait for approval.

### Creating new notes

Use the Write tool for new notes. Follow the conventions from `vault_conventions.md`:

- YAML frontmatter with `date`, `updated`, and `tags` (required), plus `type` (recommended)
- Add `source: claude-code` to frontmatter
- H1 title, H2 sections, H3 max depth
- Summary paragraph after the title
- `## Related` section at the end with wikilinks to connected notes

### Editing existing notes

Use the Edit tool for modifications to existing notes. Always update the `updated` field
in frontmatter to today's date.

### Using the Obsidian CLI for writes

Use the CLI (via Bash) instead of direct file writes for these specific operations:
- **`obsidian append`** / **`obsidian prepend`**: when adding content to an existing note,
  especially prepend which correctly handles frontmatter placement
- **`obsidian move`**: when renaming or moving a note (rewrites all wikilinks across the vault)
- **`obsidian property:set`**: when setting frontmatter fields (safer than manual YAML editing)

For all other writes (new notes, precise in-place edits), use Write/Edit tools directly.

Read `references/cli_commands.md` for exact command syntax before running CLI commands.

### Where to put new notes

1. If the topic clearly belongs in an existing folder, put it there.
2. If it spans multiple domains, pick the most natural home and tag for the other dimensions.
3. If unsure, use `inbox/`.

## Repo-vault symlink setup

When a repository has a dedicated folder in the vault, the recommended setup is to create a symlink inside the repo root pointing to that vault folder, then exclude the symlink locally without touching `.gitignore`.

```bash
# From the repo root
ln -s /home/heberto/MEGAsync/obsidian/heberto_vault/<project-folder> notes

# Exclude the symlink only for this local clone (never committed)
echo "notes" >> .git/info/exclude
```

`.git/info/exclude` behaves exactly like `.gitignore` but is local to the clone and never tracked. This keeps the vault accessible from the repo without polluting `.gitignore` or creating noise for other contributors.

If the user asks how to set this up, or if you notice a repo has a vault folder and no symlink, suggest this pattern.

## When to suggest capturing

During a conversation, suggest saving to the vault when you see:

- **Design decisions**: "We chose X over Y because..." with trade-offs worth preserving
- **Troubleshooting**: a problem was diagnosed and solved, the solution is reusable
- **Architecture documentation**: a system's structure, components, or data flow was discussed
- **Reusable patterns**: a programming technique, configuration, or workflow that applies beyond the current task
- **Reference material**: factual knowledge the user researched and would want to find again

Frame the suggestion concisely: "This troubleshooting session might be worth capturing in
`computer/performance/`. Want me to save it?" Include the proposed folder and note type.

Do not suggest capturing for:
- Trivial fixes or one-off commands
- Information already in the vault (search first)
- Conversations that are purely about the current task with no reusable knowledge

## Decision tree: CLI vs native tools

| Operation | Tool | Why |
|-----------|------|-----|
| Search text in notes | Grep | Fast, no app dependency |
| Find notes by name | Glob | Fast, no app dependency |
| Read a note | Read | Direct file access |
| Create a new note | Write | Direct, no template needed |
| Edit text within a note | Edit | Precise replacements |
| Append to a note | CLI `append` | Handles edge cases |
| Prepend after frontmatter | CLI `prepend` | Knows where frontmatter ends |
| Move/rename a note | CLI `move` | Rewrites wikilinks vault-wide |
| Set frontmatter property | CLI `property:set` | Safe YAML handling |
| Find backlinks | CLI `backlinks` | Requires link graph |
| Query by tag | CLI `tag` | Understands tag semantics |
| Find broken links | CLI `unresolved` | Requires link graph |
| Find orphan notes | CLI `orphans` | Requires link graph |
| Append to daily note | CLI `daily:append` | Knows daily note path config |
