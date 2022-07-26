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

local wallpapersPath = "/system/wallpapers"

------------------------------------

local currentWallpaperData
if fs.exists("/data/wallpaper.t2p") then
    local file = assert(fs.open("/data/wallpaper.t2p", "rb"))
    currentWallpaperData = file.readAll()--получаем файл текуший темы для сравнения
    file.close()
end

local selectWindow = graphic.createWindow(screen, posX, posY, 16, ry - (posY - 1))
local selected = 1
local wallpapaers = {"none"}
for i, file in ipairs(fs.list(wallpapersPath) or {}) do
    table.insert(wallpapaers, file)
end

if currentWallpaperData then
    selected = nil
    for i, file in ipairs(fs.list(wallpapersPath) or {}) do
        local file = assert(fs.open(paths.concat(wallpapersPath, file), "rb"))
        local data = file.readAll()--получаем файл темы
        file.close()

        if data == currentWallpaperData then
            selected = i + 1
            break
        end
    end
end

------------------------------------

local function draw(set)
    selectWindow:clear(colors.gray)
    selectWindow:setCursor(1, 1)
    for i, file in ipairs(wallpapaers) do
        file = paths.hideExtension(file)
        local str = file .. string.rep(" ", (selectWindow.sizeX - 2) - unicode.len(file))

        local background = colors.gray
        local foreground = selected == i and colors.white or colors.black

        selectWindow:write("╔" .. string.rep("═", unicode.len(str)) .. "╗\n", background, foreground)
        selectWindow:write("║", background, foreground)
        selectWindow:write(str, background, foreground)
        selectWindow:write("║" .. "\n", background, foreground)
        selectWindow:write("╚" .. string.rep("═", unicode.len(str)) .. "╝", background, foreground)

        if i ~= #wallpapaers then selectWindow:write("\n") end
    end

    if set then
        if selected == 1 then
            fs.remove("/data/wallpaper.t2p")
        else
            fs.copy(paths.concat(wallpapersPath, wallpapaers[selected]), "/data/wallpaper.t2p")
        end
        event.push("redrawDesktop")
    end
end
draw()

------------------------------------

return function(eventData)
    local selectWindowEventData = selectWindow:uploadEvent(eventData)

    if selectWindowEventData[1] == "scroll" then
        if selected then
            local oldselected = selected
            if selectWindowEventData[5] > 0 then
                selected = selected - 1
                if selected < 1 then selected = 1 end
            else
                selected = selected + 1
                if selected > #wallpapaers then selected = #wallpapaers end
            end
            if selected ~= oldselected then
                draw(true)
            end
        else
            selected = 1
        end
    elseif selectWindowEventData[1] == "touch" then
        local posY = ((selectWindowEventData[4] - 1) // 3) + 1

        if posY >= 1 and posY <= #wallpapaers then
            if posY ~= selected then
                selected = posY
                draw(true)
            end
        end
    elseif selectWindowEventData[1] == "key_down" then
        if selected then
            local oldselected = selected
            if selectWindowEventData[4] == 200 then
                selected = selected - 1
                if selected < 1 then selected = 1 end
            elseif selectWindowEventData[4] == 208 then
                selected = selected + 1
                if selected > #wallpapaers then selected = #wallpapaers end
            end
            if selected ~= oldselected then
                draw(true)
            end
        else
            selected = 1
        end
    end
end