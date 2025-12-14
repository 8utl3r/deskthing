-- Audio Info Module
-- Displays detailed audio output information in menu bar

local audioInfo = {}
local logger = require("lib.logger").get("audio-info")
local debug = require("lib.debug")

-- State
local menuBarItem = nil
local updateTimer = nil
local updateInterval = 2  -- Update every 2 seconds

-- Get audio device information
local function getAudioInfo()
    debug.callStart("audio-info", "getAudioInfo")
    
    local device = hs.audiodevice.defaultOutputDevice()
    if not device then
        logger.warning("No default output device found")
        debug.callEnd("audio-info", "getAudioInfo", nil)
        return nil
    end
    
    -- Safely get device name
    local nameSuccess, deviceName = pcall(function()
        return device:name()
    end)
    local deviceName = (nameSuccess and deviceName) or "Unknown"
    logger.debug("Got audio device: " .. tostring(deviceName))
    
    -- Safely get device UID
    local uidSuccess, deviceUID = pcall(function()
        return device:uid()
    end)
    local deviceUID = (uidSuccess and deviceUID) or "unknown"
    
    local info = {
        name = deviceName,
        uid = deviceUID,
        sampleRate = 0,
        bitDepth = nil,
        channels = nil,
        volume = 0,
        muted = false,
        device = device
    }
    
    -- Try to get sample rate using the method (may not exist in this Hammerspoon version)
    local srSuccess, sampleRate = pcall(function()
        return device:sampleRate()
    end)
    
    if srSuccess and sampleRate and type(sampleRate) == "number" and sampleRate > 0 then
        info.sampleRate = sampleRate
    else
        -- sampleRate() method doesn't exist in this Hammerspoon version
        -- Use system_profiler as fallback (this works reliably)
        local spSuccess, spRate = pcall(function()
            local devName = deviceName or "Unknown"
            -- system_profiler shows "Current SampleRate: 192000" format
            local cmd = "system_profiler SPAudioDataType 2>/dev/null | grep -A 10 '" .. devName:gsub("'", "'\\''") .. "' | grep 'Current SampleRate' | awk '{print $3}'"
            print("[AUDIO-INFO] Executing command: " .. cmd)
            local result = hs.execute(cmd, true)
            print("[AUDIO-INFO] Command result (raw): '" .. tostring(result) .. "' (type: " .. type(result) .. ")")
            
            if result and result ~= "" then
                -- Clean up the result (remove newlines, whitespace, trim)
                result = result:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", "")
                print("[AUDIO-INFO] Cleaned result: '" .. result .. "'")
                local rate = tonumber(result)
                print("[AUDIO-INFO] Parsed rate: " .. tostring(rate) .. " (type: " .. type(rate) .. ")")
                if rate and rate > 0 then
                    return rate
                end
            else
                print("[AUDIO-INFO] Command returned empty or nil result")
            end
            return nil
        end)
        
        print("[AUDIO-INFO] pcall result - success: " .. tostring(spSuccess) .. ", rate: " .. tostring(spRate) .. " (type: " .. type(spRate) .. ")")
        
        if spSuccess and spRate and type(spRate) == "number" and spRate > 0 then
            info.sampleRate = spRate
            print("[AUDIO-INFO] ✓ Successfully set sample rate: " .. tostring(spRate) .. " Hz")
        else
            print("[AUDIO-INFO] ✗ Failed to retrieve sample rate")
        end
    end
    
    -- Safely get volume (method may not exist)
    local volSuccess, volume = pcall(function()
        return device:volume()
    end)
    if volSuccess and volume and type(volume) == "number" then
        info.volume = volume
    end
    
    -- Safely get muted status (method may not exist)
    local muteSuccess, muted = pcall(function()
        return device:muted()
    end)
    if muteSuccess and muted ~= nil then
        info.muted = muted
    end
    
    -- Try to get stream format for accurate bit depth and channel info
    -- Note: streamFormat() may not be available in all Hammerspoon versions
    local success, streamFormat = pcall(function()
        -- Try different possible method names
        if device.streamFormat then
            return device:streamFormat()
        elseif device.getStreamFormat then
            return device:getStreamFormat()
        end
        return nil
    end)
    
    if success and streamFormat and type(streamFormat) == "table" then
        -- Get bit depth from stream format
        if streamFormat.bitsPerChannel then
            info.bitDepth = streamFormat.bitsPerChannel
        elseif streamFormat.bitsPerFrame and streamFormat.channelsPerFrame then
            -- Calculate bit depth from bits per frame and channels
            info.bitDepth = math.floor(streamFormat.bitsPerFrame / streamFormat.channelsPerFrame)
        end
        
        -- Get channel count
        if streamFormat.channelsPerFrame then
            info.channels = streamFormat.channelsPerFrame
        end
    end
    
    -- Fallback: Try to get from device properties (method may not exist)
    if not info.bitDepth or not info.channels then
        local propsSuccess, props = pcall(function()
            return device:properties()
        end)
        if propsSuccess and props and type(props) == "table" then
            if not info.bitDepth then
                if props["BitDepth"] then
                    info.bitDepth = props["BitDepth"]
                elseif props["bitDepth"] then
                    info.bitDepth = props["bitDepth"]
                end
            end
            
            if not info.channels then
                if props["Channels"] then
                    info.channels = props["Channels"]
                elseif props["channels"] then
                    info.channels = props["channels"]
                end
            end
        end
    end
    
    -- If bit depth still not available, infer from sample rate
    if not info.bitDepth then
        if info.sampleRate >= 96000 then
            info.bitDepth = 24  -- High sample rate usually means 24-bit
        elseif info.sampleRate >= 48000 then
            info.bitDepth = 24  -- 48kHz+ often uses 24-bit
        else
            info.bitDepth = 16  -- Default to 16-bit for lower rates
        end
    end
    
    -- Default to stereo (2 channels) if not available
    if not info.channels then
        info.channels = 2
    end
    
    -- Calculate bitrate
    -- Bitrate = sample rate × bit depth × channels
    if info.sampleRate and info.bitDepth and info.channels then
        info.bitrate = info.sampleRate * info.bitDepth * info.channels
        -- Convert to kbps for display
        info.bitrateKbps = math.floor(info.bitrate / 1000)
    end
    
    debug.callEnd("audio-info", "getAudioInfo", info)
    return info
