---
name: read-pdf
description: This skill should be used when the user asks to read, extract, parse, or analyze a PDF file, or when Claude encounters a .pdf file that needs to be read. Triggers when the user references a file path ending in .pdf, asks to "open a PDF", "extract text from a PDF", "read this paper", "summarize this PDF", or needs to work with scanned documents. Use this skill instead of Claude's built-in PDF reader for any PDF task, as it produces much better results, especially for complex layouts, tables, equations, and scanned documents.
allowed-tools: Bash(pdftotext *), Bash(marker_single *), Bash(ocrmypdf *), Bash(wc *), Bash(cat /tmp/marker_output*), Bash(ls /tmp/marker_output*), Read
---

# Reading PDF Documents

This skill extracts text from PDFs using a three-tier approach that escalates from fast and simple to more powerful tools as needed. The tiers exist because no single tool handles every PDF well: digital PDFs with simple layouts just need basic text extraction, but complex formatting (multi-column, tables, equations) or scanned/image-based PDFs require specialized tools.

## Tool Locations

- `pdftotext` at `/usr/bin/pdftotext`
- `marker_single` at `/home/heberto/.local/bin/marker_single`
- `ocrmypdf` at `/home/heberto/.local/bin/ocrmypdf`

Before using a tool, verify it exists by running `which <tool>`. If a tool is missing, tell the user how to install it and ask if they'd like you to run the install command:

- **pdftotext**: `sudo apt install poppler-utils` (Linux) or `brew install poppler` (macOS)
- **marker_single**: `uv tool install marker-pdf`
- **ocrmypdf**: `uv tool install ocrmypdf` (also needs Tesseract: `sudo apt install tesseract-ocr` or `brew install tesseract`)

Tier 1 (pdftotext) is essential. Tiers 2 and 3 are only needed when escalating, so don't block the user if only those are missing. Instead, extract what you can with the available tools and mention what could be improved with the missing tool installed.

## Decision Logic

Before running anything, check context clues to pick the right starting tier:

- **User asks for structured/Markdown output, or the PDF is a scientific paper, has tables, equations, or multi-column layout**: skip straight to Tier 2 (marker_single). These documents have formatting that pdftotext will mangle.
- **Otherwise**: start with Tier 1 (pdftotext) and escalate if the output is poor.

## Tier 1: pdftotext (default, fast)

For most digital PDFs with straightforward layouts.

```bash
pdftotext file.pdf -
```

The `-` sends output to stdout. To preserve spatial layout (useful for forms or tabular data):

```bash
pdftotext -layout file.pdf -
```

**When to escalate**: If the output is empty or nearly empty (less than a few dozen characters for a multi-page PDF), the PDF is likely scanned/image-based. Go to Tier 3. If the output is garbled or columns are interleaved, go to Tier 2.

## Tier 2: marker_single (complex documents)

For PDFs with rich formatting: multi-column layouts, tables, headings, equations, or figures.

```bash
marker_single file.pdf --output_dir /tmp/marker_output
```

This outputs structured Markdown that preserves:
- Headings and document hierarchy
- Tables (as Markdown tables)
- Equations (as LaTeX)
- Multi-column layouts (merged into reading order)

The output goes to a subdirectory inside `/tmp/marker_output`. To find and read it:

```bash
find /tmp/marker_output -name "*.md" -exec cat {} \;
```

Clean up after reading:

```bash
rm -rf /tmp/marker_output
```

## Tier 3: ocrmypdf (scanned/image PDFs)

When pdftotext returns empty or near-empty output, the PDF likely contains scanned images rather than embedded text. OCR adds a text layer, then pdftotext can extract it.

```bash
ocrmypdf input.pdf /tmp/output_ocr.pdf
pdftotext /tmp/output_ocr.pdf -
```

If the scanned document also has complex formatting, you can run marker_single on the OCR'd PDF instead:

```bash
ocrmypdf input.pdf /tmp/output_ocr.pdf
marker_single /tmp/output_ocr.pdf --output_dir /tmp/marker_output
```

Clean up temp files when done:

```bash
rm -f /tmp/output_ocr.pdf
rm -rf /tmp/marker_output
```

## Password-Protected PDFs

Some PDFs (e.g., Banorte credit card statements) are password-protected. The built-in Read tool and pdftotext will fail on these. Use `pikepdf` via `uv run` to decrypt first:

```bash
uv run --with pikepdf python3 -c "
import pikepdf
pdf = pikepdf.open('protected.pdf', password='PASSWORD')
pdf.save('decrypted.pdf')
"
```

Then read the decrypted file with the normal tiers. Remove the original protected file after decrypting to avoid confusion.

## Usage Notes

- Always clean up temporary files (`/tmp/output_ocr.pdf`, `/tmp/marker_output/`) after extracting the text you need.
- For very large PDFs, you can extract specific pages with pdftotext: `pdftotext -f 1 -l 10 file.pdf -` extracts pages 1 through 10.
- When the user wants to "summarize" or "analyze" a PDF, extract the text first using this skill, then proceed with the analysis.
