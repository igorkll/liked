local fs = require("filesystem")
local serialization = require("serialization")
local component  = require("component")
local graphic = require("graphic")
local gui_container = _G.gui_container or require("gui_container")
local path, screen = ...

local colors = assert(serialization.load(path))

local function movetable(maintable, newtable)
    for k, v in pairs(maintable) do
        maintable[k] = nil
    end
    for k, v in pairs(newtable) do
        maintable[k] = v
    end
end

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