end

-- Format sample rate for display
local function formatSampleRate(rate)
    if not rate or rate == 0 then
        return "N/A"
    end
    
    if rate >= 1000 then
        local khz = rate / 1000
        -- Show whole numbers without decimal if possible
        if khz == math.floor(khz) then
            return string.format("%d kHz", math.floor(khz))
        else
            return string.format("%.1f kHz", khz)
        end
    else
        return string.format("%d Hz", rate)
    end
end

-- Format bitrate for display
local function formatBitrate(bitrateKbps)
    if not bitrateKbps then
        return "N/A"
    end
    
    if bitrateKbps >= 1000 then
        return string.format("%.1f Mbps", bitrateKbps / 1000)
    else
        return string.format("%d kbps", bitrateKbps)
    end
end

-- Update menu bar display
local function updateMenuBar()
    debug.callStart("audio-info", "updateMenuBar")
    
    local info = getAudioInfo()
    if not info then
        if menuBarItem then
            menuBarItem:setTitle("No Audio")
            menuBarItem:setTooltip("No audio output device found")
        end
        debug.callEnd("audio-info", "updateMenuBar")
        return
    end
    
    -- Create menu bar title (compact)
    local title = ""
    
    -- Add mute indicator
    if info.muted then
        title = title .. "🔇 "
    end
    
    -- Add sample rate (only if available and valid)
    print("[AUDIO-INFO] Display - info.sampleRate: " .. tostring(info.sampleRate) .. " (type: " .. type(info.sampleRate) .. ")")
    local sampleRateStr = formatSampleRate(info.sampleRate)
    print("[AUDIO-INFO] Display - sampleRateStr: '" .. sampleRateStr .. "'")
    local hasSampleRate = sampleRateStr ~= "N/A" and info.sampleRate and info.sampleRate > 0
    print("[AUDIO-INFO] Display - hasSampleRate: " .. tostring(hasSampleRate))
    
    if hasSampleRate then
        title = title .. sampleRateStr
    end
    
    -- Add bit depth if available
    if info.bitDepth then
        if hasSampleRate then
            title = title .. "/"
        end
        title = title .. info.bitDepth .. "bit"
    end
    
    -- If we have nothing to show, show device name
    if title == "" or (not hasSampleRate and not info.bitDepth) then
        title = info.name or "Audio"
    end
    
    -- Set title
    if menuBarItem then
        menuBarItem:setTitle(title)
        
        -- Create detailed tooltip
        local tooltip = string.format(
            "Audio Output Device\n" ..
            "━━━━━━━━━━━━━━━━━━━━\n" ..
            "Device: %s\n" ..
            "Sample Rate: %s\n" ..
            "Bit Depth: %d-bit\n" ..
            "Channels: %d\n" ..
            "Bitrate: %s\n" ..
            "Volume: %d%%\n" ..
            "Muted: %s\n" ..
            "━━━━━━━━━━━━━━━━━━━━\n" ..
            "UID: %s",
            info.name,
            formatSampleRate(info.sampleRate),
            info.bitDepth or 0,
            info.channels or 0,
            formatBitrate(info.bitrateKbps),
            math.floor(info.volume * 100),
            info.muted and "Yes" or "No",
            info.uid
        )
        
        menuBarItem:setTooltip(tooltip)
    end
    
    logger.debug(string.format("Audio info updated: %s @ %s/%d-bit, %d ch, %s",
        info.name,
        formatSampleRate(info.sampleRate),
        info.bitDepth or 0,
        info.channels or 0,
        formatBitrate(info.bitrateKbps)
    ))
    
    debug.callEnd("audio-info", "updateMenuBar")
