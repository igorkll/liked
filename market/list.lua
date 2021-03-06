--https://raw.githubusercontent.com/igorkll/liked/main/market/apps;apps;/data/userdata
--https://raw.githubusercontent.com/igorkll/liked/main/market/themes;themes;/data/userdata/themes
local calls = require("calls")
local fs = require("filesystem")

local function saveFile(path, data)
    local file = fs.open(path, "wb")
    file.write(data)
    file.close()
end

return {
    nanomachines = {
        install = function()
            fs.makeDirectory("/data/userdata/nanomachines.app")
            saveFile("/data/userdata/nanomachines.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/main.lua")))
            saveFile("/data/userdata/nanomachines.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/icon.t2p")))
        end,
        uninstall = function()
            return fs.remove("/data/userdata/nanomachines.app")
        end,
        isInstalled = function()
            return fs.exists("/data/userdata/nanomachines.app")
        end
    },
    worm = {
        install = function()
            fs.makeDirectory("/data/userdata/worm.app")
            saveFile("/data/userdata/worm.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/main.lua")))
            saveFile("/data/userdata/worm.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/icon.t2p")))
        end,
        uninstall = function()
            return fs.remove("/data/userdata/worm.app")
        end,
        isInstalled = function()
            return fs.exists("/data/userdata/worm.app")
        end
    }
}