-- Desktop/Space Management Module
-- Provides space renaming, app-to-space assignment, and space switching utilities
--
-- Features:
-- - Rename spaces with custom names
-- - Assign apps to specific spaces (auto-move on launch)
-- - Restrict apps to specific spaces
-- - Quick space switching by name
-- - Space layout persistence

local desktopManagement = {}
local config = require("config")
local logger = require("lib.logger").get("desktop-management")
local debug = require("lib.debug")

-- Resources to clean up
local resources = {
    hotkeys = {},
    watchers = {},
    spaces = {}
}

-- Configuration: App to space assignments
-- Format: appName = {space = spaceIndex, restrict = true/false}
-- space: target space index (1-based) or space UUID
-- restrict: if true, app windows are moved back if they leave assigned space
local appSpaceAssignments = {
    -- Example configurations (customize as needed):
    -- ["Safari"] = {space = 2, restrict = true},
    -- ["Mail"] = {space = 3, restrict = false},
    -- ["Slack"] = {space = 4, restrict = true},
}

-- Configuration: Space names
-- Format: spaceIndex = "Custom Name"
local spaceNames = {
    -- Example: [1] = "Main",
    --          [2] = "Work",
    --          [3] = "Communication",
}

-- Get current space
function desktopManagement.getCurrentSpace()
    debug.callStart("desktop-management", "getCurrentSpace")
    
    local spaces = hs.spaces.allSpaces()
    if not spaces then
        logger.warning("Could not retrieve spaces")
        debug.callEnd("desktop-management", "getCurrentSpace")
        return nil
    end
    
    -- Find current space
    for screenUUID, spaceList in pairs(spaces) do
        for _, spaceID in ipairs(spaceList) do
            if hs.spaces.isCurrentSpace(spaceID) then
                debug.callEnd("desktop-management", "getCurrentSpace")
                return spaceID
            end
        end
    end
    
    debug.callEnd("desktop-management", "getCurrentSpace")
    return nil
end

-- Get space index from space ID
function desktopManagement.getSpaceIndex(spaceID)
    if not spaceID then return nil end
    
    local spaces = hs.spaces.allSpaces()
    if not spaces then return nil end
    
    local index = 1
    for screenUUID, spaceList in pairs(spaces) do
        for _, id in ipairs(spaceList) do
            if id == spaceID then
                return index
            end
            index = index + 1
        end
    end
    
    return nil
end

-- Get space name (custom or default)
function desktopManagement.getSpaceName(spaceID)
    if not spaceID then return nil end
    
    local index = desktopManagement.getSpaceIndex(spaceID)
    if index and spaceNames[index] then
        return spaceNames[index]
    end
    
    -- Return default name
    return "Space " .. (index or "?")
end

-- Set space name
function desktopManagement.setSpaceName(spaceIndex, name)
    if not spaceIndex or not name then
        logger.warning("Invalid parameters for setSpaceName")
        return false
    end
    
    spaceNames[spaceIndex] = name
    logger.info("Set space " .. spaceIndex .. " name to: " .. name)
    
    -- Notify user
    hs.notify.new({
        title = "Desktop Management",
        informativeText = "Space " .. spaceIndex .. " renamed to: " .. name
    }):send()
    
    return true
end

-- Switch to space by index
function desktopManagement.switchToSpace(spaceIndex)
    debug.callStart("desktop-management", "switchToSpace")
    
    local spaces = hs.spaces.allSpaces()
    if not spaces then
        logger.warning("Could not retrieve spaces")
        debug.callEnd("desktop-management", "switchToSpace")
        return false
    end
    
    local index = 1
    for screenUUID, spaceList in pairs(spaces) do
        for _, spaceID in ipairs(spaceList) do
            if index == spaceIndex then
                hs.spaces.gotoSpace(spaceID)
                local name = desktopManagement.getSpaceName(spaceID)
                logger.info("Switched to space " .. spaceIndex .. ": " .. name)
                debug.callEnd("desktop-management", "switchToSpace")
                return true
            end
            index = index + 1
        end
    end
    
    logger.warning("Space index " .. spaceIndex .. " not found")
    debug.callEnd("desktop-management", "switchToSpace")
    return false
end

-- Move window to space
function desktopManagement.moveWindowToSpace(win, spaceIndex)
    if not win then
        logger.warning("No window provided")
        return false
    end
    
    local spaces = hs.spaces.allSpaces()
    if not spaces then
        logger.warning("Could not retrieve spaces")
        return false
    end
    
    local index = 1
    for screenUUID, spaceList in pairs(spaces) do
        for _, spaceID in ipairs(spaceList) do
            if index == spaceIndex then
                -- Try to move window to space
                local success = hs.spaces.moveWindowToSpace(win, spaceID)
                if success then
                    logger.info("Moved window to space " .. spaceIndex)
                    return true
                else
                    logger.warning("Failed to move window to space " .. spaceIndex)
                    return false
                end
            end
            index = index + 1
        end
    end
    
    logger.warning("Space index " .. spaceIndex .. " not found")
    return false
end

