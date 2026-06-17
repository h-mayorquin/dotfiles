# Obsidian CLI Command Reference

The Obsidian CLI communicates with a running Obsidian instance. If Obsidian is not running,
commands will launch it first (which adds startup delay). All commands below assume the
default vault. For multi-vault setups, add `vault="name"` as the first parameter.

## File Operations

### read

Read the full content of a note.

```bash
obsidian read file="path/to/note"
```

Prefer the Read tool over this command for speed and no app dependency.

### create

Create a new note. Optionally use an Obsidian template.

```bash
obsidian create name="folder/note-title" content="markdown content here"
obsidian create name="folder/note-title" template="TemplateName"
```

Use the `template=` parameter when the user has Obsidian templates that should be respected
(resolves `{{date}}`, `{{title}}`, etc.).

### append

Add content to the end of a note.

```bash
obsidian append file="path/to/note" content="new content"
obsidian append file="path/to/note" content="inline addition" inline
```

The `inline` flag appends to the last line instead of adding a new line.

### prepend

Add content after the frontmatter block. This is frontmatter-aware: it inserts after the
closing `---`, not at byte 0.

```bash
obsidian prepend file="path/to/note" content="content after frontmatter"
```

### move

Move or rename a note. Rewrites all wikilinks across the entire vault that pointed to the
old location. Always use this instead of shell `mv`.

```bash
obsidian move file="old/path/note" to="new/path/"
obsidian move file="old/path/note" to="new/path/new-name"
```

### delete

Move a note to trash (respects user's trash preference in Obsidian settings).

```bash
obsidian delete file="path/to/note"
obsidian delete file="path/to/note" permanent
```

## Search

### search

Full-text search. Returns matching file paths. Supports Obsidian search operators.

```bash
obsidian search query="search term"
obsidian search query="search term" path="subfolder/"
obsidian search query="tag:#python" format=json
```

Obsidian search operators (not available via Grep):
- `tag:#tagname` - find notes with a specific tag
- `section:("heading text")` - search within sections by heading
- `block:(term)` - search within specific blocks
- `path:folder/` - scope to a folder
- `file:filename` - scope to a filename
- Boolean: `term1 AND term2`, `term1 OR term2`, `NOT term`

### search:context

Same as search but includes surrounding lines (like `grep -C`).

```bash
obsidian search:context query="search term" limit=10
```

For plain text search, prefer the Grep tool. Use CLI search only when you need the
Obsidian-specific operators listed above.

## Link Analysis

### backlinks

List all notes that contain a wikilink pointing to this note. Resolves aliases, heading
links, and block references.

```bash
obsidian backlinks file="path/to/note"
obsidian backlinks file="path/to/note" format=json
```

### links

List all outgoing wikilinks from a note, resolved to actual file paths.

```bash
obsidian links file="path/to/note"
```

### unresolved

List all wikilinks across the vault that point to notes that don't exist.

```bash
obsidian unresolved
obsidian unresolved format=json
```

### orphans

List notes that nothing links to.

```bash
obsidian orphans
```

### deadends

List notes that contain no outgoing links.

```bash
obsidian deadends
```

## Tags and Properties

### tags

List all tags in the vault with counts.

```bash
obsidian tags
obsidian tags format=json
```

### tag

List all notes with a specific tag. Understands nested tags: querying `#computer` also
finds `#computer/performance`.

```bash
obsidian tag name="#computer/performance"
```

### properties

Read all frontmatter properties of a note.

```bash
obsidian properties file="path/to/note"
obsidian properties file="path/to/note" format=json
```

### property:set

Set a frontmatter field. Creates the frontmatter block if it doesn't exist. Safer than
manual YAML editing.

```bash
obsidian property:set file="path/to/note" name="status" value="reviewed"
obsidian property:set file="path/to/note" name="updated" value="2026-03-15"
```

### property:remove

Remove a frontmatter field.

```bash
obsidian property:remove file="path/to/note" name="fieldname"
```

## Daily Notes

### daily

Open today's daily note (creates from template if it doesn't exist).

```bash
obsidian daily
```

### daily:append

Append content to today's daily note. Creates the note from template if needed.

```bash
obsidian daily:append content="## Meeting with team\n- discussed X\n- decided Y"
```

### daily:read

Read today's daily note content.

```bash
obsidian daily:read
```

### daily:path

Get the file path of today's daily note.

```bash
obsidian daily:path
```

## Outline

### outline

Show the heading hierarchy of a note.

```bash
obsidian outline file="path/to/note"
obsidian outline file="path/to/note" format=json
```

## Useful Global Flags

- `format=json` - structured output (available on most commands)
- `format=csv` - CSV output
- `--copy` - copies output to clipboard
- `vault="name"` - target a specific vault (must be first parameter)
