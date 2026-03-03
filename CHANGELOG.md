# Changelog

## 2026-03-02

- Removed `eval "$(gh copilot alias -- bash)"` from bashrc. The `gh-copilot`
  extension was deprecated on 2025-10-25 and replaced by the standalone
  GitHub Copilot CLI (`copilot`). The old extension caused
  "too many arguments. Expected 0 arguments but got 1" errors on terminal
  startup after a `gh` update.
