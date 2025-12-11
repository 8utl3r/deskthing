-- Diagnostic Test Script for Shortcut Overlay
-- Tests each component independently to identify issues

local testResults = {
    permissions = "UNKNOWN",
    eventtap = "UNKNOWN",
    modifierDetection = "UNKNOWN",
    windowCreation = "UNKNOWN",
    timer = "UNKNOWN",
    checkKeyboardModifiers = "UNKNOWN"
}

local function logTest(testName, result, details)
    local status = result and "PASS" or "FAIL"
    print(string.format("[TEST] %s: %s", testName, status))
    if details then
        print("  Details: " .. hs.inspect(details))
    end
    return result
end

-- Test 1: Check Accessibility Permissions
local function testPermissions()
    print("\n=== TEST 1: Accessibility Permissions ===")
    
    -- Try to create a simple eventtap
    local success, tap = pcall(function()
        return hs.eventtap.new({hs.eventtap.event.types.keyDown}, function() return false end)
    end)
    
    if success then
        local startSuccess, startErr = pcall(function()
            tap:start()
            tap:stop()
        end)
        
        if startSuccess then
            testResults.permissions = "PASS"
            return logTest("Permissions", true, "EventTap can be created and started")
        else
            testResults.permissions = "FAIL"
            return logTest("Permissions", false, {error = startErr})
        end
    else
        testResults.permissions = "FAIL"
        return logTest("Permissions", false, {error = tap})
    end
end

-- Test 2: Test checkKeyboardModifiers()
local function testCheckKeyboardModifiers()
    print("\n=== TEST 2: checkKeyboardModifiers() ===")
    
    local success, flags = pcall(function()
        return hs.eventtap.checkKeyboardModifiers()
    end)
    
    if success then
        testResults.checkKeyboardModifiers = "PASS"
        return logTest("checkKeyboardModifiers", true, {
            currentFlags = flags,
            cmd = flags.cmd or false,
            alt = flags.alt or false,
            ctrl = flags.ctrl or false,
            shift = flags.shift or false
        })
    else
        testResults.checkKeyboardModifiers = "FAIL"
        return logTest("checkKeyboardModifiers", false, {error = flags})
    end
end

-- Test 3: EventTap Receiving Events
local function testEventTap()
    print("\n=== TEST 3: EventTap Receiving Events ===")
    print("Hold Command key now - you should see events logged...")
    
    local eventCount = 0
    local receivedFlagsChanged = false
    
    local tap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
        eventCount = eventCount + 1
        receivedFlagsChanged = true
        local flags = event:getFlags()
        print(string.format("  [Event #%d] Flags: %s", eventCount, hs.inspect(flags)))
        return false
    end)
    
    local startSuccess, startErr = pcall(function()
        tap:start()
    end)
    
    if not startSuccess then
        testResults.eventtap = "FAIL"
        return logTest("EventTap Start", false, {error = startErr})
    end
    
    -- Wait 3 seconds for user to press Command
    hs.timer.doAfter(3, function()
        tap:stop()
        if eventCount > 0 then
            testResults.eventtap = "PASS"
            logTest("EventTap Events", true, {eventCount = eventCount, receivedFlagsChanged = receivedFlagsChanged})
        else
            testResults.eventtap = "FAIL"
            logTest("EventTap Events", false, {message = "No events received in 3 seconds - try holding Command key"})
        end
    end)
    
    return true
end

