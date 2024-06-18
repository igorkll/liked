local registry = require("registry")
local fs = require("filesystem")
local serialization = require("serialization")
local xorfs = require("xorfs")
local uuid = require("uuid")
local likedprotect_fs = {}

local function getFileKey(path, password)
    local datakey = fs.getAttribute(path, "datakey")
    if not datakey then
        datakey = uuid.next()
        fs.setAttribute(path, "datakey", datakey)
    end
    return xorfs.xorcode(datakey, password)
end

local function toggleFile(path, password, state)
    
end

local function toggleFolder(path, password, state)
    for i, lpath in ipairs(fs.recursion(path)) do
        toggleFile(lpath, password, state)
    end
end

local function toggleAll(password)
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


function likedprotect_fs.isEncrypt()
    return not not registry.encrypt
end

function likedprotect_fs.encrypt()

end

function likedprotect_fs.init()
    if not likedprotect_fs.isEncrypt() then return end


end

likedprotect_fs.unloadable = true
return likedprotect_fs