end

-- Create menu bar item
local function createMenuBar()
    local success, result = pcall(function()
        menuBarItem = hs.menubar.new()
        return menuBarItem
    end)
    
    if not success or not menuBarItem then
        logger.error("Failed to create audio-info menu bar item: " .. tostring(result))
        return false
    end
    
    -- Set click callback to open Audio MIDI Setup
    local clickSuccess, clickErr = pcall(function()
        menuBarItem:setClickCallback(function()
            hs.execute("open -a 'Audio MIDI Setup'")
        end)
    end)
    
    if not clickSuccess then
        logger.warning("Failed to set click callback: " .. tostring(clickErr))
    end
    
    -- Don't do initial update here - it will be done in init() after a delay
    -- to ensure hs.audiodevice extension is loaded
    
    logger.info("Audio info menu bar configured")
    return true
end

-- Start update timer
local function startUpdateTimer()
    if updateTimer then
        updateTimer:stop()
    end
    
    updateTimer = hs.timer.doEvery(updateInterval, function()
        updateMenuBar()
    end)
    
    logger.debug("Audio info update timer started (interval: " .. updateInterval .. "s)")
end

-- Stop update timer
local function stopUpdateTimer()
    if updateTimer then
        updateTimer:stop()
        updateTimer = nil
        logger.debug("Audio info update timer stopped")
    end
end

-- Cleanup function
function audioInfo.cleanup()
    stopUpdateTimer()
    
    if menuBarItem then
        menuBarItem:delete()
        menuBarItem = nil
    end
    
    logger.debug("Audio info cleanup complete")
end

-- Initialize
function audioInfo.init()
    logger.info("Initializing audio-info module")
    
    -- Create menu bar (with error handling)
    local menuBarCreated = createMenuBar()
    if not menuBarCreated then
        logger.error("Failed to initialize audio-info menu bar, continuing without it")
    end
    
    -- Delay initial update to ensure hs.audiodevice extension is loaded
    -- The extension loads after modules, so we need to wait
    hs.timer.doAfter(1.0, function()
        -- Check if hs.audiodevice is available
        if not hs.audiodevice then
            logger.error("hs.audiodevice extension not available")
            return
        end
        
        -- Perform initial update
        updateMenuBar()
        
        -- Now start the update timer
        startUpdateTimer()
        
        -- Watch for audio device changes (with error handling)
        local watcherSuccess, watcherErr = pcall(function()
            hs.audiodevice.watcher.setCallback(function(event)
                logger.debug("Audio device event: " .. tostring(event))
                -- Update immediately when device changes
                updateMenuBar()
            end)
            hs.audiodevice.watcher.start()
        end)
        
        if not watcherSuccess then
            logger.warning("Failed to start audio device watcher: " .. tostring(watcherErr))
            logger.info("Audio info will still update via timer")
        end
    end)
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, audioInfo.cleanup)
    
    logger.info("Audio info module initialized")
end

return audioInfo
