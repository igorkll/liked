local registry = require("registry")
local fs = require("filesystem")
local serialization = require("serialization")
local xorfs = require("xorfs")
local uuid = require("uuid")
local paths = require("paths")
local cache = require("cache")
local text = require("text")
local unicode = require("unicode")
local likedCryptoFs = {}

local lList
local function loadlist()
    if lList then return lList end
    lList = serialization.load("/system/liked/encrypt.lst")
    return lList
end

local function getDatakey(path, password, state)
    local datakey = fs.getAttribute(path, "datakey")
    if (not not datakey) == (not not state) then
        return true
    end

    if not datakey then
        datakey = uuid.next()
        fs.setAttribute(path, "datakey", datakey)
    else
        fs.setAttribute(path, "datakey")
    end

    return xorfs.xorcode(datakey, password)
end

local function toggleFile(path, password, state)
    local datakey = getDatakey(path, password, state)
    if datakey ~= true then
        xorfs.toggleFile(path, datakey)
    end
end

local function toggleFolder(path, password, state)
    for _, lpath in fs.recursion(fs.mntPath(path)) do
        if not fs.isDirectory(lpath) then
            toggleFile(lpath, password, state)
        end
    end
end

local function toggleAll(password) --the password must be correct when decrypting files, otherwise the keys will overlap
    local newState = not registry.encrypt
    for _, path in ipairs(loadlist()) do
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
        fs.openHooks[function(path, mode, ...)
            if mode and registry.encrypt then
                local chr = mode:sub(1, 1)
                if (chr == "w" or chr == "a") and not fs.exists(path) then
                    path = fs.mntPath(path)
                    for _, listpath in ipairs(loadlist()) do
                        listpath = fs.mntPath(listpath)
                        if paths.equals(path, listpath) or (fs.isDirectory(listpath) and text.startwith(unicode, path .. "/", listpath .. "/")) then
                            local file, err = fs.open(path, mode, ...)
                            local datakey = getDatakey(path, password, true)
                            if datakey ~= true then
                                fs.regXor(path, datakey)
                            end
                            return {file, err}
                        end
                    end
                end
            end
        end] = 774
        cache.static[2] = true

        for _, path in ipairs(loadlist()) do
            for _, lpath in fs.recursion(fs.mntPath(path)) do
                if not fs.isDirectory(lpath) then
                    local datakey = fs.getAttribute(lpath, "datakey")
                    if datakey then
                        fs.regXor(lpath, xorfs.xorcode(datakey, password))
                    else
                        fs.regXor(lpath)
                    end
                end
            end
        end
    else
        table.clear(fs.openHooks, 774)
        for _, path in ipairs(loadlist()) do
            for _, lpath in fs.recursion(fs.mntPath(path)) do
                if not fs.isDirectory(lpath) then
                    fs.regXor(lpath)
                end
            end
        end
    end
end


function likedCryptoFs.isEncrypt()
    return not not registry.encrypt
end

function likedCryptoFs.encrypt(password)
    if likedCryptoFs.isEncrypt() then return false end
    toggleAll(password)
    reg(password)
    return true
end

function likedCryptoFs.decrypt(password)
    if not likedCryptoFs.isEncrypt() then return false end
    toggleAll(password)
    reg()
    return true
end

function likedCryptoFs.init(password)
    if cache.static[0] then return false end
    cache.static[0] = true

    if not likedCryptoFs.isEncrypt() then return false end
    reg(password)
    return true
end

likedCryptoFs.unloadable = true
return likedCryptoFs