-- Test 4: Window Creation
local function testWindowCreation()
    print("\n=== TEST 4: Window Creation ===")
    
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    local width = screenFrame.w * 0.6
    local height = screenFrame.h * 0.7
    local x = screenFrame.x + (screenFrame.w - width) / 2
    local y = screenFrame.y + (screenFrame.h - height) / 2
    
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
        :shadow(true)
    end)
    
    if success then
        testResults.windowCreation = "PASS"
        logTest("Window Creation", true, {webview = webview})
        
        -- Test showing window
        webview:html("<html><body style='background: red; color: white; padding: 50px; font-size: 24px;'>TEST WINDOW - If you see this, window creation works!</body></html>")
        webview:show()
        
        print("  Window should be visible now (red background)")
        print("  Press any key to close test window...")
        
        -- Close after 5 seconds
        hs.timer.doAfter(5, function()
            webview:delete()
            print("  Test window closed")
        end)
        
        return true
    else
        testResults.windowCreation = "FAIL"
        return logTest("Window Creation", false, {error = webview})
    end
end

-- Test 5: Timer Functionality
local function testTimer()
    print("\n=== TEST 5: Timer Functionality ===")
    
    local timerFired = false
    
    local timer = hs.timer.doAfter(1, function()
        timerFired = true
        print("  Timer fired after 1 second")
    end)
    
    if timer then
        print("  Timer created, waiting 1.5 seconds...")
        hs.timer.doAfter(1.5, function()
            if timerFired then
                testResults.timer = "PASS"
                logTest("Timer", true, {fired = true})
            else
                testResults.timer = "FAIL"
                logTest("Timer", false, {fired = false})
            end
        end)
        return true
    else
        testResults.timer = "FAIL"
        return logTest("Timer", false, {error = "Failed to create timer"})
    end
end

-- Test 6: Modifier Detection Logic
local function testModifierDetection()
    print("\n=== TEST 6: Modifier Detection Logic ===")
    print("Testing modifier detection with current keyboard state...")
    
    local flags = hs.eventtap.checkKeyboardModifiers()
    local cmdPressed = flags.cmd or false
    local altPressed = flags.alt or false
    local ctrlPressed = flags.ctrl or false
    local shiftPressed = flags.shift or false
    
    print("  Current modifier state:")
    print("    Cmd: " .. tostring(cmdPressed))
    print("    Alt: " .. tostring(altPressed))
    print("    Ctrl: " .. tostring(ctrlPressed))
    print("    Shift: " .. tostring(shiftPressed))
    
    -- Test detection logic for "cmd" modifier
    local shouldShow = cmdPressed and not altPressed and not ctrlPressed and not shiftPressed
    
    print("  Detection logic (cmd alone): " .. tostring(shouldShow))
    print("  Hold Command key alone and run this test again to verify")
    
    testResults.modifierDetection = "PASS"
    return logTest("Modifier Detection", true, {
        flags = flags,
        shouldShow = shouldShow,
        logic = "cmd && !alt && !ctrl && !shift"
    })
end

-- Run all tests
local function runAllTests()
    print("\n" .. string.rep("=", 60))
    print("SHORTCUT OVERLAY DIAGNOSTIC TESTS")
    print(string.rep("=", 60))
    
    testPermissions()
    hs.timer.doAfter(0.5, function()
        testCheckKeyboardModifiers()
        hs.timer.doAfter(0.5, function()
            testEventTap()
            hs.timer.doAfter(4, function()
                testWindowCreation()
                hs.timer.doAfter(6, function()
                    testTimer()
                    hs.timer.doAfter(2, function()
                        testModifierDetection()
                        hs.timer.doAfter(1, function()
                            print("\n" .. string.rep("=", 60))
                            print("TEST SUMMARY")
                            print(string.rep("=", 60))
                            for test, result in pairs(testResults) do
                                print(string.format("  %s: %s", test, result))
                            end
                            print(string.rep("=", 60))
                        end)
                    end)
                end)
            end)
        end)
    end)
end

-- Export test functions
local testModule = {
    runAll = runAllTests,
    testPermissions = testPermissions,
    testCheckKeyboardModifiers = testCheckKeyboardModifiers,
    testEventTap = testEventTap,
    testWindowCreation = testWindowCreation,
    testTimer = testTimer,
    testModifierDetection = testModifierDetection,
    results = testResults
}

return testModule
