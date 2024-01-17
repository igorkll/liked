local account = require("account")
local fs = require("filesystem")
local event = require("event")
local programs = require("programs")
local internet = require("internet")
local thread = require("thread")
local liked = require("liked")
local apps = require("apps")

if not liked.recoveryMode then
    local storagePath = "/data/userdata/cloudStorage"
    local publicStoragePath = "/data/userdata/publicStorage"

    local function realCheck()
        apps.check()
        
        if internet.check() then
            account.check()
            
            local storage = account.getStorage()
            if storage then
                if not fs.exists(storagePath) then
                    fs.mount(storage, storagePath)
                end
            elseif fs.exists(storagePath) then
                fs.umount(storagePath)
            end

            local publicStorage = account.getPublicStorage()
            if publicStorage then
                if not fs.exists(publicStoragePath) then
                    fs.mount(publicStorage, publicStoragePath)
                end
            elseif fs.exists(publicStoragePath) then
                fs.umount(publicStoragePath)
            end

            if account.isBricked() then
                assert(programs.execute("/system/liked/brick.lua"))
            end
        end
    end

    local function check()
        thread.createBackground(realCheck):resume()
    end

    realCheck()
    event.timer(60, check, math.huge)
    event.listen("accountChanged", check)
end