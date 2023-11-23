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

local function download(path, url)
    assert(internet.download(url, path))
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
        version = "2.2",
        vendor = "logic",
        description = "allows you to control nanobots using a wireless modem",
        minDiskSpace = 64,

        path = "/data/apps/nanomachines.app",
        urlPrimaryPart = selfurlpart .. "/apps/nanomachines.app/",
        files = {"main.lua", "icon.t2p"}
    },
    {
        name = "worm",
        version = "1",
        vendor = "computercraft",
        description = "classic snake ported from computercraft",
        minDiskSpace = 64,

        path = "/data/apps/worm.app",
        urlPrimaryPart = selfurlpart .. "/apps/worm.app/",
        files = {"main.lua", "icon.t2p"}
    },
    {
        name = "chat",
        version = "2.6",
        vendor = "logic",
        icon = selfurlpart .. "/apps/chat.app/icon.t2p",
        description = "allows you to exchange messages, pictures and files between computers via a network card",
        minDiskSpace = 64,

        path = "/data/apps/chat.app",
        install = function(self)
            fs.makeDirectory("/data/apps/chat.app")
            download("/data/apps/chat.app/main.lua", selfurlpart .. "/apps/chat.app/main.lua")
            download("/data/apps/chat.app/icon.t2p", self.icon)
            download("/data/apps/chat.app/uninstall.lua", selfurlpart .. "/apps/chat.app/uninstall.lua")

            fs.makeDirectory("/data/autoruns")
            download("/data/autoruns/chat_demon.lua", selfurlpart .. "/apps/chat.app/autorun.lua")

            fs.makeDirectory("/data/lib")
            download("/data/lib/chat_lib.lua", selfurlpart .. "/apps/chat.app/chat_lib.lua")
            download("/data/lib/modem_chat_lib.lua", selfurlpart .. "/apps/chat.app/modem_chat_lib.lua")
        
            assert(programs.execute("/data/autoruns/chat_demon.lua"))
        end
    },
    {
        name = "irc",
        version = "1",
        vendor = "Nathan Flynn",
        description = "allows you to connect to IRC chats via an Internet card.\nprogram ported from openOS",
        minDiskSpace = 64,

        path = "/data/apps/irc.app",
        urlPrimaryPart = selfurlpart .. "/apps/irc.app/",
        files = {"main.lua", "icon.t2p"}
    },
    {
        name = "brainfuck",
        version = "2",
        vendor = "logic",
        description = "brainfuck code interpreter",
        minDiskSpace = 64,
        libs = {"brainfuck"},

        path = "/data/apps/brainfuck.app",
        urlPrimaryPart = selfurlpart .. "/apps/brainfuck.app/"
    },
    {
        name = "lua",
        version = "4",
        vendor = "logic",
        description = "lua code interpreter",
        minDiskSpace = 64,

        path = "/data/apps/lua.app",
        urlPrimaryPart = selfurlpart .. "/apps/lua.app/",
        files = {"main.lua", "icon.t2p"}
    },
    {
        name = "events",
        version = "3",
        vendor = "logic",
        description = "allows you to view computer events",
        minDiskSpace = 64,

        path = "/data/apps/events.app",
        urlPrimaryPart = selfurlpart .. "/apps/events.app/",
        files = {"main.lua", "icon.t2p"}
    },
    {
        name = "openOS",
        version = "1.8.3;2",
        vendor = "MightyPirates",
        icon = selfurlpart .. "/apps/openOS.app/icon.t2p",
        description = "configures dualboot between openOS and liked",
        minDiskSpace = 1024,
        dualboot = true,

        path = "/vendor/apps/openOS.app",
        install = function(self)
            local afpxPath = self.path .. "/openOS.afpx"

            fs.makeDirectory(self.path)
            download(self.path .. "/main.lua", selfurlpart .. "/apps/openOS.app/main.lua")
            download(self.path .. "/uninstall.lua", selfurlpart .. "/apps/openOS.app/uninstall.lua")
            download(self.path .. "/icon.t2p", self.icon)

            download(self.path .. "/lua5_2.lua", selfurlpart .. "/apps/openOS.app/lua5_2.lua")
            download(self.path .. "/actions.cfg", selfurlpart .. "/apps/openOS.app/actions.cfg")
            
            download(afpxPath, selfurlpart .. "/apps/openOS.app/openOS.afpx")

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
        dualboot = true,

        path = "/vendor/apps/mineOS.app",
        install = function(self)
            local afpxPath = self.path .. "/mineOS.afpx"

            fs.makeDirectory(self.path)
            download(self.path .. "/main.lua", selfurlpart .. "/apps/mineOS.app/main.lua")
            download(self.path .. "/uninstall.lua", selfurlpart .. "/apps/mineOS.app/uninstall.lua")
            download(self.path .. "/icon.t2p", self.icon)
            download("/mineOS.lua", selfurlpart .. "/apps/mineOS.app/mineOS.lua")
            
            download(self.path .. "/lua5_2.lua", selfurlpart .. "/apps/mineOS.app/lua5_2.lua")
            download(self.path .. "/actions.cfg", selfurlpart .. "/apps/mineOS.app/actions.cfg")
            download(self.path .. "/LICENSE", self.license)

            download(afpxPath, selfurlpart .. "/apps/mineOS.app/mineOS.afpx")

            require("archiver").unpack(afpxPath, "/")
            fs.remove(afpxPath)
        end
    },
    {
        name = "explode",
        version = "2",
        vendor = "logic",
        description = "blow up your computer!",
        minDiskSpace = 64,

        path = "/data/apps/explode.app",
        urlPrimaryPart = selfurlpart .. "/apps/explode.app/",
        files = {"main.lua", "icon.t2p", "config.cfg"}
    },
    {
        name = "camera",
        version = "1.3",
        vendor = "logic",
        description = "allows you to take pictures on the camera from the computronix addon.\n* allows you to select a camera from several\n* allows you to save a photo for loading on another computer",
        minDiskSpace = 64,

        path = "/data/apps/camera.app",
        urlPrimaryPart = selfurlpart .. "/apps/camera.app/",
        files = {"main.lua", "icon.t2p", "formats.cfg", "config.cfg"}
    },
    {
        name = "redirection",
        version = "3",
        vendor = "computercraft",
        description = "the game was ported from computercraft",
        minDiskSpace = 64,

        path = "/data/apps/redirection.app",
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

        path = "/data/apps/adventure.app",
        urlPrimaryPart = selfurlpart .. "/apps/adventure.app/" --часть url к которой будут присираться разные имена файлов для скачивания(обязателен / на конце)
    },
    {
        name = "magnet",
        version = "4",
        vendor = "logic",
        description = "a program for controlling a magnet that attracts resources(tractor_beam-upgrade)",
        minDiskSpace = 64,

        path = "/data/apps/magnet.app",
        urlPrimaryPart = selfurlpart .. "/apps/magnet.app/", --часть url к которой будут присираться разные имена файлов для скачивания(обязателен / на конце)
        files = {"main.lua", "icon.t2p", "uninstall.lua"}
    },
    {
        name = "piston",
        version = "4",
        vendor = "logic",
        description = "a program for controlling a piston(piston-upgrade)",
        minDiskSpace = 64,

        path = "/data/apps/piston.app",
        urlPrimaryPart = selfurlpart .. "/apps/piston.app/", --часть url к которой будут присираться разные имена файлов для скачивания(обязателен / на конце)
        files = {"main.lua", "icon.t2p", "uninstall.lua"}
    },
    {
        name = "commandBlock",
        version = "2",
        vendor = "logic",
        description = "allows you to control the command block from the computer\nto work, you need to activate \"enableCommandBlockDriver\" in the mod config, then re-enter the game\nthe command block must be connected to the computer by means of an adapter\nit also allows you to run cbs scripts (text files with a queue of commands)",
        minDiskSpace = 64,

        path = "/data/apps/commandBlock.app",
        urlPrimaryPart = selfurlpart .. "/apps/commandBlock.app/",
        files = {"main.lua", "icon.t2p", "formats.cfg"},
    },
    {
        name = "openFM",
        version = "1",
        vendor = "logic",
        description = "the program for the radio from the OpenFM addon\nit has a number of built-in radio stations",
        minDiskSpace = 64,

        path = "/data/apps/openFM.app",
        urlPrimaryPart = selfurlpart .. "/apps/openFM.app/",
        files = {"main.lua", "icon.t2p", "list.txt"}
    },
    {
        name = "tape",
        version = "1",
        vendor = "logic",
        description = "allows you to record music in dfpwm format to tapes from computronics\nallows you to dump the tape to dfpwm file\nyou can also record music directly over the Internet",
        minDiskSpace = 64,

        path = "/data/apps/tape.app",
        urlPrimaryPart = selfurlpart .. "/apps/tape.app/",
        files = {"main.lua", "icon.t2p", "formats.cfg"}
    },
    {
        name = "hologram",
        version = "3",
        vendor = "logic",
        description = "this program allows you to display various effects on a holographic projector\nLevel 1 and 2 holographic projectors are supported\neffects can work in the background and on multiple projectors at the same time",
        minDiskSpace = 64,
        libs = {"vec"},

        path = "/data/apps/hologram.app",
        urlPrimaryPart = selfurlpart .. "/apps/hologram.app/",
        files = {"main.lua", "icon.t2p", "unreg.reg", "autorun.lua", "holograms/fireworks.lua", "holograms/fullbox.lua", "holograms/tree.lua"}
    },
    {
        name = "printer3d",
        version = "1",
        vendor = "logic",
        description = "allows you to open/edit/save and print 3D models in 3dm format.\nThe model format is fully compatible with the \"3D Print\" program in MineOS.\nalso, models in this format can be found on the Internet without any problems.\nvisualization on a holographic projector is supported",
        minDiskSpace = 64,

        path = "/data/apps/printer3d.app",
        urlPrimaryPart = selfurlpart .. "/apps/printer3d.app/"
    },
    {
        name = "toolbox",
        version = "1",
        vendor = "logic",
        description = "contains a minecraft-style watch and compass\nthe compass points north and only works on a tablet",
        minDiskSpace = 64,

        path = "/data/apps/toolbox.app",
        urlPrimaryPart = selfurlpart .. "/apps/toolbox.app/",
        files = {"compass.t2p", "watch.t2p", "icon.t2p", "main.lua"}
    },
    {
        name = "chunkloader",
        version = "1",
        vendor = "logic",
        description = "the program for managing the chankloader",
        minDiskSpace = 64,

        path = "/data/apps/chunkloader.app",
        urlPrimaryPart = selfurlpart .. "/apps/chunkloader.app/"
    },
    {
        name = "assembler",
        version = "1",
        vendor = "logic",
        description = "the program for managing the assembler",
        minDiskSpace = 64,

        path = "/data/apps/assembler.app",
        urlPrimaryPart = selfurlpart .. "/apps/assembler.app/"
    },
    {
        name = "cardwriter",
        version = "2",
        vendor = "logic",
        description = "program for write cards and EEPROM's via card writer",
        minDiskSpace = 64,

        path = "/data/apps/cardwriter.app",
        urlPrimaryPart = selfurlpart .. "/apps/cardwriter.app/"
    },
    {
        name = "calculator",
        version = "1",
        vendor = "logic",
        description = "this is an engineering calculator that supports a lot of functions",
        minDiskSpace = 64,

        path = "/data/apps/calculator.app",
        urlPrimaryPart = selfurlpart .. "/apps/calculator.app/"
    },
    {
        name = "openbox",
        version = "1",
        vendor = "logic",
        description = "this program allows you to run software from openOS on liked in compatibility mode",
        minDiskSpace = 64,
        executer = true,
        libs = {"openbox"},

        path = "/data/apps/openbox.app",
        urlPrimaryPart = selfurlpart .. "/apps/openbox.app/"
    },
    {
        name = "navigation",
        version = "1",
        vendor = "logic",
        description = "navigation apps. requires upgrade \"navigation\"",
        minDiskSpace = 64,

        path = "/data/apps/navigation.app",
        urlPrimaryPart = selfurlpart .. "/apps/navigation.app/"
    },
    {
        name = "tquest",
        version = "1",
        vendor = "MineCR",
        description = "quest ported from hipOS.\ndeveloped by MineCR.\nyoutube - Max Play`n",
        minDiskSpace = 64,
        libs = {"openbox"},

        path = "/data/apps/tquest.app",
        urlPrimaryPart = selfurlpart .. "/apps/tquest.app/",
        files = {"main.lua", "icon.t2p", "program.lua"}
    }
}

list.libs = {
    ["vec"] = {
        url = selfurlpart .. "/libs/vec.lua",
        vendor = "logic",
        version = "1"
    },
    ["brainfuck"] = {
        url = selfurlpart .. "/libs/brainfuck.lua",
        vendor = "logic",
        version = "1"
    },
    ["openbox"] = {
        url = selfurlpart .. "/libs/openbox.lua",
        vendor = "logic",
        version = "2"
    }
}

return list