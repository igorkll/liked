--заметки для меня(актульны для этого файла)
--все приложения должны содержать
--посля name, vendor, version, description, minDiskSpace
--url иконки в поле icon
--поле path с путем установки для того чтобы автогенерация функции uninstall в конце этого файла знала что удалять или где искать uninstall.lua
--функцию для установки

local fs = require("filesystem")
local paths = require("paths")
local programs = require("programs")
local internet = require("internet")
local unicode = require("unicode")

local function download(url)
    return assert(internet.getInternetFile(url))
end

local function save(path, data)
    assert(fs.writeFile(path, data))
end

local screen, nickname, selfurl = ...

local selfurlpart = selfurl
for i = #selfurl, 1, -1 do
    selfurlpart = unicode.sub(selfurlpart, 1, #selfurlpart - 1)
    if unicode.sub(selfurl, i, i) == "/" then
        break
    end
end

local list = {
    {
        name = "nanomachines",
        version = "2",
        vendor = "logic",
        icon = selfurlpart .. "/apps/nanomachines.app/icon.t2p",
        description = "allows you to control nanobots using a wireless modem",
        minDiskSpace = 64,

        path = "/data/bin/nanomachines.app",
        install = function(self)
            fs.makeDirectory("/data/bin/nanomachines.app")
            save("/data/bin/nanomachines.app/main.lua", download(selfurlpart .. "/apps/nanomachines.app/main.lua"))
            save("/data/bin/nanomachines.app/icon.t2p", download(self.icon))
        end
    },
    {
        name = "worm",
        version = "1",
        vendor = "computercraft",
        icon = selfurlpart .. "/apps/worm.app/icon.t2p",
        description = "classic snake ported from computercraft",
        minDiskSpace = 64,

        path = "/data/bin/worm.app",
        install = function(self)
            fs.makeDirectory("/data/bin/worm.app")
            save("/data/bin/worm.app/main.lua", download(selfurlpart .. "/apps/worm.app/main.lua"))
            save("/data/bin/worm.app/icon.t2p", download(self.icon))
        end
    },
    {
        name = "chat",
        version = "1.7",
        vendor = "logic",
        icon = selfurlpart .. "/apps/chat.app/icon.t2p",
        description = "allows you to exchange messages, pictures and files between computers via a network card",
        minDiskSpace = 64,

        path = "/data/bin/chat.app",
        install = function(self)
            fs.makeDirectory("/data/bin/chat.app")
            save("/data/bin/chat.app/main.lua", download(selfurlpart .. "/apps/chat.app/main.lua"))
            save("/data/bin/chat.app/icon.t2p", download(self.icon))
            save("/data/bin/chat.app/uninstall.lua", download(selfurlpart .. "/apps/chat.app/uninstall.lua"))
            save("/data/bin/chat.app/exit.lua", download(selfurlpart .. "/apps/chat.app/exit.lua"))

            fs.makeDirectory("/data/autoruns")
            save("/data/autoruns/chat_demon.lua", download(selfurlpart .. "/apps/chat.app/autorun.lua"))

            fs.makeDirectory("/data/lib")
            save("/data/lib/chat_lib.lua", download(selfurlpart .. "/apps/chat.app/chat_lib.lua"))
            save("/data/lib/modem_chat_lib.lua", download(selfurlpart .. "/apps/chat.app/modem_chat_lib.lua"))
        
            assert(programs.execute("/data/autoruns/chat_demon.lua"))
        end
    },
    --[[
    {
        path = "/data/bin/spaceshot.app",
        install = function()
            fs.makeDirectory("/data/bin/spaceshoter.app")
            save("/data/bin/spaceshoter.app/main.lua", download(selfurlpart .. "/apps/spaceshoter.app/main.lua")))
            save("/data/bin/spaceshoter.app/icon.t2p", download(selfurlpart .. "/apps/spaceshoter.app/icon.t2p")))
        end
    }
    ]]
    {
        name = "irc",
        version = "1",
        vendor = "Nathan Flynn",
        icon = selfurlpart .. "/apps/irc.app/icon.t2p",
        description = "allows you to connect to IRC chats via an Internet card.\nprogram ported from openOS",
        minDiskSpace = 64,

        path = "/data/bin/irc.app",
        install = function(self)
            fs.makeDirectory("/data/bin/irc.app")
            save("/data/bin/irc.app/main.lua", download(selfurlpart .. "/apps/irc.app/main.lua"))
            save("/data/bin/irc.app/icon.t2p", download(self.icon))
        end
    },
    {
        name = "archiver",
        version = "2",
        vendor = "logic",
        icon = selfurlpart .. "/apps/archiver.app/icon.t2p",
        description = "allows you to unpack and package archives",
        minDiskSpace = 64,

        path = "/data/bin/archiver.app",
        install = function(self)
            fs.makeDirectory("/data/bin/archiver.app")
            save("/data/bin/archiver.app/main.lua", download(selfurlpart .. "/apps/archiver.app/main.lua"))
            save("/data/bin/archiver.app/icon.t2p", download(self.icon))
            save("/data/bin/archiver.app/uninstall.lua", download(selfurlpart .. "/apps/archiver.app/uninstall.lua"))
            save("/data/autoruns/archiver.lua", download(selfurlpart .. "/apps/archiver.app/autorun.lua"))
            save("/data/icons/afpx.t2p", download(selfurlpart .. "/apps/archiver.app/afpx.t2p"))
        
            assert(programs.execute("/data/autoruns/archiver.lua"))
        end
    },
    {
        name = "brainfuck",
        version = "1",
        vendor = "logic",
        icon = selfurlpart .. "/apps/brainfuck.app/icon.t2p",
        description = "brainfuck code interpreter",
        minDiskSpace = 64,

        path = "/data/bin/brainfuck.app",
        install = function(self)
            fs.makeDirectory("/data/bin/brainfuck.app")
            fs.makeDirectory("/data/lib")
            save("/data/bin/brainfuck.app/main.lua", download(selfurlpart .. "/apps/brainfuck.app/main.lua"))
            save("/data/bin/brainfuck.app/icon.t2p", download(self.icon))
            save("/data/bin/brainfuck.app/uninstall.lua", download(selfurlpart .. "/apps/brainfuck.app/uninstall.lua"))
            save("/data/lib/brainfuck.lua", download(selfurlpart .. "/apps/brainfuck.app/lib.lua"))
        end
    },
    --[[
    eeprom = {
        path = "/data/bin/eeprom.app",
        install = function()
            fs.makeDirectory("/data/bin/eeprom.app")
            save("/data/bin/eeprom.app/main.lua", download(selfurlpart .. "/apps/eeprom.app/main.lua")))
            save("/data/bin/eeprom.app/icon.t2p", download(selfurlpart .. "/apps/eeprom.app/icon.t2p")))
        end
    },
    ]]
    --[[
    {
        name = "legacy render",
        version = "1",
        vendor = "logic",
        icon = selfurlpart .. "/apps/legacyRender.app/icon.t2p",
        description = "allows you to switch between rendering options",

        path = "/data/bin/legacyRender.app",
        install = function(self)
            fs.makeDirectory("/data/autoruns")
            fs.makeDirectory("/data/bin/legacyRender.app")

            save("/data/bin/legacyRender.app/main.lua", download(selfurlpart .. "/apps/legacyRender.app/main.lua")))
            save("/data/bin/legacyRender.app/icon.t2p", download(self.icon)))
            save("/data/bin/legacyRender.app/uninstall.lua", download(selfurlpart .. "/apps/legacyRender.app/uninstall.lua")))
            save("/data/autoruns/legacyRender.lua", download(selfurlpart .. "/apps/legacyRender.app/autorun.lua")))
            
            programs.execute("/data/autoruns/legacyRender.lua")
        end
    },
    ]]
    {
        name = "lua",
        version = "3",
        vendor = "logic",
        icon = selfurlpart .. "/apps/lua.app/icon.t2p",
        description = "lua code interpreter",
        minDiskSpace = 64,

        path = "/data/bin/lua.app",
        install = function(self)
            fs.makeDirectory("/data/bin/lua.app")
            save("/data/bin/lua.app/main.lua", download(selfurlpart .. "/apps/lua.app/main.lua"))
            save("/data/bin/lua.app/icon.t2p", download(self.icon))
        end
    },
    {
        name = "events",
        version = "2",
        vendor = "logic",
        icon = selfurlpart .. "/apps/events.app/icon.t2p",
        description = "allows you to view computer events",
        minDiskSpace = 64,

        path = "/data/bin/events.app",
        install = function(self)
            fs.makeDirectory("/data/bin/events.app")
            save("/data/bin/events.app/main.lua", download(selfurlpart .. "/apps/events.app/main.lua"))
            save("/data/bin/events.app/icon.t2p", download(self.icon))
        end
    },
    {
        name = "OpenOS",
        version = "1.8.3",
        vendor = "MightyPirates",
        icon = selfurlpart .. "/apps/OpenOS.app/icon.t2p",
        description = "configures dualboot between openOS and liked",
        minDiskSpace = 1024,

        path = "/vendor/bin/OpenOS.app",
        install = function(self)
            local afpxPath = self.path .. "/openOS.afpx"

            fs.makeDirectory(self.path)
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/OpenOS.app/main.lua"))
            save(self.path .. "/uninstall.lua", download(selfurlpart .. "/apps/OpenOS.app/uninstall.lua"))
            save(self.path .. "/icon.t2p", download(self.icon))

            save(self.path .. "/lua5_2.lua", download(selfurlpart .. "/apps/OpenOS.app/lua5_2.lua"))
            save(self.path .. "/actions.cfg", download(selfurlpart .. "/apps/OpenOS.app/actions.cfg"))
            
            save(afpxPath, download(selfurlpart .. "/apps/OpenOS.app/openOS.afpx"))
            require("archiver").unpack(afpxPath, "/")
            fs.remove(afpxPath)
        end
    },
    {
        name = "MineOS",
        version = "2",
        vendor = "IgorTimofeev",
        icon = selfurlpart .. "/apps/MineOS.app/icon.t2p",
        license = selfurlpart .. "/apps/MineOS.app/LICENSE",
        description = "configures dualboot between mineOS and liked",
        minDiskSpace = 1024 + 512,
        minColorDepth = 8,

        path = "/vendor/bin/MineOS.app",
        install = function(self)
            local afpxPath = self.path .. "/mineOS.afpx"

            fs.makeDirectory(self.path)
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/MineOS.app/main.lua"))
            save(self.path .. "/uninstall.lua", download(selfurlpart .. "/apps/MineOS.app/uninstall.lua"))
            save(self.path .. "/icon.t2p", download(self.icon))
            save("/mineOS.lua", download(selfurlpart .. "/apps/MineOS.app/mineOS.lua"))
            
            save(self.path .. "/lua5_2.lua", download(selfurlpart .. "/apps/MineOS.app/lua5_2.lua"))
            save(self.path .. "/actions.cfg", download(selfurlpart .. "/apps/MineOS.app/actions.cfg"))
            save(self.path .. "/LICENSE", download(self.license))

            save(afpxPath, download(selfurlpart .. "/apps/MineOS.app/mineOS.afpx"))
            require("archiver").unpack(afpxPath, "/")
            fs.remove(afpxPath)
        end
    },
    {
        name = "explode",
        version = "2",
        vendor = "logic",
        icon = selfurlpart .. "/apps/explode.app/icon.t2p",
        description = "blow up your computer!",
        minDiskSpace = 64,

        path = "/data/bin/explode.app",
        install = function(self)
            fs.makeDirectory(self.path)
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/explode.app/main.lua"))
            save(self.path .. "/icon.t2p", download(self.icon))
        end
    },
    {
        name = "camera",
        version = "1",
        vendor = "logic",
        icon = selfurlpart .. "/apps/camera.app/icon.t2p",
        description = "allows you to take pictures on the camera from the computronix addon.\n* allows you to select a camera from several\n* allows you to save a photo for loading on another computer",
        minDiskSpace = 64,

        path = "/data/bin/camera.app",
        install = function(self)
            fs.makeDirectory(self.path)
            save(self.path .. "/uninstall.lua", download(selfurlpart .. "/apps/camera.app/uninstall.lua"))
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/camera.app/main.lua"))
            
            local icon = download(self.icon)
            save(self.path .. "/icon.t2p", icon)
            save("/data/icons/cam.t2p", icon)

            save("/data/autoruns/camera.lua", download(selfurlpart .. "/apps/camera.app/autorun.lua"))
            assert(programs.execute("/data/autoruns/camera.lua"))
        end
    },
    {
        name = "redirection",
        version = "1",
        vendor = "computercraft",
        icon = selfurlpart .. "/apps/redirection.app/icon.t2p",
        description = "the game was ported from computercraft",
        minDiskSpace = 64,

        path = "/data/bin/redirection.app",
        install = function(self)
            fs.makeDirectory(self.path)
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/redirection.app/main.lua"))
            save(self.path .. "/icon.t2p", download(self.icon))

            fs.makeDirectory(paths.concat(self.path, "levels"))
            for i = 0, 12 do
                local name = tostring(i) .. ".dat"
                save(paths.concat(self.path, "levels", name), download(selfurlpart .. "/apps/redirection.app/levels/" .. name))
            end
        end
    },
    {
        name = "adventure",
        version = "1",
        vendor = "computercraft",
        description = "the game was ported from computercraft",
        minDiskSpace = 64,

        path = "/data/bin/adventure.app",
        urlPrimaryPart = selfurlpart .. "/apps/adventure.app/" --часть url к которой будут присираться разные имена файлов для скачивания(обязателен / на конце)
    },
    {
        name = "magnet",
        version = "1",
        vendor = "logic",
        description = "a program for controlling a magnet that attracts resources(tractor_beam-upgrade)",
        minDiskSpace = 64,

        path = "/data/bin/magnet.app",
        urlPrimaryPart = selfurlpart .. "/apps/magnet.app/", --часть url к которой будут присираться разные имена файлов для скачивания(обязателен / на конце)
        files = {"main.lua", "icon.t2p", "uninstall.lua"}
    },
    {
        name = "piston",
        version = "3",
        vendor = "logic",
        description = "a program for controlling a piston(piston-upgrade)",
        minDiskSpace = 64,

        path = "/data/bin/piston.app",
        urlPrimaryPart = selfurlpart .. "/apps/piston.app/", --часть url к которой будут присираться разные имена файлов для скачивания(обязателен / на конце)
        files = {"main.lua", "icon.t2p", "uninstall.lua"}
    }
    --[[
    openbox = {
        hided = true,
        path = "/data/bin/openbox.app",
        install = function()
            fs.makeDirectory("/data/bin/openbox.app")
            save("/data/bin/openbox.app/main.lua", download(selfurlpart .. "/apps/openbox.app/main.lua")))
            save("/data/bin/openbox.app/icon.t2p", download(selfurlpart .. "/apps/openbox.app/icon.t2p")))
        end
    }
    ]]
}

return list