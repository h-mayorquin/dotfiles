# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Targets macOS (Apple Silicon) and Linux (Ubuntu/Debian).

## What is managed

**Shells**

- `dot_bashrc` - bash configuration (kept for compatibility and scripts)
- `dot_zshrc` - minimal zsh configuration (kept for compatibility)
- `private_dot_config/fish/config.fish` - primary shell configuration

**Prompt and terminal**

- `private_dot_config/starship.toml` - cross-shell starship prompt
- `private_dot_config/wezterm/wezterm.lua` - WezTerm terminal emulator

**Version control**

- `dot_gitconfig` - git settings including delta as the diff pager

**Keyboard**

- `private_dot_config/private_karabiner/` - Karabiner-Elements key remapping (macOS only)

**Claude**

- `dot_claude/CLAUDE.md` - global instructions for Claude Code

## Tools configured

**Development runtimes**

- Go (`/usr/local/go/bin`, `$GOPATH/bin`)
- Rust/Cargo (`~/.cargo/bin`)
- Node.js via NVM (classic `~/.nvm` on Linux, Homebrew on macOS)
- Bun (`~/.bun/bin`)
- Python via Miniconda (Linux, `~/miniconda3`)

**CLI tools**

- [atuin](https://github.com/atuinsh/atuin) - shell history sync
- [zoxide](https://github.com/ajeetdsouza/zoxide) - smarter `cd`
- [fzf](https://github.com/junegunn/fzf) - fuzzy finder
- [starship](https://starship.rs/) - cross-shell prompt
- [delta](https://github.com/dandavison/delta) - git diff pager
- [gh](https://cli.github.com/) - GitHub CLI
- [micro](https://micro-editor.github.io/) - terminal text editor (set as `$EDITOR`)

## Notable decisions

**Fish is the primary shell.** Bash and zsh configs are kept minimal and are maintained mainly for compatibility (scripts, SSH sessions, tools that drop to bash). The fish config contains the full setup: PATH management, tool initialisation, and key bindings.

**Fish uses graceful degradation for optional tools.** Each tool (starship, zoxide, fzf, atuin) is guarded with `type -q` before initialisation. Missing tools print a warning in red rather than aborting the shell session. This keeps the config portable to machines where not everything is installed.

**NVM uses a bash wrapper in fish.** The fish-native `nvm.fish` plugin was avoided because it uses a different install root (`~/.local/share/nvm`) and does not share Node versions or global npm packages with the classic NVM install. The `bass` approach was also rejected because it cannot cleanly import bash functions. Instead, a small fish wrapper function spawns bash, sources `nvm.sh`, and forwards arguments.

**Delta as the git diff tool.** Git is configured to use delta for `git diff`, `git log -p`, and `git show`. The `interactive.diffFilter` is set to `delta --color-only` so that `git add -p` also benefits.

**Atuin + fzf integration for history search.** Ctrl+Alt+R opens an fzf selector over `atuin history list` output, showing timestamps alongside commands. This is mapped in both fish and bash. Ctrl+G is mapped to the standard fzf history widget.

**WezTerm Wayland disabled.** `enable_wayland = false` is set explicitly to avoid rendering and compatibility issues on Linux. XWayland works reliably with the current setup.

**Karabiner remappings (macOS only).**

- Fn key and Right Command are swapped, so Fn is accessible where Right Command physically sits.
- Caps Lock is remapped to Left Control.

**`gh copilot alias` removed.** The `eval "$(gh copilot alias -- bash)"` line was removed from `.bashrc` in March 2026. The `gh-copilot` extension was deprecated on 2025-10-25 and replaced by the standalone GitHub Copilot CLI. The old extension caused "too many arguments. Expected 0 arguments but got 1" errors on terminal startup after a `gh` update.
