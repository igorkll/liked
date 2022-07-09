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

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx // 4, 1)
local selectWindow = graphic.classWindow:new(screen, 1, 2, rx // 4, ry - 1)
local modulWindow = graphic.classWindow:new(screen, (rx // 4) + 1, 1, (rx - (rx // 4)), ry)

local selected = 1
local limit = 0
local modules = {}
for i, file in ipairs(fs.list(modulesPath) or {}) do
    limit = 1
    table.insert(modules, file)
end

local function draw()
    selectWindow:clear(colors.lightGray)
    modulWindow:clear(colors.gray)
    statusWindow:clear(colors.black)

    limit = 0
    selectWindow:setCursor(1, 1)
    for i, file in ipairs(modules) do
        local background = colors.lightGray
        local foreground = selected == i and colors.white or colors.black

        selectWindow:write("╔" .. string.rep("═", unicode.len(file)) .. "╗\n", background, foreground)
        selectWindow:write("║", background, foreground)
        selectWindow:write(file, background, foreground)
        selectWindow:write("║" .. "\n", background, foreground)
        selectWindow:write("╚" .. string.rep("═", unicode.len(file)) .. "╝\n", background, foreground)

        limit = limit + 1
    end
end
draw()

while true do
    local eventData = {event.pull()}
    local selectWindowEventData = selectWindow:uploadEvent(eventData)
    local modulWindowEventData = selectWindow:uploadEvent(eventData)

    if selectWindowEventData[1] == "scroll" then
        local oldselected = selected
        if selectWindowEventData[5] > 0 then
            selected = selected - 1
            if selected < 1 then selected = 1 end
        else
            selected = selected + 1
            if selected > limit then selected = limit end
        end
        if selected ~= oldselected then
            draw()
        end
    end
end