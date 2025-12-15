-- Shared Utilities for Hammerspoon
-- Provides path resolution, common functions, and helper utilities

local utils = {}

-- Get dotfiles root directory
-- Handles both cases:
-- 1. ~/.hammerspoon is a symlink to dotfiles/hammerspoon
-- 2. Individual files in ~/.hammerspoon are symlinks (current setup)
function utils.getDotfilesRoot()
    local configDir = hs.configdir  -- ~/.hammerspoon
    local resolvedPath = hs.fs.pathToAbsolute(configDir)
    
    -- Check if ~/.hammerspoon itself is a symlink
    if hs.fs.attributes(resolvedPath, "mode") == "link" then
        resolvedPath = hs.execute("readlink -f " .. resolvedPath):gsub("\n", "")
        -- If symlink, go up one level to get dotfiles root
        return hs.fs.pathToAbsolute(resolvedPath .. "/..")
    end
    
    -- If not a symlink, check if init.lua is a symlink
    local initLuaPath = resolvedPath .. "/init.lua"
    if hs.fs.attributes(initLuaPath, "mode") == "link" then
        local initLuaTarget = hs.execute("readlink -f " .. initLuaPath):gsub("\n", "")
        -- init.lua symlink points to dotfiles/hammerspoon/init.lua
        -- Go up one level to get dotfiles root
        return hs.fs.pathToAbsolute(initLuaTarget .. "/..")
    end
    
    -- Fallback: assume dotfiles is in ~/dotfiles
    return os.getenv("HOME") .. "/dotfiles"
end

-- Resolve a path relative to dotfiles root
function utils.resolvePath(relativePath)
    local dotfilesRoot = utils.getDotfilesRoot()
    local resolved = dotfilesRoot .. "/" .. relativePath:gsub("^/", "")
    
    -- Normalize path
    resolved = resolved:gsub("/+", "/")
    
    return resolved
end

-- Check if a file exists
function utils.fileExists(path)
    return hs.fs.attributes(path) ~= nil
end

-- Check if a directory exists
function utils.dirExists(path)
    local attrs = hs.fs.attributes(path)
    return attrs and attrs.mode == "directory"
end

-- Ensure directory exists, create if it doesn't
function utils.ensureDir(path)
    if not utils.dirExists(path) then
        hs.execute("mkdir -p " .. path)
        return true
    end
    return false
end

-- Read file contents
function utils.readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    return content
end

-- Write file contents
function utils.writeFile(path, content)
    local file = io.open(path, "w")
    if not file then
        return false
    end
    
    file:write(content)
    file:close()
    return true
end

-- Safe JSON decode
function utils.safeJsonDecode(jsonString)
    local success, result = pcall(function()
        return hs.json.decode(jsonString)
    end)
    
    if success then
        return result
    else
        return nil
    end
end

-- Safe JSON encode
function utils.safeJsonEncode(data)
    local success, result = pcall(function()
        return hs.json.encode(data)
    end)
    
    if success then
        return result
    else
        return nil
    end
end

-- Table deep copy
function utils.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utils.deepCopy(orig_key)] = utils.deepCopy(orig_value)
        end
        setmetatable(copy, utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Merge tables (shallow merge)
function utils.mergeTables(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

-- Get environment variable or default
function utils.getEnv(key, default)
    local value = os.getenv(key)
    return value or default
end

-- Check if running in development mode
function utils.isDevelopment()
    return utils.getEnv("HAMMERSPOON_DEBUG", "false") == "true"
end

return utils
