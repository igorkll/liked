local fs = require("filesystem")
local calls = require("calls")
local component  = require("component")
local graphic = require("graphic")
local gui_container = gui_container or require("gui_container")
local path = ...

local file = assert(fs.open(path, "rb"))
local data = file.readAll()
file.close()

local tbl = calls.call("unserialization", data)
local newindexcolors = tbl
local newcolors = {
    white     = tbl[1],
    orange    = tbl[2],
    magenta   = tbl[3],
    lightBlue = tbl[4],
    yellow    = tbl[5],
    lime      = tbl[6],
    pink      = tbl[7],
    gray      = tbl[8],
    lightGray = tbl[9],
    cyan      = tbl[10],
    purple    = tbl[11],
    blue      = tbl[12],
    brown     = tbl[13],
    green     = tbl[14],
    red       = tbl[15],
    black     = tbl[16]
}

for k, v in pairs(newcolors) do
    gui_container.colors[k] = newcolors[k]
end
for k, v in pairs(newindexcolors) do
    gui_container.indexsColors[k] = newindexcolors[k]
end

for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.maxDepth() ~= 1 then
        local count = 0
        for i, v in pairs(gui_container.colors) do
            gpu.setPaletteColor(count, v)
            count = count + 1
        end
    end
end