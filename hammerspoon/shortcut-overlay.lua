-- Shortcut Overlay for Hammerspoon (Production Version)
-- Shows keyboard shortcuts when holding a modifier key (default: Command)
-- FOSS alternative to CheatSheet
-- Detects left vs right Command key for side-specific display

local shortcutOverlay = {}
local overlayWindow = nil
local modifierTimer = nil
local isShowing = false
local lastModifierState = false
local holdStartTime = nil
local pollTimer = nil
local commandSide = nil  -- "left" or "right"
local eventTap = nil  -- For detecting left vs right Command key

-- Configuration
local config = {
    modifier = "cmd",  -- Default modifier to monitor
    delay = 0.3,       -- Delay in seconds before showing overlay
}

-- Define all shortcuts (only exact combinations)
local shortcuts = {
    cmd = {
        title = "Command ⌘ Shortcuts",
        shortcuts = {
            {key = "Space", desc = "Spotlight / Alfred"},
            {key = "Tab", desc = "Switch applications"},
            {key = "Q", desc = "Quit application"},
            {key = "W", desc = "Close window"},
            {key = "H", desc = "Hide application"},
            {key = "M", desc = "Minimize window"},
            {key = "N", desc = "New window"},
            {key = "T", desc = "New tab"},
            {key = "S", desc = "Save"},
            {key = "A", desc = "Select all"},
            {key = "C", desc = "Copy"},
            {key = "V", desc = "Paste"},
            {key = "X", desc = "Cut"},
            {key = "Z", desc = "Undo"},
            {key = "Shift+Z", desc = "Redo"},
        }
    },
    cmdAlt = {
        title = "Command+Option ⌘⌥ Shortcuts",
        shortcuts = {
            {key = "T", desc = "Home Assistant: Toggle TV"},
            {key = "1", desc = "Home Assistant: TV Volume 1%"},
            {key = "2", desc = "Home Assistant: TV Volume 25%"},
            {key = "3", desc = "Home Assistant: TV Volume 50%"},
            {key = "5", desc = "Home Assistant: TV Volume 5%"},
            {key = "H", desc = "Home Assistant: TV Home"},
            {key = "B", desc = "Home Assistant: TV Back"},
            {key = "I", desc = "Home Assistant: TV HDMI 1"},
            {key = "O", desc = "Home Assistant: TV HDMI 2"},
            {key = "D", desc = "Home Assistant: Check dock status"},
        }
    },
    alt = {
        title = "Option ⌥ Shortcuts",
        shortcuts = {
            {key = "Tab", desc = "Switch windows"},
            {key = "H", desc = "Hide others"},
            {key = "M", desc = "Minimize all"},
            {key = "Space", desc = "Character viewer"},
        }
    },
    ctrl = {
        title = "Control ⌃ Shortcuts",
        shortcuts = {
            {key = "Space", desc = "Input source"},
            {key = "A", desc = "Beginning of line"},
            {key = "E", desc = "End of line"},
        }
    },
}

-- Get currently pressed modifier(s) and detect which Command key
local function getPressedModifiers()
    local flags = hs.eventtap.checkKeyboardModifiers()
    if not flags then
        return nil, false, {}
    end
    
    local pressed = {}
    if flags.cmd == true then table.insert(pressed, "cmd") end
    if flags.alt == true then table.insert(pressed, "alt") end
    if flags.ctrl == true then table.insert(pressed, "ctrl") end
    -- Don't include shift - we don't want to trigger on shift
    
    local primary = pressed[1]  -- First modifier pressed
    local anyPressed = #pressed > 0
    
    return primary, anyPressed, pressed
end

-- Check if modifier is pressed (excluding Shift)
local function isModifierPressed()
    local primary, anyPressed, pressed = getPressedModifiers()
    if not anyPressed then
        return false
    end
    
    -- Don't trigger on Shift alone
    if primary == "shift" then
        return false
    end
    
    return anyPressed
end

-- Get shortcuts for exact modifier combination
local function getShortcutsForModifiers(allModifiers)
    local modifierKey = table.concat(allModifiers, "")
    
    if modifierKey == "cmdalt" or modifierKey == "altcmd" then
        return shortcuts.cmdAlt
    elseif modifierKey == "cmd" then
        return shortcuts.cmd
    elseif modifierKey == "alt" then
        return shortcuts.alt
    elseif modifierKey == "ctrl" then
        return shortcuts.ctrl
    else
        -- Default: return empty
        return {title = "No shortcuts", shortcuts = {}}
    end
end

