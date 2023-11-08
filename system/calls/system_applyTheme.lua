local fs = require("filesystem")
local calls = require("calls")
local component  = require("component")
local graphic = require("graphic")
local gui_container = _G.gui_container or require("gui_container")
local path, screen = ...

local file = assert(fs.open(path, "rb"))
local themeData = file.readAll()
file.close()

local colors = calls.call("unserialization", themeData)
movetable(gui_container.indexsColors, colors)
movetable(gui_container.colors, {
    white     = colors[1],
    orange    = colors[2],
    magenta   = colors[3],
    lightBlue = colors[4],
    yellow    = colors[5],
    lime      = colors[6],
    pink      = colors[7],
    gray      = colors[8],
    lightGray = colors[9],
    cyan      = colors[10],
    purple    = colors[11],
    blue      = colors[12],
    brown     = colors[13],
    green     = colors[14],
    red       = colors[15],
    black     = colors[16]
})

local function applyOnScreen(address)
    if graphic.maxDepth(address) ~= 1 then
        local count = 0
        for i, v in ipairs(colors) do
            if graphic.getPaletteColor(address, count) ~= v then
                graphic.setPaletteColor(address, count, v)
            end
            count = count + 1
        end
    end
end

if screen then
    applyOnScreen(screen)
else
    for address in component.list("screen") do
        applyOnScreen(address)
    end
end