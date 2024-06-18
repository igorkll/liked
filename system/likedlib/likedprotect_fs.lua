local registry = require("registry")
local fs = require("filesystem")
local serialization = require("serialization")
local xorfs = require("xorfs")
local uuid = require("uuid")
local paths = require("paths")
local cache = require("cache")
local likedprotect_fs = {}

local function toggleFile(path, password, state)
    local datakey = fs.getAttribute(path, "datakey")
    if (not not datakey) == (not not state) then
        return
    end

    if not datakey then
        datakey = uuid.next()
        fs.setAttribute(path, "datakey", datakey)
    else
        fs.setAttribute(path, "datakey")
    end

    local xordata = xorfs.xorcode(datakey, password)
    xorfs.toggleFile(path, xordata)
end

local function toggleFolder(path, password, state)
    for i, lpath in fs.recursion(path) do
        toggleFile(lpath, password, state)
    end
end

local function toggleAll(password) --the password must be correct when decrypting files, otherwise the keys will overlap
    local newState = not registry.encrypt
    for _, path in ipairs(serialization.load("/system/liked/encrypt.lst")) do
        if fs.isDirectory(path) then
            toggleFolder(path, password, newState)
        else
            toggleFile(path, password, newState)
        end
    end
    registry.encrypt = newState
end

local function reg(password)
    if registry.encrypt then
        for _, path in ipairs(serialization.load("/system/liked/encrypt.lst")) do
            local datakey = fs.getAttribute(path, "datakey")
            if datakey then
                fs.xorfs[paths.absolute(path)] = xorfs.xorcode(datakey, password)
            else
                fs.xorfs[paths.absolute(path)] = nil
            end
        end
    else
        for _, path in ipairs(serialization.load("/system/liked/encrypt.lst")) do
            fs.xorfs[paths.absolute(path)] = nil
        end
    end
end


function likedprotect_fs.isEncrypt()
    return not not registry.encrypt
end

function likedprotect_fs.encrypt(password)
    if likedprotect_fs.isEncrypt() then return false end
    toggleAll(password)
    reg(password)
    return true
end

function likedprotect_fs.decrypt(password)
    if not likedprotect_fs.isEncrypt() then return false end
    toggleAll(password)
    reg()
    return true
end

function likedprotect_fs.init(password)
    if cache.static[0] then return false end
    cache.static[0] = true

    if not likedprotect_fs.isEncrypt() then return false end
    reg(password)
    return true
end

likedprotect_fs.unloadable = true
return likedprotect_fs