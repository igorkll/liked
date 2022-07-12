local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local themesPath = "/system/themes"

------------------------------------

local currentThemeData
if fs.exists("/data/theme.plt") then
    local file = assert(fs.open("/data/theme.plt", "rb"))
    currentThemeData = file.readAll()--получаем файл текуший темы для сравнения
    file.close()
end

local selectWindow = graphic.classWindow:new(screen, posX, posY, 16, ry - (posY - 1))
local colorsWindow = graphic.classWindow:new(screen, posX + 17, posY, 8, 18)
local limit = 0
local selected = 1
local themes = {}
for i, file in ipairs(fs.list(themesPath) or {}) do
    limit = limit + 1
    table.insert(themes, file)

    local file = assert(fs.open(paths.concat(themesPath, file), "rb"))
    local data = file.readAll()--получаем файл темы
    file.close()

    if data == currentThemeData then
        selected = i
    end
end

------------------------------------

local function draw(set)
    selectWindow:clear(colors.gray)
    colorsWindow:fill(1, 1, colorsWindow.sizeX, colorsWindow.sizeY, colors.gray, colors.brown, "▒")
    selectWindow:setCursor(1, 1)

    for i, v in ipairs(gui_container.indexsColors) do
        colorsWindow:set(2, i + 1, v, 0, "      ")
    end

    for i, file in ipairs(themes) do
        file = paths.hideExtension(file)
        local str = file .. string.rep(" ", (selectWindow.sizeX - 2) - unicode.len(file))

        local background = colors.gray
        local foreground = selected == i and colors.white or colors.black

        selectWindow:write("╔" .. string.rep("═", unicode.len(str)) .. "╗\n", background, foreground)
        selectWindow:write("║", background, foreground)
        selectWindow:write(str, background, foreground)
        selectWindow:write("║" .. "\n", background, foreground)
        selectWindow:write("╚" .. string.rep("═", unicode.len(str)) .. "╝", background, foreground)

        if i ~= limit then selectWindow:write("\n") end
    end

    if set then
        calls.call("system_setTheme", paths.concat(themesPath, themes[selected]))
    end
    event.push("redrawDesktop")
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
            draw(true)
        end
    elseif selectWindowEventData[1] == "touch" then
        local posY = ((selectWindowEventData[4] - 1) // 3) + 1

        if posY >= 1 and posY <= limit then
            if posY ~= selected then
                selected = posY
                draw(true)
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
            draw(true)
        end
    end
end