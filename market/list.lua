local calls = require("calls")
local fs = require("filesystem")
local paths = require("paths")

local function saveFile(path, data)
    fs.makeDirectory(paths.path(path))
    local file = fs.open(path, "wb")
    file.write(data)
    file.close()
end

return {
    nanomachines = {
        install = function()
            fs.makeDirectory("/data/bin/nanomachines.app")
            saveFile("/data/bin/nanomachines.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/main.lua")))
            saveFile("/data/bin/nanomachines.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/icon.t2p")))
            saveFile("/data/bin/nanomachines.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/uninstall.lua")))
        end,
        uninstall = function()
            return fs.remove("/data/bin/nanomachines.app")
        end,
        isInstalled = function()
            return fs.exists("/data/bin/nanomachines.app")
        end
    },
    worm = {
        install = function()
            fs.makeDirectory("/data/bin/worm.app")
            saveFile("/data/bin/worm.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/main.lua")))
            saveFile("/data/bin/worm.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/icon.t2p")))
            saveFile("/data/bin/worm.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/uninstall.lua")))
        end,
        uninstall = function()
            return fs.remove("/data/bin/worm.app")
        end,
        isInstalled = function()
            return fs.exists("/data/bin/worm.app")
        end
    }
}