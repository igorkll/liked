--все приложения должны содержать
--посля name, vendor, version
--url иконки в поле icon
--функцию для установки

local calls = require("calls")
local fs = require("filesystem")
local paths = require("paths")
local programs = require("programs")

local list = {
    nanomachines = {
        name = "nanomachines",
        version = "1.3",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/icon.t2p",

        path = "/data/bin/nanomachines.app",
        install = function(self)
            fs.makeDirectory("/data/bin/nanomachines.app")
            saveFile("/data/bin/nanomachines.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/main.lua")))
            saveFile("/data/bin/nanomachines.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/nanomachines.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/uninstall.lua")))
        end
    },
    worm = {
        name = "worm",
        version = "1",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/icon.t2p",

        path = "/data/bin/worm.app",
        install = function(self)
            fs.makeDirectory("/data/bin/worm.app")
            saveFile("/data/bin/worm.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/main.lua")))
            saveFile("/data/bin/worm.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/worm.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/uninstall.lua")))
        end
    },
    chat = {
        name = "chat",
        version = "1.7",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/icon.t2p",

        path = "/data/bin/chat.app",
        install = function(self)
            fs.makeDirectory("/data/bin/chat.app")
            saveFile("/data/bin/chat.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/main.lua")))
            saveFile("/data/bin/chat.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/chat.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/uninstall.lua")))

            fs.makeDirectory("/data/autoruns")
            saveFile("/data/autoruns/chat_demon.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/autorun.lua")))

            fs.makeDirectory("/data/lib")
            saveFile("/data/lib/chat_lib.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/chat_lib.lua")))
            saveFile("/data/lib/modem_chat_lib.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/chat.app/modem_chat_lib.lua")))
        
            programs.execute("/data/autoruns/chat_demon.lua")
        end
    },
    --[[
    spaceshoter = {
        path = "/data/bin/spaceshot.app",
        install = function()
            fs.makeDirectory("/data/bin/spaceshoter.app")
            saveFile("/data/bin/spaceshoter.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/spaceshoter.app/main.lua")))
            saveFile("/data/bin/spaceshoter.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/spaceshoter.app/icon.t2p")))
            saveFile("/data/bin/spaceshoter.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/spaceshoter.app/uninstall.lua")))
        end
    }
    ]]
    irc = {
        name = "irc",
        version = "1",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/irc.app/icon.t2p",

        path = "/data/bin/irc.app",
        install = function(self)
            fs.makeDirectory("/data/bin/irc.app")
            saveFile("/data/bin/irc.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/irc.app/main.lua")))
            saveFile("/data/bin/irc.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/irc.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/irc.app/uninstall.lua")))
        end
    },
    archiver = {
        name = "archiver",
        version = "1.1",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/icon.t2p",

        path = "/data/bin/archiver.app",
        install = function(self)
            fs.makeDirectory("/data/bin/archiver.app")
            saveFile("/data/bin/archiver.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/main.lua")))
            saveFile("/data/bin/archiver.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/archiver.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/uninstall.lua")))
        end
    },
    brainfuck = {
        name = "brainfuck",
        version = "1",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/brainfuck.app/icon.t2p",

        path = "/data/bin/brainfuck.app",
        install = function(self)
            fs.makeDirectory("/data/bin/brainfuck.app")
            fs.makeDirectory("/data/lib")
            saveFile("/data/bin/brainfuck.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/brainfuck.app/main.lua")))
            saveFile("/data/bin/brainfuck.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/brainfuck.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/brainfuck.app/uninstall.lua")))
            saveFile("/data/lib/brainfuck.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/brainfuck.app/lib.lua")))
        end
    },
    --[[
    eeprom = {
        path = "/data/bin/eeprom.app",
        install = function()
            fs.makeDirectory("/data/bin/eeprom.app")
            saveFile("/data/bin/eeprom.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/eeprom.app/main.lua")))
            saveFile("/data/bin/eeprom.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/eeprom.app/icon.t2p")))
            saveFile("/data/bin/eeprom.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/eeprom.app/uninstall.lua")))
        end
    },
    ]]
    legacyRender = {
        name = "legacy render",
        version = "1",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/legacyRender.app/icon.t2p",

        path = "/data/bin/legacyRender.app",
        install = function(self)
            fs.makeDirectory("/data/autoruns")
            fs.makeDirectory("/data/bin/legacyRender.app")

            saveFile("/data/bin/legacyRender.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/legacyRender.app/main.lua")))
            saveFile("/data/bin/legacyRender.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/legacyRender.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/legacyRender.app/uninstall.lua")))
            saveFile("/data/autoruns/legacyRender.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/legacyRender.app/autorun.lua")))
            
            programs.execute("/data/autoruns/legacyRender.lua")
        end
    },
    lua = {
        name = "lua",
        version = "1",
        vendor = "Logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/lua.app/icon.t2p",

        path = "/data/bin/lua.app",
        install = function(self)
            fs.makeDirectory("/data/bin/lua.app")
            saveFile("/data/bin/lua.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/lua.app/main.lua")))
            saveFile("/data/bin/lua.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/lua.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/lua.app/uninstall.lua")))
        end
    },
    --[[
    openbox = {
        hided = true,
        path = "/data/bin/openbox.app",
        install = function()
            fs.makeDirectory("/data/bin/openbox.app")
            saveFile("/data/bin/openbox.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/openbox.app/main.lua")))
            saveFile("/data/bin/openbox.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/openbox.app/icon.t2p")))
            saveFile("/data/bin/openbox.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/openbox.app/uninstall.lua")))
        end
    }
    ]]
}

for k, v in pairs(list) do
    function v.uninstall()
        programs.execute(paths.concat(v.path, "uninstall.lua"))
    end
    function v.isInstalled()
        return fs.exists(v.path)
    end
end

return list