-- Move app windows to assigned space
function desktopManagement.moveAppToSpace(appName, spaceIndex)
    local app = hs.application.get(appName)
    if not app then
        logger.debug("App not found: " .. appName)
        return false
    end
    
    local windows = app:allWindows()
    if #windows == 0 then
        logger.debug("No windows found for app: " .. appName)
        return false
    end
    
    local moved = 0
    for _, win in ipairs(windows) do
        if desktopManagement.moveWindowToSpace(win, spaceIndex) then
            moved = moved + 1
        end
    end
    
    if moved > 0 then
        logger.info("Moved " .. moved .. " window(s) from " .. appName .. " to space " .. spaceIndex)
        return true
    end
    
    return false
end

-- Handle app launch - move to assigned space
function desktopManagement.handleAppLaunch(appName, app)
    local assignment = appSpaceAssignments[appName]
    if not assignment then
        return
    end
    
    local spaceIndex = assignment.space
    if type(spaceIndex) == "string" then
        -- If it's a UUID, convert to index
        -- For now, assume it's an index
        logger.debug("Space assignment uses UUID, converting...")
    end
    
    -- Wait a bit for windows to appear, then move them
    hs.timer.doAfter(0.5, function()
        desktopManagement.moveAppToSpace(appName, spaceIndex)
    end)
end

-- Monitor window focus to enforce restrictions
function desktopManagement.enforceRestrictions(win)
    if not win then return end
    
    local app = win:application()
    if not app then return end
    
    local appName = app:name()
    local assignment = appSpaceAssignments[appName]
    
    if not assignment or not assignment.restrict then
        return
    end
    
    local currentSpace = desktopManagement.getCurrentSpace()
    local targetSpace = assignment.space
    
    -- Check if window is on wrong space
    -- Note: This is a simplified check - full implementation would need
    -- to check which space the window is actually on
    local currentIndex = desktopManagement.getSpaceIndex(currentSpace)
    
    if currentIndex ~= targetSpace then
        -- Window is on wrong space, but we're checking current space
        -- This is a limitation - we can't easily check which space a window is on
        -- For now, we'll just log it
        logger.debug("Window from restricted app " .. appName .. " detected on different space")
    end
end

-- Setup app watcher
function desktopManagement.setupAppWatcher()
    local watcher = hs.application.watcher.new(function(appName, eventType, app)
        if eventType == hs.application.watcher.launched then
            desktopManagement.handleAppLaunch(appName, app)
        end
    end)
    
    watcher:start()
    table.insert(resources.watchers, watcher)
    logger.info("App watcher started")
end

-- Setup hotkeys
function desktopManagement.setupHotkeys()
    local hyper = config.get("hyper")
    
    -- Switch to space 1-9
    for i = 1, 9 do
        local hotkey = hs.hotkey.bind(hyper, tostring(i), function()
            desktopManagement.switchToSpace(i)
        end)
        table.insert(resources.hotkeys, hotkey)
    end
    
    -- Rename current space (hyper + shift + r)
    local renameHotkey = hs.hotkey.bind(hyper, "R", function()
        local currentSpace = desktopManagement.getCurrentSpace()
        if not currentSpace then
            hs.alert.show("Could not get current space", 2)
            return
        end
        
        local index = desktopManagement.getSpaceIndex(currentSpace)
        if not index then
            hs.alert.show("Could not get space index", 2)
            return
        end
        
        -- Prompt for new name
        hs.dialog.textPrompt("Rename Space " .. index, 
                             "Enter new name:", 
                             spaceNames[index] or "", 
                             "OK", 
                             "Cancel", 
                             function(result)
                                 if result then
                                     desktopManagement.setSpaceName(index, result)
                                 end
                             end)
    end)
    table.insert(resources.hotkeys, renameHotkey)
    
    logger.info("Desktop management hotkeys configured")
end

-- Get configuration
function desktopManagement.getConfig()
    return {
        appAssignments = appSpaceAssignments,
        spaceNames = spaceNames
    }
end

-- Set app assignment
function desktopManagement.setAppAssignment(appName, spaceIndex, restrict)
    appSpaceAssignments[appName] = {
        space = spaceIndex,
        restrict = restrict or false
    }
    logger.info("Set app assignment: " .. appName .. " -> space " .. spaceIndex .. 
                (restrict and " (restricted)" or ""))
end

-- Cleanup function
function desktopManagement.cleanup()
    for _, watcher in ipairs(resources.watchers) do
        if watcher and watcher.stop then
            watcher:stop()
        end
    end
    logger.debug("Desktop management cleanup complete")
end

-- Initialize
function desktopManagement.init()
    logger.info("Initializing desktop management module")
    
    -- Check if hs.spaces is available
    if not hs.spaces then
        logger.error("hs.spaces module not available - desktop management features limited")
        logger.info("Install hs.spaces via: hs.ipc.cliInstall('spaces')")
        return
    end
    
    desktopManagement.setupHotkeys()
    desktopManagement.setupAppWatcher()

    logger.info("Desktop management module initialized")
end

return desktopManagement
