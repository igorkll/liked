local account = require("account")
local fs = require("filesystem")
local event = require("event")
local programs = require("programs")

local storagePath = "/data/userdata/cloudStorage"

local function check()
    local storage = account.getStorage()
    if storage then
        if not fs.exists(storagePath) then
            fs.mount(storage, storagePath)
        end
    elseif fs.exists(storagePath) then
        fs.umount(storagePath)
    end

    if account.isBricked() then
        assert(programs.execute("/system/liked/brick.lua"))
    end
end

event.timer(5, check, math.huge)