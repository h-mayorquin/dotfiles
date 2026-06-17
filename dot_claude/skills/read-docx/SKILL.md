---
name: read-docx
description: This skill should be used when the user asks to "read a docx file", "open a Word document", "extract text from a docx", "view a .docx file", or when Claude encounters a .docx file that needs to be read. Also triggers when the user references a file path ending in .docx or .doc.
allowed-tools: Bash(doxx *)
---

# Reading Microsoft Word Documents

This skill uses `doxx`, a fast Rust-based terminal document viewer, to read `.docx` files directly from the command line without requiring Microsoft Office or Python libraries.

## Reading a Document

To extract the full text content of a `.docx` file as Markdown:

```bash
doxx file.docx --export markdown
```

To extract as plain text (no formatting):

```bash
doxx file.docx --export text
```

## Extracting Tables Only

To extract tables as CSV:

```bash
doxx file.docx --export csv
```

## Searching Within a Document

To search for specific content:

```bash
doxx file.docx --search "search term" --export text
```

## Viewing Document Metadata

To get document metadata as JSON:

```bash
doxx file.docx --export json
```

## Usage Notes

- Prefer `--export markdown` for most use cases as it preserves headings, lists, and table structure.
- Use `--export text` when only raw text content is needed (e.g., for further processing or when formatting is irrelevant).
- `doxx` only supports `.docx` files (Office Open XML). For older `.doc` files (binary format), fall back to `libreoffice --headless --convert-to txt file.doc` or `antiword file.doc`.
- The tool is installed at `/home/heberto/.cargo/bin/doxx`.
- If `doxx` is not found, suggest installing it with `cargo install doxx`.
