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
        name = "midi",
        version = "1",
        vendor = "logic",
        description = "allows to play midi files",
        minDiskSpace = 64,
        
        path = "/data/apps/midi.app",
        urlPrimaryPart = selfurlpart .. "/apps/midi.app/",
        files = {"main.lua", "icon.t2p", "formats.cfg"}
    }
}

return list