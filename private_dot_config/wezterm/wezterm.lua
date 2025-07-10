-- ~/.config/wezterm/wezterm.lua
-- Cross-platform WezTerm configuration
--  • Prefers fish shell when available, with sane fall-backs
--  • Auto light/dark theme switching
--  • Comments throughout for easy tweaking

local wezterm = require 'wezterm'   -- WezTerm API

local config = {}                   -- Main configuration table

-- ─────────────────────────────────────────────────────────────────────────────
-- FONT & VISUALS
-- ─────────────────────────────────────────────────────────────────────────────
config.font              = wezterm.font('FiraCode Nerd Font') -- Nerd-Font for glyphs
config.font_size         = 12.0
config.harfbuzz_features = { 'calt=1', 'liga=1', 'clig=1', 'dlig=1' } -- enable ligatures
config.line_height       = 1.0        -- Adjust if text looks cramped/tall
config.text_min_contrast_ratio = 3.5 -- only on unreleased version, WCAG 2.0 level AA for readability

-- ─────────────────────────────────────────────────────────────────────────────
-- PERFORMANCE
-- ─────────────────────────────────────────────────────────────────────────────
config.max_fps        = 60            -- Cap FPS to reduce CPU usage
config.enable_wayland = false         -- Disable Wayland unless you need it

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS (bells)
-- ─────────────────────────────────────────────────────────────────────────────
config.audible_bell = 'Disabled'      -- Silence speaker bell
config.visual_bell  = {               -- Flash background instead
  fade_in_duration_ms  = 100,
  fade_out_duration_ms = 100,
  target               = 'BackgroundColor',
}
config.warn_about_missing_glyphs = false -- Less console spam

-- ─────────────────────────────────────────────────────────────────────────────
-- TAB BAR
-- ─────────────────────────────────────────────────────────────────────────────
config.enable_tab_bar               = true
config.tab_bar_at_bottom            = false
config.use_fancy_tab_bar            = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width                = 30

-- ─────────────────────────────────────────────────────────────────────────────
-- THEME OPTIONS  ░░░  Uncomment any pair you prefer
-- ─────────────────────────────────────────────────────────────────────────────
local light_theme = "Selenized Light (Gogh)"
-- local light_theme = "Solarized Light (Gogh)"
-- local light_theme = "GruvboxLight"

local dark_theme        = "Selenized Dark (Gogh)"
-- local dark_theme  = "Solarized Dark (Gogh)"
-- local dark_theme  = "GruvboxDark"

-- Auto-switch between light/dark based on system appearance (macOS/Windows)
if wezterm.gui.get_appearance():find('Dark') then
  config.color_scheme = dark_theme
else
  config.color_scheme = light_theme
end

-- ────────────────────────────────────────────────────────────────────────────
-- DEFAULT SHELL LOGIC (fish first; zsh fallback on macOS)
-- ────────────────────────────────────────────────────────────────────────────
-- Helper: cheap file-existence check (we only care that the path exists;
-- executability is implied for typical fish installs)
local function file_exists(path)
  local f = io.open(path, 'rb')
  if f then f:close() end
  return f ~= nil
end

local target = wezterm.target_triple  -- e.g. "aarch64-apple-darwin"

if target:find('windows') then
  -- Windows: try fish in default WSL distro; otherwise PowerShell Core/MSYS
  config.default_prog = { 'wsl.exe', 'fish', '--login' }

elseif target:find('darwin') then
  -- macOS: prefer Homebrew fish; fall back to /bin/zsh (not bash)
  if file_exists('/opt/homebrew/bin/fish') then        -- Apple Silicon
    config.default_prog = { '/opt/homebrew/bin/fish', '--login' }
  elseif file_exists('/usr/local/bin/fish') then       -- Intel
    config.default_prog = { '/usr/local/bin/fish', '--login' }
  else
    config.default_prog = { '/bin/zsh', '-l' }
  end

else
  -- Linux / *BSD: fish if present, otherwise bash
  if file_exists('/usr/bin/fish') then
    config.default_prog = { '/usr/bin/fish', '--login' }
  elseif file_exists('/bin/fish') then
    config.default_prog = { '/bin/fish', '--login' }
  else
    config.default_prog = { '/bin/bash', '-l' }
  end
end


-- ─────────────────────────────────────────────────────────────────────────────
return config