-- Create overlay window (left or right based on Command key side)
local function createOverlay()
    if overlayWindow then
        overlayWindow:delete()
    end
    
    local _, _, allModifiers = getPressedModifiers()
    
    -- Don't show if only Shift is pressed
    if #allModifiers == 0 or (allModifiers[1] == "shift" and #allModifiers == 1) then
        return
    end
    
    local shortcutSet = getShortcutsForModifiers(allModifiers)
    
    -- Don't show if no shortcuts
    if #shortcutSet.shortcuts == 0 then
        return
    end
    
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    
    -- Sidebar width
    local width = math.min(screenFrame.w * 0.25, 400)
    local height = screenFrame.h
    
    -- Determine position based on Command key side (default to left if not Command)
    local isRightSide = (commandSide == "right")
    local x = isRightSide and (screenFrame.x + screenFrame.w - width) or screenFrame.x
    local y = screenFrame.y
    
    -- Build HTML content with transparency and side-specific styling
    local html = string.format([[
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body {
                width: 100%%;
                height: 100%%;
                background: transparent;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Helvetica Neue', Arial, sans-serif;
                background: transparent;
                color: rgba(255, 255, 255, 0.95);
                padding: 0;
                overflow: hidden;
            }
            .glass-container {
                background: rgba(28, 28, 30, 0.75);
                backdrop-filter: blur(40px) saturate(180%%);
                -webkit-backdrop-filter: blur(40px) saturate(180%%);
                %s: 1px solid rgba(255, 255, 255, 0.1);
                padding: 20px 16px;
                height: 100%%;
                overflow-y: auto;
            }
            .section-title {
                font-size: 16px;
                font-weight: 600;
                color: rgba(255, 255, 255, 0.95);
                margin-bottom: 16px;
                padding-bottom: 8px;
                border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                text-align: %s;
            }
            .shortcut-list {
                display: flex;
                flex-direction: column;
                gap: 6px;
            }
            .shortcut-item {
                display: flex;
                align-items: center;
                flex-direction: %s;
                padding: 8px 12px;
                background: rgba(255, 255, 255, 0.05);
                border-radius: 8px;
                border-%s: 2px solid rgba(255, 255, 255, 0.15);
                transition: all 0.15s ease;
            }
            .shortcut-item:hover {
                background: rgba(255, 255, 255, 0.1);
                border-%s-color: rgba(255, 255, 255, 0.3);
            }
            .key {
                font-family: 'SF Mono', Monaco, 'Courier New', monospace;
                background: rgba(255, 255, 255, 0.15);
                color: rgba(255, 255, 255, 0.95);
                padding: 4px 10px;
                border-radius: 6px;
                font-weight: 500;
                font-size: 11px;
                margin-%s: 12px;
                min-width: 60px;
                text-align: center;
                border: 1px solid rgba(255, 255, 255, 0.2);
            }
            .desc {
                flex: 1;
                font-size: 12px;
                color: rgba(255, 255, 255, 0.85);
                letter-spacing: -0.1px;
                text-align: %s;
            }
        </style>
    </head>
    <body>
        <div class="glass-container">
            <div class="section-title">%s</div>
            <div class="shortcut-list">
    ]], 
    isRightSide and "border-left" or "border-right",
    isRightSide and "right" or "left",
    isRightSide and "row-reverse" or "row",
    isRightSide and "right" or "left",
    isRightSide and "right" or "left",
    isRightSide and "left" or "right",
    isRightSide and "right" or "left",
    shortcutSet.title)
    
    local function escapeHtml(text)
        return tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
    end
    
    -- Add shortcuts
    for _, shortcut in ipairs(shortcutSet.shortcuts) do
        html = html .. string.format(
            '<div class="shortcut-item"><div class="key">%s</div><div class="desc">%s</div></div>',
            escapeHtml(shortcut.key),
            escapeHtml(shortcut.desc)
        )
    end
    
    html = html .. [[
            </div>
        </div>
    </body>
    </html>
    ]]
    
    -- Create window with transparency
    local success, webview = pcall(function()
        return hs.webview.new({
            x = x,
            y = y,
            w = width,
            h = height
        })
        :windowStyle("utility")
        :level(hs.drawing.windowLevels.overlay)
        :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces + hs.drawing.windowBehaviors.stationary)
        :allowTextEntry(false)
        :shadow(false)
        :alpha(0.98)  -- Slight transparency
    end)
    
    if not success then
        local errorMsg = "Failed to create overlay window: " .. tostring(webview)
        print("ERROR: Shortcut Overlay - " .. errorMsg)
        hs.notify.new({
            title = "Shortcut Overlay Error",
            informativeText = errorMsg
        }):send()
        return
    end
    
    overlayWindow = webview
    overlayWindow:html(html)
    overlayWindow:show()
end

