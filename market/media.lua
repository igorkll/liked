local unicode = require("unicode")
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
        files = {"icon.t2p", "aSongAboutHares.mid", "theIslandOfBadLuck.mid", "duckTalesTheme.mid", "GazaStripJava.mid", "gazaStripPunk.mid"}
    }
}

return list