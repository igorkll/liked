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
local registry = require("registry")
local liked = require("liked")

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
        version = "2.1",
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
        version = "2.1",
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
    {
        name = "lua",
        version = "4",
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
        version = "3",
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
        name = "openOS",
        version = "1.8.3;2",
        vendor = "MightyPirates",
        icon = selfurlpart .. "/apps/openOS.app/icon.t2p",
        description = "configures dualboot between openOS and liked",
        minDiskSpace = 1024,

        path = "/vendor/bin/openOS.app",
        install = function(self)
            local afpxPath = self.path .. "/openOS.afpx"

            fs.makeDirectory(self.path)
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/openOS.app/main.lua"))
            save(self.path .. "/uninstall.lua", download(selfurlpart .. "/apps/openOS.app/uninstall.lua"))
            save(self.path .. "/icon.t2p", download(self.icon))

            save(self.path .. "/lua5_2.lua", download(selfurlpart .. "/apps/openOS.app/lua5_2.lua"))
            save(self.path .. "/actions.cfg", download(selfurlpart .. "/apps/openOS.app/actions.cfg"))
            
            save(afpxPath, download(selfurlpart .. "/apps/openOS.app/openOS.afpx"))
            require("archiver").unpack(afpxPath, "/")
            fs.remove(afpxPath)
        end
    },
    {
        name = "mineOS",
        version = "3",
        vendor = "IgorTimofeev",
        icon = selfurlpart .. "/apps/mineOS.app/icon.t2p",
        license = selfurlpart .. "/apps/mineOS.app/LICENSE",
        description = "configures dualboot between mineOS and liked\nATTENTION. if you have \"MineOS EFI\" installed, then you will not be able to use liked after installing MineOS. in order to boot into liked, delete the /OS.lua file in the MineOS explorer",
        minDiskSpace = 1024 + 512,
        minColorDepth = 8,
        minRam = 768 * 2, --минимальный обьем ОЗУ для установки

        path = "/vendor/bin/mineOS.app",
        install = function(self)
            local afpxPath = self.path .. "/mineOS.afpx"

            fs.makeDirectory(self.path)
            save(self.path .. "/main.lua", download(selfurlpart .. "/apps/mineOS.app/main.lua"))
            save(self.path .. "/uninstall.lua", download(selfurlpart .. "/apps/mineOS.app/uninstall.lua"))
            save(self.path .. "/icon.t2p", download(self.icon))
            save("/mineOS.lua", download(selfurlpart .. "/apps/mineOS.app/mineOS.lua"))
            
            save(self.path .. "/lua5_2.lua", download(selfurlpart .. "/apps/mineOS.app/lua5_2.lua"))
            save(self.path .. "/actions.cfg", download(selfurlpart .. "/apps/mineOS.app/actions.cfg"))
            save(self.path .. "/LICENSE", download(self.license))

            save(afpxPath, download(selfurlpart .. "/apps/mineOS.app/mineOS.afpx"))
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
        version = "1.2",
        vendor = "logic",
        icon = selfurlpart .. "/apps/camera.app/icon.t2p",
        description = "allows you to take pictures on the camera from the computronix addon.\n* allows you to select a camera from several\n* allows you to save a photo for loading on another computer",
        minDiskSpace = 64,
        minColorDepth = 4,

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
        version = "2",
        vendor = "computercraft",
        description = "the game was ported from computercraft",
        minDiskSpace = 64,

        path = "/data/bin/redirection.app",
        urlPrimaryPart = selfurlpart .. "/apps/redirection.app/",
        files = (function ()
            local files = {"main.lua", "icon.t2p", "select.lua", "actions.cfg"}
            for i = 0, 12 do
                table.insert(files, "levels/" .. tostring(math.round(i)) .. ".dat")
            end
            return files
        end)()
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
        version = "3",
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
    },
    {
        name = "commandBlock",
        version = "1",
        vendor = "logic",
        description = "allows you to control the command block from the computer\nto work, you need to activate \"enableCommandBlockDriver\" in the mod config, then re-enter the game\nthe command block must be connected to the computer by means of an adapter\nit also allows you to run cbs scripts (text files with a queue of commands)",
        minDiskSpace = 64,

        path = "/data/bin/commandBlock.app",
        urlPrimaryPart = selfurlpart .. "/apps/commandBlock.app/",
        files = {"main.lua", "icon.t2p", "uninstall.lua"},

        postInstall = function (self)
            if not registry.icons then registry.icons = {} end
            registry.icons["cbs"] = paths.concat(self.path, "icon.t2p")
            liked.reg("openVia", "cbs", paths.concat(self.path, "main.lua"))
            liked.reg("editable", "cbs", true)
        end
    },
    {
        name = "openFM",
        version = "1",
        vendor = "logic",
        description = "the program for the radio from the OpenFM addon\nit has a number of built-in radio stations",
        minDiskSpace = 64,

        path = "/data/bin/openFM.app",
        urlPrimaryPart = selfurlpart .. "/apps/openFM.app/",
        files = {"main.lua", "icon.t2p", "list.txt"}
    },
    {
        name = "tape",
        version = "1",
        vendor = "logic",
        description = "allows you to record music in dfpwm format to tapes from computronics\nallows you to dump the tape to dfpwm file\nyou can also record music directly over the Internet",
        minDiskSpace = 64,

        path = "/data/bin/tape.app",
        urlPrimaryPart = selfurlpart .. "/apps/tape.app/",
        files = {"main.lua", "icon.t2p", "uninstall.lua", "reg.reg", "unreg.reg"}
    },
    {
        name = "hologram",
        version = "1",
        vendor = "logic",
        description = "this program allows you to display various effects on a holographic projector\nLevel 1 and 2 holographic projectors are supported\neffects can work in the background and on multiple projectors at the same time",
        minDiskSpace = 64,
        libs = {"vec"},

        path = "/data/bin/hologram.app",
        urlPrimaryPart = selfurlpart .. "/apps/hologram.app/",
        files = {"main.lua", "icon.t2p", "holograms/fireworks.lua", "holograms/fullbox.lua", "holograms/tree.lua"}
    },
    {
        name = "printer3d",
        version = "1",
        vendor = "logic",
        description = "allows you to open/edit/save and print 3D models in 3dm format.\nThe model format is fully compatible with the \"3D Print\" program in MineOS.\nalso, models in this format can be found on the Internet without any problems.\nvisualization on a holographic projector is supported",
        minDiskSpace = 64,

        path = "/data/bin/printer3d.app",
        urlPrimaryPart = selfurlpart .. "/apps/printer3d.app/"
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

list.libs = {
    ["vec"] = {
        url = selfurlpart .. "/libs/vec.lua",
        vendor = "logic",
        version = "1"
    }
}

return list