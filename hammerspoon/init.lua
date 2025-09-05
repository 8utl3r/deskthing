-- Simple test configuration for Hammerspoon
hs.notify.new({title = "Hammerspoon", informativeText = "Test configuration loaded"}):send()

-- Simple menubar test
local testMenu = hs.menubar.new()
testMenu:setTitle("TEST")
testMenu:setClickCallback(function()
    hs.notify.new({title = "Test", informativeText = "Menu clicked"}):send()
end)
