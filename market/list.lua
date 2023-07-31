--все приложения должны содержать
--посля name, vendor, version, description
--url иконки в поле icon
--функцию для установки
--программы которые создают автораны или иначе встраиваються в систему должны ставиться по пути /data/bin
--программы которые пользователь сможет переносить между дисками должны ставиться в /data/userdata

local calls = require("calls")
local fs = require("filesystem")
local paths = require("paths")
local programs = require("programs")

local list = {
    nanomachines = {
        name = "nanomachines",
        version = "1.3",
        vendor = "logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/icon.t2p",
        description = "allows you to control nanobots using a wireless modem",

        path = "/data/userdata/nanomachines.app",
        install = function(self)
            fs.makeDirectory("/data/userdata/nanomachines.app")
            saveFile("/data/userdata/nanomachines.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/nanomachines.app/main.lua")))
            saveFile("/data/userdata/nanomachines.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
        end
    },
    worm = {
        name = "worm",
        version = "1",
        vendor = "logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/icon.t2p",

        path = "/data/userdata/worm.app",
        install = function(self)
            fs.makeDirectory("/data/userdata/worm.app")
            saveFile("/data/userdata/worm.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/worm.app/main.lua")))
            saveFile("/data/userdata/worm.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
        end
    },
    chat = {
        name = "chat",
        version = "1.7",
        vendor = "logic",
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
        path = "/data/userdata/spaceshot.app",
        install = function()
            fs.makeDirectory("/data/userdata/spaceshoter.app")
            saveFile("/data/userdata/spaceshoter.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/spaceshoter.app/main.lua")))
            saveFile("/data/userdata/spaceshoter.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/spaceshoter.app/icon.t2p")))
        end
    }
    ]]
    irc = {
        name = "irc",
        version = "1",
        vendor = "logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/irc.app/icon.t2p",

        path = "/data/userdata/irc.app",
        install = function(self)
            fs.makeDirectory("/data/userdata/irc.app")
            saveFile("/data/userdata/irc.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/irc.app/main.lua")))
            saveFile("/data/userdata/irc.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
        end
    },
    archiver = {
        name = "archiver",
        version = "1.2",
        vendor = "logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/icon.t2p",

        path = "/data/bin/archiver.app",
        install = function(self)
            fs.makeDirectory("/data/bin/archiver.app")
            saveFile("/data/bin/archiver.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/main.lua")))
            saveFile("/data/bin/archiver.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
            saveFile("/data/bin/archiver.app/uninstall.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/uninstall.lua")))
            saveFile("/data/icons/afpx.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/archiver.app/afpx.t2p")))
        end
    },
    brainfuck = {
        name = "brainfuck",
        version = "1",
        vendor = "logic",
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
        path = "/data/userdata/eeprom.app",
        install = function()
            fs.makeDirectory("/data/userdata/eeprom.app")
            saveFile("/data/userdata/eeprom.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/eeprom.app/main.lua")))
            saveFile("/data/userdata/eeprom.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/eeprom.app/icon.t2p")))
        end
    },
    ]]
    legacyRender = {
        name = "legacy render",
        version = "1",
        vendor = "logic",
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
        vendor = "logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/lua.app/icon.t2p",

        path = "/data/userdata/lua.app",
        install = function(self)
            fs.makeDirectory("/data/userdata/lua.app")
            saveFile("/data/userdata/lua.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/lua.app/main.lua")))
            saveFile("/data/userdata/lua.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
        end
    },
    events = {
        name = "events",
        version = "1",
        vendor = "logic",
        icon = "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/events.app/icon.t2p",

        path = "/data/userdata/events.app",
        install = function(self)
            fs.makeDirectory("/data/userdata/events.app")
            saveFile("/data/userdata/events.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/events.app/main.lua")))
            saveFile("/data/userdata/events.app/icon.t2p", assert(calls.call("getInternetFile", self.icon)))
        end
    },
    --[[
    openbox = {
        hided = true,
        path = "/data/userdata/openbox.app",
        install = function()
            fs.makeDirectory("/data/userdata/openbox.app")
            saveFile("/data/userdata/openbox.app/main.lua", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/openbox.app/main.lua")))
            saveFile("/data/userdata/openbox.app/icon.t2p", assert(calls.call("getInternetFile", "https://raw.githubusercontent.com/igorkll/liked/main/market/apps/openbox.app/icon.t2p")))
        end
    }
    ]]
}

for k, v in pairs(list) do
    local versionpath = paths.concat(v.path, "version.dat")
    function v.getVersion(self)
        if fs.exists(versionpath) then
            return getFile(versionpath)
        else
            return "unknown"
        end
    end

    function v.uninstall(self)
        local uninstallPath = paths.concat(self.path, "uninstall.lua")
        if fs.exists(uninstallPath) then
            programs.execute(uninstallPath)
        else
            fs.remove(self.path)
        end
    end

    function v.isInstalled(self)
        return fs.exists(self.path)
    end

    local _install = v.install
    function v.install(self)
        _install(self)
        saveFile(versionpath, self.version)
    end
end

return list