local graphic = require("graphic")
local event = require("event")
local programs = require("programs")
local fs = require("filesystem")
local calls = require("calls")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")

local colors = gui_container.colors

------------------------------------

local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()
local path = paths.path(calls.call("getPath"))
local modulesPath = paths.concat(path, "modules")

------------------------------------

local selectWindow = graphic.classWindow:new(screen, 1, 1, rx // 4, ry)
local modulWindow = graphic.classWindow:new(screen, rx // 4, 1, (rx - (rx // 4)) + 1, ry)

local scroll = 1
local function draw()
    selectWindow:clear(colors.white)
    modulWindow:clear(colors.gray)

    selectWindow:setCursor(1, scroll)
    selectWindow:write(modulesPath .. "\n")
    for _, file in ipairs(fs.list(modulesPath) or {}) do
        selectWindow:write("╔" .. string.rep("═", unicode.len(file)) .. "╗\n")
        selectWindow:write("║" .. file .. "║\n")
        selectWindow:write("╚" .. string.rep("═", unicode.len(file)) .. "╝\n")
    end
end
draw()

while true do
    local eventData = {event.pull()}
    local selectWindowEventData = selectWindow:uploadEvent(eventData)
    local modulWindowEventData = selectWindow:uploadEvent(eventData)

    if selectWindowEventData[1] == "scroll" then
        scroll = scroll + selectWindowEventData[5]
        draw()
    end
end