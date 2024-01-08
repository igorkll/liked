local account = require("account")
local fs = require("filesystem")
local event = require("event")

local storagePath = "/data/userdata/cloudStorage"

local function storageCheck()
    local storage = account.getStorage()
    if storage then
        if not fs.exists(storagePath) then
            fs.mount(storage, storagePath)
        end
    elseif fs.exists(storagePath) then
        fs.umount(storagePath)
    end
end

event.timer(5, storageCheck, math.huge)