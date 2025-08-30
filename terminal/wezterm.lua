local wezterm = require 'wezterm'

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'Iosevka',
  'Menlo',
})
config.font_size = 13.0
config.enable_tab_bar = false
config.window_decorations = 'RESIZE'
config.use_fancy_tab_bar = false
config.native_macos_fullscreen_mode = true

return config