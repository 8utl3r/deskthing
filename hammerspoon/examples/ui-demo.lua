-- Hammerspoon UI Elements Demo
-- Shows all available UI components that Hammerspoon can create
-- Trigger with Hyper+D (Caps Lock + D)

local uiDemo = {}
local demoWindows = {}
local demoElements = {}

-- Clean up all demo elements
local function cleanup()
    for _, element in ipairs(demoElements) do
        if element and element.delete then
            pcall(function() element:delete() end)
        end
    end
    demoElements = {}
    
    for _, win in pairs(demoWindows) do
        if win and win.delete then
            pcall(function() win:delete() end)
        end
    end
    demoWindows = {}
end

-- Show all UI demos
function uiDemo.show()
    cleanup()
    
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    
    -- Calculate grid layout (3x3)
    local cols = 3
    local rows = 3
    local cellWidth = screenFrame.w / cols
    local cellHeight = screenFrame.h / rows
    
    local demoIndex = 0
    
    -- Helper to get cell position
    local function getCellPos(row, col)
        return {
            x = screenFrame.x + col * cellWidth,
            y = screenFrame.y + row * cellHeight,
            w = cellWidth,
            h = cellHeight
        }
    end
    
    -- 1. hs.webview - HTML/CSS/JS Window (Top Left)
    demoIndex = demoIndex + 1
    local pos = getCellPos(0, 0)
    local webview = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :allowTextEntry(false)
    :shadow(true)
    
    webview:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {
                font-family: -apple-system, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px;
                margin: 0;
                height: 100%;
                box-sizing: border-box;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            p { margin: 5px 0; font-size: 12px; }
            .feature { background: rgba(255,255,255,0.2); padding: 8px; margin: 5px 0; border-radius: 5px; }
        </style>
    </head>
    <body>
        <h1>hs.webview</h1>
        <div class="feature">✓ HTML/CSS/JS</div>
        <div class="feature">✓ Full web capabilities</div>
        <div class="feature">✓ Transparent backgrounds</div>
        <div class="feature">✓ Interactive content</div>
        <p>This is what the shortcut overlay uses!</p>
    </body>
    </html>
    ]])
    webview:show()
    table.insert(demoElements, webview)
    demoWindows.webview = webview
    
    -- 2. hs.canvas - Advanced Drawing API (Top Center)
    demoIndex = demoIndex + 1
    pos = getCellPos(0, 1)
    local canvas = hs.canvas.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :show()
    
    -- Add various canvas elements
    canvas:appendElements(
        -- Background
        {
            type = "rectangle",
            action = "fill",
            fillColor = {red = 0.2, green = 0.4, blue = 0.6, alpha = 0.8},
            frame = {x = 0, y = 0, w = "100%", h = "100%"}
        },
        -- Title
        {
            type = "text",
            text = "hs.canvas",
            textSize = 18,
            textColor = {red = 1, green = 1, blue = 1, alpha = 1},
            frame = {x = 10, y = 10, w = "100%", h = 30}
        },
        -- Circle
        {
            type = "circle",
            action = "fill",
            fillColor = {red = 1, green = 0.5, blue = 0, alpha = 0.7},
            center = {x = pos.w/2 - 30, y = 80},
            radius = 25
        },
        -- Rectangle
        {
            type = "rectangle",
            action = "fill",
            fillColor = {red = 0, green = 0.8, blue = 0.4, alpha = 0.7},
            frame = {x = pos.w/2 + 10, y = 60, w = 50, h = 40},
            roundedRectRadii = {xRadius = 5, yRadius = 5}
        },
        -- Line
        {
            type = "segments",
            action = "stroke",
            strokeColor = {red = 1, green = 1, blue = 0, alpha = 1},
            strokeWidth = 3,
            coordinates = {{x = 20, y = 120}, {x = pos.w - 20, y = 120}}
        },
        -- Text
        {
            type = "text",
            text = "Shapes, text, images",
            textSize = 12,
            textColor = {red = 1, green = 1, blue = 1, alpha = 0.9},
            frame = {x = 10, y = 140, w = "100%", h = 30}
        }
    )
    
    table.insert(demoElements, canvas)
    demoWindows.canvas = canvas
    
    -- 3. hs.drawing - Basic Drawing (Top Right)
    demoIndex = demoIndex + 1
    pos = getCellPos(0, 2)
    
    local drawingRect = hs.drawing.rectangle({
        x = pos.x + 20,
        y = pos.y + 20,
        w = pos.w - 40,
        h = pos.h - 40
    })
    drawingRect:setFillColor({red = 0.8, green = 0.2, blue = 0.4, alpha = 0.7})
    drawingRect:setStrokeColor({red = 1, green = 1, blue = 1, alpha = 1})
    drawingRect:setStrokeWidth(2)
    drawingRect:setRoundedRectRadii(10, 10)
    drawingRect:setLevel(hs.drawing.windowLevels.overlay)
    drawingRect:show()
    
    local drawingText = hs.drawing.text({
        x = pos.x + 30,
        y = pos.y + 30,
        w = pos.w - 60,
        h = 50
    }, "hs.drawing\nBasic primitives\n(Deprecated)")
    drawingText:setTextColor({red = 1, green = 1, blue = 1, alpha = 1})
    drawingText:setTextSize(14)
    drawingText:setLevel(hs.drawing.windowLevels.overlay)
    drawingText:show()
    
    table.insert(demoElements, drawingRect)
    table.insert(demoElements, drawingText)
    demoWindows.drawing = {rect = drawingRect, text = drawingText}
    
    -- 4. hs.alert - Alert Messages (Middle Left)
    demoIndex = demoIndex + 1
    pos = getCellPos(1, 0)
    
    -- Show multiple alerts in sequence
    hs.alert.show("hs.alert - Simple alerts", 2, {fillColor = {red = 0.2, green = 0.6, blue = 0.8, alpha = 0.9}})
    
    -- Create a webview to show alert info (since alerts disappear)
    local alertInfo = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    
    alertInfo:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {
                font-family: -apple-system, sans-serif;
                background: rgba(0.2, 0.6, 0.8, 0.9);
                color: white;
                padding: 20px;
                margin: 0;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            .feature { background: rgba(255,255,255,0.2); padding: 5px; margin: 3px 0; border-radius: 3px; }
        </style>
    </head>
    <body>
        <h1>hs.alert</h1>
        <div class="feature">Temporary messages</div>
        <div class="feature">Auto-dismiss</div>
        <div class="feature">Customizable colors</div>
        <div class="feature">Screen positioning</div>
    </body>
    </html>
    ]])
    alertInfo:show()
    table.insert(demoElements, alertInfo)
    demoWindows.alert = alertInfo
    
    -- 5. hs.chooser - Searchable Chooser (Middle Center)
    demoIndex = demoIndex + 1
    pos = getCellPos(1, 1)
    
    local chooserInfo = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    
    chooserInfo:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {
                font-family: -apple-system, sans-serif;
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                color: white;
                padding: 20px;
                margin: 0;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            .feature { background: rgba(255,255,255,0.2); padding: 5px; margin: 3px 0; border-radius: 3px; }
            button {
                background: rgba(255,255,255,0.3);
                border: 1px solid rgba(255,255,255,0.5);
                color: white;
                padding: 8px 16px;
                border-radius: 5px;
                cursor: pointer;
                margin-top: 10px;
                font-size: 12px;
            }
            button:hover { background: rgba(255,255,255,0.4); }
        </style>
    </head>
    <body>
        <h1>hs.chooser</h1>
        <div class="feature">Searchable list</div>
        <div class="feature">Keyboard navigation</div>
        <div class="feature">Custom callbacks</div>
        <div class="feature">Like Alfred/Spotlight</div>
        <button onclick="window.webkit.messageHandlers.chooser.postMessage('show')">Test Chooser</button>
    </body>
    </html>
    ]])
    
    -- Add chooser callback
    chooserInfo:urlCallback(function(message)
        if message == "show" then
            local testChooser = hs.chooser.new(function(choice)
                if choice then
                    hs.alert.show("Selected: " .. choice.text)
                end
            end)
            testChooser:choices({
                {text = "Option 1", subText = "First choice"},
                {text = "Option 2", subText = "Second choice"},
                {text = "Option 3", subText = "Third choice"},
                {text = "Test Item", subText = "Searchable content"},
                {text = "Another Item", subText = "More options"}
            })
            testChooser:show()
        end
    end)
    
    chooserInfo:show()
    table.insert(demoElements, chooserInfo)
    demoWindows.chooser = chooserInfo
    
    -- 6. hs.menubar - Menu Bar Items (Middle Right)
    demoIndex = demoIndex + 1
    pos = getCellPos(1, 2)
    
    local menubarInfo = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    
    menubarInfo:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {
                font-family: -apple-system, sans-serif;
                background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
                color: white;
                padding: 20px;
                margin: 0;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            .feature { background: rgba(255,255,255,0.2); padding: 5px; margin: 3px 0; border-radius: 3px; }
        </style>
    </head>
    <body>
        <h1>hs.menubar</h1>
        <div class="feature">Menu bar icons</div>
        <div class="feature">Click callbacks</div>
        <div class="feature">Dynamic titles</div>
        <div class="feature">Custom menus</div>
        <p style="margin-top: 10px; font-size: 11px;">See menu bar for examples</p>
    </body>
    </html>
    ]])
    menubarInfo:show()
    table.insert(demoElements, menubarInfo)
    demoWindows.menubar = menubarInfo
    
    -- 7. hs.notify - Notifications (Bottom Left)
    demoIndex = demoIndex + 1
    pos = getCellPos(2, 0)
    
    -- Show a notification
    hs.notify.new({
        title = "hs.notify",
        informativeText = "System notifications with custom content",
        contentImage = nil
    }):send()
    
    local notifyInfo = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    
    notifyInfo:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {
                font-family: -apple-system, sans-serif;
                background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
                color: white;
                padding: 20px;
                margin: 0;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            .feature { background: rgba(255,255,255,0.2); padding: 5px; margin: 3px 0; border-radius: 3px; }
        </style>
    </head>
    <body>
        <h1>hs.notify</h1>
        <div class="feature">System notifications</div>
        <div class="feature">Custom content</div>
        <div class="feature">Action buttons</div>
        <div class="feature">Sound support</div>
        <p style="margin-top: 10px; font-size: 11px;">Check notification center</p>
    </body>
    </html>
    ]])
    notifyInfo:show()
    table.insert(demoElements, notifyInfo)
    demoWindows.notify = notifyInfo
    
    -- 8. hs.hotkey.modal - Modal Hotkeys (Bottom Center)
    demoIndex = demoIndex + 1
    pos = getCellPos(2, 1)
    
    local modalInfo = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    
    modalInfo:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {
                font-family: -apple-system, sans-serif;
                background: linear-gradient(135deg, #30cfd0 0%, #330867 100%);
                color: white;
                padding: 20px;
                margin: 0;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            .feature { background: rgba(255,255,255,0.2); padding: 5px; margin: 3px 0; border-radius: 3px; }
        </style>
    </head>
    <body>
        <h1>hs.hotkey.modal</h1>
        <div class="feature">Temporary key modes</div>
        <div class="feature">Context-sensitive</div>
        <div class="feature">Auto-exit</div>
        <div class="feature">Visual indicators</div>
        <p style="margin-top: 10px; font-size: 11px;">Like vim modes</p>
    </body>
    </html>
    ]])
    modalInfo:show()
    table.insert(demoElements, modalInfo)
    demoWindows.modal = modalInfo
    
    -- 9. Transparency & Effects Demo (Bottom Right)
    demoIndex = demoIndex + 1
    pos = getCellPos(2, 2)
    
    local transparencyDemo = hs.webview.new({
        x = pos.x + 10,
        y = pos.y + 10,
        w = pos.w - 20,
        h = pos.h - 20
    })
    :windowStyle("utility")
    :level(hs.drawing.windowLevels.overlay)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :alpha(0.95)  -- Window-level transparency
    
    transparencyDemo:html([[
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body {
                width: 100%;
                height: 100%;
                background: transparent;
            }
            body {
                font-family: -apple-system, sans-serif;
                color: white;
                padding: 20px;
                background: rgba(0, 0, 0, 0);
            }
            .glass {
                background: rgba(28, 28, 30, 0.7);
                backdrop-filter: blur(40px) saturate(180%);
                -webkit-backdrop-filter: blur(40px) saturate(180%);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 15px;
                padding: 20px;
                height: 100%;
            }
            h1 { margin: 0 0 10px 0; font-size: 18px; }
            .feature { 
                background: rgba(255,255,255,0.1); 
                padding: 8px; 
                margin: 5px 0; 
                border-radius: 5px;
                border-left: 3px solid rgba(255,255,255,0.3);
            }
        </style>
    </head>
    <body>
        <div class="glass">
            <h1>Transparency Demo</h1>
            <div class="feature">Window alpha: 0.95</div>
            <div class="feature">CSS backdrop-filter</div>
            <div class="feature">rgba backgrounds</div>
            <div class="feature">Glassmorphism effect</div>
            <p style="margin-top: 10px; font-size: 11px; opacity: 0.8;">This is the style used in shortcut overlay</p>
        </div>
    </body>
    </html>
    ]])
    transparencyDemo:show()
    table.insert(demoElements, transparencyDemo)
    demoWindows.transparency = transparencyDemo
    
    -- Show instructions
    hs.alert.show("UI Demo Active - Press Hyper+D again to close", 3)
end

-- Hide all demos
function uiDemo.hide()
    cleanup()
    hs.alert.show("UI Demo Closed", 1)
end

-- Toggle demo
function uiDemo.toggle()
    if #demoElements > 0 then
        uiDemo.hide()
    else
        uiDemo.show()
    end
end

return uiDemo


