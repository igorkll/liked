local registry = require("registry")
local fs = require("filesystem")
local serialization = require("serialization")
local likedprotect_fs = {}

local function toggleFolder(path, state)
    local xorfs = require("xorfs")
    for i, lpath in ipairs(fs.recursion(path)) do
        xorfs.toggleFile(path, )
    end
end

local function toggleAll()
    for _, path in ipairs(serialization.load("/system/liked/encrypt.lst")) do
        if fs.isDirectory(path) then
            toggleFolder(path, xorcode)
        end
    end
    registry.encrypt = not registry.encrypt
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