local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local event = require("event")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local themesPath = "/system/themes"

------------------------------------

local selectWindow = graphic.classWindow:new(screen, posX, posY, 16, ry - (posY - 1))
local limit = 0
local themes = {}
for i, file in ipairs(fs.list(themesPath) or {}) do
    limit = limit + 1
    table.insert(themes, file)
end

local selected = 1

------------------------------------

local function draw()
    selectWindow:clear(colors.gray)
    selectWindow:setCursor(1, 1)
    for i, file in ipairs(themes) do
        local str = paths.hideExtension(file) .. string.rep(" ", (selectWindow.sizeX - 2) - unicode.len(file))

        local background = colors.gray
        local foreground = selected == i and colors.white or colors.black

        selectWindow:write("╔" .. string.rep("═", unicode.len(str)) .. "╗\n", background, foreground)
        selectWindow:write("║", background, foreground)
        selectWindow:write(str, background, foreground)
        selectWindow:write("║" .. "\n", background, foreground)
        selectWindow:write("╚" .. string.rep("═", unicode.len(str)) .. "╝", background, foreground)

        if i ~= limit then selectWindow:write("\n") end
    end
end
draw()

------------------------------------

return function(eventData)
    local selectWindowEventData = selectWindow:uploadEvent(eventData)

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
    elseif selectWindowEventData[1] == "touch" then
        local posY = ((selectWindowEventData[4] - 1) // 3) + 1

        if posY >= 1 and posY <= limit then
            if posY ~= selected then
                selected = posY
                draw()
            end
        end
    elseif selectWindowEventData[1] == "key_down" then
        local oldselected = selected
        if selectWindowEventData[4] == 200 then
            selected = selected - 1
            if selected < 1 then selected = 1 end
        elseif selectWindowEventData[4] == 208 then
            selected = selected + 1
            if selected > limit then selected = limit end
        end
        if selected ~= oldselected then
            draw()
        end
    end
end