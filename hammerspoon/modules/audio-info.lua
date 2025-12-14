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
        debug.callEnd("audio-info", "getAudioInfo", nil)
        return nil
    end
    
    local info = {
        name = device:name() or "Unknown",
        uid = device:uid() or "unknown",
        sampleRate = device:sampleRate() or 0,
        bitDepth = nil,
        channels = nil,
        volume = device:volume() or 0,
        muted = device:muted() or false,
        device = device
    }
    
    -- Try to get stream format for accurate bit depth and channel info
    local success, streamFormat = pcall(function()
        return device:streamFormat()
    end)
    
    if success and streamFormat then
        -- Get bit depth from stream format
        if streamFormat.bitsPerChannel then
            info.bitDepth = streamFormat.bitsPerChannel
        elseif streamFormat.bitsPerFrame and streamFormat.channelsPerFrame then
            -- Calculate bit depth from bits per frame and channels
            info.bitDepth = streamFormat.bitsPerFrame / streamFormat.channelsPerFrame
        end
        
        -- Get channel count
        if streamFormat.channelsPerFrame then
            info.channels = streamFormat.channelsPerFrame
        end
    end
    
    -- Fallback: Try to get from device properties
    if not info.bitDepth or not info.channels then
        local props = device:properties()
        if props then
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
            menuBarItem:setTitle("🔊 No Audio")
            menuBarItem:setTooltip("No audio output device found")
        end
        debug.callEnd("audio-info", "updateMenuBar")
        return
    end
    
    -- Create menu bar title (compact)
    local title = "🔊 "
    
    -- Add mute indicator
    if info.muted then
        title = title .. "🔇 "
    end
    
    -- Add sample rate
    title = title .. formatSampleRate(info.sampleRate)
    
    -- Add bit depth if available
    if info.bitDepth then
        title = title .. "/" .. info.bitDepth .. "bit"
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
    menuBarItem = hs.menubar.new()
    
    if not menuBarItem then
        logger.error("Failed to create audio-info menu bar item")
        return
    end
    
    -- Set click callback to open Audio MIDI Setup
    menuBarItem:setClickCallback(function()
        hs.execute("open -a 'Audio MIDI Setup'")
    end)
    
    -- Initial update
    updateMenuBar()
    
    logger.info("Audio info menu bar configured")
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
    
    createMenuBar()
    startUpdateTimer()
    
    -- Watch for audio device changes
    hs.audiodevice.watcher.setCallback(function(uid, event)
        logger.debug("Audio device event: " .. tostring(event) .. " for device: " .. tostring(uid))
        -- Update immediately when device changes
        updateMenuBar()
    end)
    hs.audiodevice.watcher.start()
    
    -- Register cleanup
    hs.cleanup = hs.cleanup or {}
    table.insert(hs.cleanup, audioInfo.cleanup)
    
    logger.info("Audio info module initialized")
end

return audioInfo
