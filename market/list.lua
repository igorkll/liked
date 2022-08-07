local calls = require("calls")
local fs = require("filesystem")
local paths = require("paths")
local programs = require("programs")

local function saveFile(path, data)
    fs.makeDirectory(paths.path(path))
    local file = fs.open(path, "wb")
    file.write(data)
    file.close()
end

local list = {
    nanomachines = {
        path = "/data/bin/nanomachines.app",
        install = function()
            fs.makeDirectory("/data/bin/nanomachines.app")
            saveFile("/data/bin/nanomachines.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/main.lua")))
            saveFile("/data/bin/nanomachines.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/icon.t2p")))
            saveFile("/data/bin/nanomachines.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/uninstall.lua")))
        end
    },
    worm = {
        path = "/data/bin/worm.app",
        install = function()
            fs.makeDirectory("/data/bin/worm.app")
            saveFile("/data/bin/worm.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/main.lua")))
            saveFile("/data/bin/worm.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/icon.t2p")))
            saveFile("/data/bin/worm.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/uninstall.lua")))
        end
    },
    chat = {
        path = "/data/bin/chat.app",
        install = function()
            fs.makeDirectory("/data/bin/chat.app")
            saveFile("/data/bin/chat.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/main.lua")))
            saveFile("/data/bin/chat.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/icon.t2p")))
            saveFile("/data/bin/chat.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/uninstall.lua")))

            fs.makeDirectory("/data/autoruns")
            saveFile("/data/autoruns/chat_demon.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/autorun.lua")))

            fs.makeDirectory("/data/lib")
            saveFile("/data/lib/chat_lib.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/chat_lib.lua")))
            saveFile("/data/lib/modem_chat_lib.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/modem_chat_lib.lua")))
        
            programs.execute("/data/autoruns/chat_demon.lua")
        end
    }
}

for i, v in ipairs(list) do
    function v.uninstall()
        programs.execute(paths.concat(v.path, "uninstall.lua"))
    end
    function v.isInstalled()
        return fs.exists(v.path)
    end
end


return list