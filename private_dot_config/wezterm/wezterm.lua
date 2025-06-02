local wezterm = require 'wezterm'

local config = {
  -- Set fish as default shell
  -- default_prog = { "/usr/bin/fish", "--login" },

  -- Use a Powerline-compatible font
  font = wezterm.font("Fira Code Nerd Font"),
  font_size = 12.0,
  -- Set maximum FPS (important to prevent excessive CPU usage)
  max_fps = 60,  -- Adjust based on your display. 30-60 is usually best.
  -- Enable ligatures for better font rendering
  harfbuzz_features = { "calt=1", "liga=1", "clig=1", "dlig=1" },
  -- Enable GPU acceleration (default is enabled, but we enforce it)
  enable_wayland = false,  -- If on Linux, use Wayland only if needed.
  line_height = 1.0,  -- Adjust this value as needed
  audible_bell= "Disabled",
  visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = "CursorColor",

  }
}

-- Theme options (uncomment the one you want to use)
--local light_theme = "Solarized (light) (terminal.sexy)"
--local light_theme = "Solarized Light (Gogh)"
-- local light_theme = "Github"
-- local light_theme = "Material Lighter (base16)"
-- local light_theme = "GruvboxLight"
local light_theme = "Selenized Light (Gogh)"

--local dark_theme = "Solarized Dark (Gogh)"
-- local dark_theme = "Solarized Dark (terminal.sexy)"
-- local dark_theme = "GruvboxDark"
local dark_theme = "Selenized Dark (Gogh)"

-- Set theme based on system appearance
local system_appearance = wezterm.gui.get_appearance()
if system_appearance:find("Dark") then
  config.color_scheme = dark_theme
else
  config.color_scheme = light_theme
end

return config
