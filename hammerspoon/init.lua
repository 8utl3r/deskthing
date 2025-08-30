local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Reload config
hs.hotkey.bind(hyper, "r", function()
  hs.reload()
  hs.notify.new({title = "Hammerspoon", informativeText = "Config reloaded"}):send()
end)

-- Quick app launchers (adjust to taste)
local apps = {
  t = "WezTerm",
  c = "Cursor",
  b = "Mullvad Browser",
  f = "Finder",
}
for key, app in pairs(apps) do
  hs.hotkey.bind(hyper, key, function() hs.application.launchOrFocus(app) end)
end

-- Move window to next screen
hs.hotkey.bind(hyper, "n", function()
  local win = hs.window.focusedWindow()
  if win then win:moveToScreen(win:screen():next()) end
end)

-- Center window and size to 70%
hs.hotkey.bind(hyper, "space", function()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen()
  local max = screen:frame()
  local w = max.w * 0.7
  local h = max.h * 0.7
  local x = max.x + (max.w - w) / 2
  local y = max.y + (max.h - h) / 2
  win:setFrame({x = x, y = y, w = w, h = h})
end)

-- Prevent sleep toggle (menubar)
local caffeine = hs.menubar.new()
local function setCaffeine(state)
  caffeine:setTitle(state and "AWAKE" or "SLEEP")
end
if caffeine then
  caffeine:setClickCallback(function()
    setCaffeine(hs.caffeinate.toggle("displayIdle"))
  end)
  setCaffeine(hs.caffeinate.get("displayIdle"))
end
