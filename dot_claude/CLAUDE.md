# Claude Instructions

## Markdown Formatting

**NEVER use emojis in markdown content.** This is a strict requirement that must be followed at all times. Do not add emojis to any markdown files, documentation, README files, or any other text content unless explicitly requested by the user. Keep all markdown clean and professional without decorative emojis.

Avoid using em dashes (--) in writing. Use commas, periods, or parentheses instead.

## PR and Issue Descriptions

When writing PR or issue descriptions:
- Write them to a local file in the current directory.
- Keep the content concise with only a single header for the PR or issue title.
- Do not add additional headers or sections unless explicitly requested by the user.
- Only present final design decisions. Unless explicitly asked to, do not include implementation discussions, rejected alternatives, or the history of how we arrived at the solution. Just state what was decided and why.
- Write design reasoning in prose paragraphs, not change lists. The diff already shows what changed, so the description should explain the "why."
- Use first-person voice for scoping decisions (e.g. "I have left out X to keep this easier to review") rather than passive "out of scope" lists.


## Python

Use `uv` for running Python programs and managing dependencies unless explicitly told not to. Avoid using `idx` as a variable name — use `index` or `indices` instead.