-- Show overlay
local function showOverlay()
    if isShowing then return end
    isShowing = true
    createOverlay()
end

-- Hide overlay
local function hideOverlay()
    if not isShowing then return end
    isShowing = false
    if overlayWindow then
        overlayWindow:delete()
        overlayWindow = nil
    end
    if modifierTimer then
        modifierTimer:stop()
        modifierTimer = nil
    end
    holdStartTime = nil
    commandSide = nil
end

-- Detect which Command key is pressed (left = 55, right = 54)
local function setupCommandSideDetection()
    if eventTap then
        eventTap:stop()
        eventTap = nil
    end
    
    -- Track Command key presses to determine which side
    -- Only listen to keyDown events for Command keys specifically (55, 54)
    -- This should not interfere with Caps Lock (57) or other keys
    eventTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local keyCode = event:getKeyCode()
        
        -- Only process Command keys, ignore everything else
        -- Left Command = 55, Right Command = 54
        if keyCode == 55 then
            commandSide = "left"
        elseif keyCode == 54 then
            commandSide = "right"
        end
        -- For all other keys (including Caps Lock = 57), do nothing
        
        return false  -- Never consume events - let them pass through
    end)
    
    -- Only start if we successfully created the tap
    if eventTap then
        eventTap:start()
    end
end

-- Polling-based modifier monitoring
local function monitorModifier()
    local lastPrimaryModifier = nil
    local lastModifierCount = 0
    
    pollTimer = hs.timer.doEvery(0.05, function()  -- Check every 50ms
        local primaryModifier, currentlyPressed, allModifiers = getPressedModifiers()
        local modifierCount = allModifiers and #allModifiers or 0
        
        -- Don't trigger on Shift alone
        if primaryModifier == "shift" and modifierCount == 1 then
            currentlyPressed = false
        end
        
        if currentlyPressed and not lastModifierState then
            -- Modifier just pressed
            holdStartTime = os.time()
            lastModifierState = true
            lastPrimaryModifier = primaryModifier
            lastModifierCount = modifierCount
            
            -- Start delay timer
            if modifierTimer then
                modifierTimer:stop()
            end
            modifierTimer = hs.timer.doAfter(config.delay, function()
                -- Check if still pressed after delay
                local stillPressed = isModifierPressed()
                if stillPressed then
                    showOverlay()
                end
            end)
            
        elseif currentlyPressed and lastModifierState then
            -- Check if modifier combination changed (e.g., added Alt to Command)
            if modifierCount ~= lastModifierCount or primaryModifier ~= lastPrimaryModifier then
                lastPrimaryModifier = primaryModifier
                lastModifierCount = modifierCount
                -- Update overlay with new shortcuts
                if isShowing then
                    createOverlay()  -- Recreate with updated shortcuts
                end
            end
            
        elseif not currentlyPressed and lastModifierState then
            -- Modifier just released
            lastModifierState = false
            lastPrimaryModifier = nil
            lastModifierCount = 0
            holdStartTime = nil
            
            -- Cancel timer if still running
            if modifierTimer then
                modifierTimer:stop()
                modifierTimer = nil
            end
            
            -- Hide overlay immediately
            hideOverlay()
        end
    end)
    
    return {timer = pollTimer}
end

-- Initialize
local modifierMonitor = nil

function shortcutOverlay.start()
    if modifierMonitor then
        shortcutOverlay.stop()
    end
    setupCommandSideDetection()
    modifierMonitor = monitorModifier()
end

function shortcutOverlay.stop()
    hideOverlay()
    if eventTap then
        eventTap:stop()
        eventTap = nil
    end
    if modifierMonitor and modifierMonitor.timer then
        modifierMonitor.timer:stop()
        modifierMonitor = nil
    end
    if pollTimer then
        pollTimer:stop()
        pollTimer = nil
    end
    lastModifierState = false
end

function shortcutOverlay.toggle()
    if modifierMonitor then
        shortcutOverlay.stop()
    else
        shortcutOverlay.start()
    end
end

function shortcutOverlay.show()
    showOverlay()
end

function shortcutOverlay.hide()
    hideOverlay()
end

function shortcutOverlay.setModifier(modifier)
    config.modifier = modifier
    if modifierMonitor then
        shortcutOverlay.stop()
        shortcutOverlay.start()
    end
end

-- Auto-start with error handling
local success, err = pcall(function()
    shortcutOverlay.start()
end)
if not success then
    local errorMsg = "Failed to start: " .. tostring(err)
    print("ERROR: Shortcut Overlay - " .. errorMsg)
    hs.notify.new({
        title = "Shortcut Overlay Error", 
        informativeText = errorMsg
    }):send()
end

return shortcutOverlay
