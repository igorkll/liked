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
    nullapp1 = {
        install = function()
        end,
        uninstall = function()
        end,
        isInstalled = function()
        end
    },
    nullapp2 = {
        install = function()
        end,
        uninstall = function()
        end,
        isInstalled = function()
        end
    },
    nullapp3 = {
        install = function()
        end,
        uninstall = function()
        end,
        isInstalled = function()
        end
    },
}