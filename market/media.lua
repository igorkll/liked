local unicode = require("unicode")
local paths = require("paths")
local fs = require("filesystem")

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
        name = "midipack",
        version = "1",
        vendor = "logic",
        description = "a set of midi files",
        minDiskSpace = 64,
        
        path = "/data/userdata/midipack",
        urlPrimaryPart = selfurlpart .. "/media/midipack/",
        files = {"icon.t2p", "aSongAboutHares.mid", "theIslandOfBadLuck.mid", "duckTalesTheme.mid", "gazaStripJava.mid", "gazaStripPunk.mid"},
        
        postInstall = function (self)
            fs.setAttribute(paths.concat(self.path, "icon.t2p"), "hidden", true)
        end
    },
    {
        name = "t2wallpaperPack",
        version = "1",
        vendor = "logic",
        description = "a set of wallpapers for tier2",
        minDiskSpace = 64,
        
        path = "/data/userdata/t2wallpaperPack",
        urlPrimaryPart = selfurlpart .. "/media/t2wallpaperPack/",
        files = {"icon.t2p", "1.t2p", "2.t2p", "3.t2p", "4.t2p"},
        
        postInstall = function (self)
            fs.setAttribute(paths.concat(self.path, "icon.t2p"), "hidden", true)
        end
    },
    {
        name = "t3wallpaperPack",
        version = "1",
        vendor = "logic",
        description = "a set of wallpapers for tier3",
        minDiskSpace = 64,
        
        path = "/data/userdata/t3wallpaperPack",
        urlPrimaryPart = selfurlpart .. "/media/t3wallpaperPack/",
        files = {"icon.t2p", "1.t3p", "2.t3p", "3.t3p", "4.t3p"},
        
        postInstall = function (self)
            fs.setAttribute(paths.concat(self.path, "icon.t2p"), "hidden", true)
        end
    },
    {
        name = "slideshow",
        version = "1",
        vendor = "logic",
        description = "slideshow set for tier2 and tier3",
        minDiskSpace = 64,
        
        path = "/data/userdata/slideshow",
        urlPrimaryPart = selfurlpart .. "/media/slideshow/",
        files = (function()
            local list = {"icon.t2p"}
            for i = 1, 10 do
                table.insert(list, tostring(math.round(i)) .. ".t2p")
                table.insert(list, tostring(math.round(i)) .. ".t3p")
            end
            return list
        end)(),
        
        postInstall = function (self)
            fs.setAttribute(paths.concat(self.path, "icon.t2p"), "hidden", true)
        end
    }
}

return list