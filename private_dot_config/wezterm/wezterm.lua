local wezterm = require 'wezterm'

local config = {
  -- Set fish as default shell
  default_prog = { "/usr/bin/fish", "--login" },

  -- ============================================================================
  -- FONT AND VISUAL SETTINGS
  -- ============================================================================
  
  -- Use a Powerline-compatible font
  font = wezterm.font("Fira Code Nerd Font"),
  font_size = 12.0,
  -- Enable ligatures for better font rendering (makes -> into actual arrows, etc.)
  harfbuzz_features = { "calt=1", "liga=1", "clig=1", "dlig=1" },
  line_height = 1.0,  -- Adjust this value as needed
  
  -- ============================================================================
  -- PERFORMANCE SETTINGS
  -- ============================================================================
  
  -- Set maximum FPS (important to prevent excessive CPU usage)
  max_fps = 60,  -- Adjust based on your display. 30-60 is usually best.
  -- Enable GPU acceleration (default is enabled, but we enforce it)
  enable_wayland = false,  -- If on Linux, use Wayland only if needed.
  
  -- ============================================================================
  -- NOTIFICATION SETTINGS
  -- ============================================================================
  
  -- Disable annoying audio bell
  audible_bell = "Disabled",
  -- Use visual bell that briefly makes background flash instead of sound
  visual_bell = {
    fade_in_duration_ms = 100,
    fade_out_duration_ms = 100,
    target = "BackgroundColor", 
    -- Other target options: "CursorColor", "CursorOutline", "Foreground"

  },
  -- Don't warn about missing font glyphs (reduces console spam)
  warn_about_missing_glyphs = false,

  -- ============================================================================
  -- TAB BAR CONFIGURATION (Fish-optimized)
  -- ============================================================================
  
  -- Always show tab bar for better organization (even with single tab)
  enable_tab_bar = true,
  -- Position tabs at top like browser tabs (more familiar)
  tab_bar_at_bottom = false,
  -- Use modern-looking tab bar instead of retro style
  use_fancy_tab_bar = true,
  -- Show tab bar even when only one tab (consistent UI)
  hide_tab_bar_if_only_one_tab = false,
  -- Limit tab title length to prevent overcrowding
  tab_max_width = 30,


}


-- ============================================================================
-- THEME CONFIGURATION (Automatic dark/light switching)
-- ============================================================================

-- Theme options (uncomment the one you want to use)
-- local light_theme = "Solarized (light) (terminal.sexy)"
-- local light_theme = "Solarized Light (Gogh)"
-- local light_theme = "GruvboxLight"
local light_theme = "Selenized Light (Gogh)"

--local dark_theme = "Solarized Dark (Gogh)"
-- local dark_theme = "Solarized Dark (terminal.sexy)"
-- local dark_theme = "GruvboxDark"
local dark_theme = "Selenized Dark (Gogh)"

-- Automatically switch theme based on system appearance (macOS/Windows)
local system_appearance = wezterm.gui.get_appearance()
if system_appearance:find("Dark") then
  config.color_scheme = dark_theme
else
  config.color_scheme = light_theme
end

return config