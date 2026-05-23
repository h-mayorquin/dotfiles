# Ideas

## Nix Home Manager

Declarative management of both packages and dotfiles in a single `.nix` file. `home-manager switch`
installs tools and writes config atomically, fully reproducible across machines. Works on both macOS
and Linux. The right long-term answer for the "new machine bootstrap" problem. Blockers: real
learning curve, cryptic errors, conda is a known pain point with Nix.

## Chezmoi templates

Convert `private_dot_config/fish/config.fish` to a `.tmpl` file and use chezmoi's Go template
conditionals (`{{ if eq .chezmoi.os "linux" }}`) instead of fish-level `if test $OS = Linux` guards.
Benefit is a cleaner rendered file per OS with dead branches removed entirely. Low urgency since the
current fish guards work fine.

## Chezmoi run_once scripts for stable tools

A `run_once_` script that installs only the tools with rock-solid official installers: Rust/Cargo,
starship, atuin, bun, chezmoi itself. Leave the rest (NVM, conda, Go) to a manual checklist in
README.md. Avoids the maintenance trap of scripting everything while automating the most tedious
parts.
