local paths = require("paths")
local fs = require("filesystem")

fs.remove(paths.path(getPath()))
fs.remove("/data/autoruns/chat_demon.lua")
fs.remove("/data/lib/modem_chat_lib.lua")
fs.remove("/data/lib/chat_lib.lua")

local filesExps = require("gui_container").filesExps

for i = #filesExps, 1, -1 do
    if filesExps[i][2] == "chat" then
        table.remove(filesExps, i)
    end
end