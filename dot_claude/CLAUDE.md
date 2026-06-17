# Claude Instructions

## Markdown Formatting

**NEVER use emojis in markdown content.** This is a strict requirement that must be followed at all times. Do not add emojis to any markdown files, documentation, README files, or any other text content unless explicitly requested by the user. Keep all markdown clean and professional without decorative emojis.

Avoid using em dashes (--) in writing. Use commas, periods, or parentheses instead.

Do not use the words "lift" / "lifted" or "load-bearing" in writing (PRs, docs, chat). Use "extract" / "extracted" or a plainer description instead.

## Acronyms

Never use an acronym as a stand-alone token. Always expand it on every use, even after it has appeared earlier in the same response or document. Write "STN (subthalamic nucleus)", "M1 (primary motor cortex)", "MER (microelectrode recording)" each time the term appears, not just on first use. This applies to chat responses, code comments, markdown docs, and PR descriptions alike. The cost of repeating the expansion is small; the cost of an unexplained acronym is high because a reader who lands on the middle of a document has no context. Pick the most natural inline form ("X (full name)") and use it consistently throughout.

## GitHub Actions

Never create GitHub issues, pull requests, or comments, and never push to remote repositories, without the user explicitly authorizing that specific action in the current message. Writing a description to a local file is not authorization to publish it. Always ask first.

## PR and Issue Descriptions

When writing PR or issue descriptions:
- PR drafts go in the current directory (repo root). They are transient: deleted once the PR is published.
- Issue drafts may live longer through iteration. If the project has a longer-lived scratchpad area (e.g., an Obsidian vault folder under `ongoing_work/`), use it; otherwise the current directory is fine.
- Keep the content concise with only a single header for the PR or issue title.
- Default to one or two paragraphs. Adding more paragraphs requires a strong, specific reason (typically a non-obvious scoping decision worth explaining in first person). Most diffs do not need them; the diff itself does the heavy lifting, and the description should explain only the "why" the diff cannot.
- Do not add additional headers or sections unless explicitly requested by the user.
- Only present final design decisions. Unless explicitly asked to, do not include implementation discussions, rejected alternatives, or the history of how we arrived at the solution. Just state what was decided and why.
- Write design reasoning in prose paragraphs, not change lists. The diff already shows what changed, so the description should explain the "why."
- When the user does explicitly ask for a scoping note, use first-person voice rather than passive "out of scope" lists. The same voice rule applies elsewhere in PR descriptions: e.g., "I picked uint32 because uint64 doubles per-entry memory for no real-world benefit" rather than "uint32 was picked because...".

## Pull Request Diffs

When preparing a pull request, minimize diff churn. Change only what the fix or feature strictly requires. Do not fold in incidental refactors, reformatting, comment deletions, variable renames, or restructuring that is not essential to the change, because each unrelated edit makes the diff harder for reviewers to read.

Only modify docstrings if strictly necessary for the change. In borderline cases, where a docstring edit or a larger diff might be worth it but is not clearly required, do not just make the change. Pause and raise it with me as a separate discussion step, explaining why you think the docstring change or the larger diff is worth it, and let me decide.

## Obsidian Vault

When a conversation produces reusable knowledge (design decisions, troubleshooting solutions, architecture documentation, reusable programming patterns), suggest saving it to the Obsidian vault using the obsidian skill.

### Work repos symlink pattern

For repos under `~/development/work_repos/`, prefer a `./obsidian_docs` symlink pointing to the matching vault folder (usually `~/MEGAsync/obsidian/heberto_vault/neuroscience/<repo-name>/`), excluded locally via `.git/info/exclude` (never `.gitignore`). When entering such a repo without this setup, surface the proposal rather than silently creating it.

## Python

Use `uv` for running Python programs and managing dependencies unless explicitly told not to. Avoid using `idx` as a variable name use `index` or `indices` instead.