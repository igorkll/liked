local graphic = require("graphic")
local fs = require("filesystem")
local event = require("event")
local gui_container = require("gui_container")
local calls = require("calls")

local colors = gui_container.colors

------------------------------------

local screen, filepath = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local mainWindow = graphic.classWindow:new(screen, 1, 2, rx - 8, ry - 1)
local paletteWindow = graphic.classWindow:new(screen, rx - 7, 2, 8, 18)
local nullWindow2 = graphic.classWindow:new(screen, rx - 7, 2 + paletteWindow.sizeY, 8, ry - 19)

------------------------------------

local selectedColor1 = 1
local selectedColor2 = 1
local image

local function drawSelectedColors()
    nullWindow2:fill(1, 1, nullWindow2.sizeX, nullWindow2.sizeY, colors.green, colors.black, "▒")
    nullWindow2:fill(2, 2, 2, nullWindow2.sizeY - 2, gui_container.indexsColors[selectedColor1], 0, " ")
    nullWindow2:fill(nullWindow2.sizeX - 2, 2, 2, nullWindow2.sizeY - 2, gui_container.indexsColors[selectedColor2], 0, " ")
end

local function drawColors()
    paletteWindow:fill(1, 1, paletteWindow.sizeX, paletteWindow.sizeY, colors.brown, colors.black, "▒")
    for i, v in ipairs(gui_container.indexsColors) do
        paletteWindow:set(2, i + 1, v, 0, "      ")
    end
    paletteWindow:fill(4, 1, 2, paletteWindow.sizeY, colors.brown, colors.black, "▒")
end

local function drawUi()
    mainWindow:clear(colors.lightGray)

    statusWindow:clear(colors.gray)
    statusWindow:set(1, 1, colors.red, colors.white, "X")
    statusWindow:set(rx - 5, 1, colors.gray, colors.white, "paint")
    statusWindow:set(3, 1, colors.white, colors.black, "file")
    statusWindow:set(8, 1, colors.white, colors.black, "settings")
end

local function drawImage()
    
end

local function draw()
    drawUi()
    drawColors()
    drawSelectedColors()
    drawImage()
end
draw()

local function load()
    local readbit = calls.load("readbit")

    local file = assert(fs.open(filepath, "rb"))
    local buffer = file.readAll()
    file.close()
    local function read(bytecount)
        local str = buffer:sub(1, bytecount)
        buffer = buffer:sub(bytecount + 1, #buffer)
        return str
    end

    local sizeX = string.byte(read(1))
    local sizeY = string.byte(read(1))
    read(8)

    mainWindow:fill(1, 1, sizeX, sizeY, colors.gray, colors.white, "▒")

    local colorByte, countCharBytes, background, foreground, char
    for cy = 1, sizeY do
        for cx = 1, sizeX do
            colorByte      = string.byte(read(1))
            countCharBytes = string.byte(read(1))

            background = 
            ((readbit(colorByte, 1) and 1 or 0) * 1) + 
            ((readbit(colorByte, 2) and 1 or 0) * 2) + 
            ((readbit(colorByte, 3) and 1 or 0) * 4) + 
            ((readbit(colorByte, 4) and 1 or 0) * 8)
            foreground = 
            ((readbit(colorByte, 5) and 1 or 0) * 1) + 
            ((readbit(colorByte, 6) and 1 or 0) * 2) + 
            ((readbit(colorByte, 7) and 1 or 0) * 4) + 
            ((readbit(colorByte, 8) and 1 or 0) * 8)
            background = colors[background]
            foreground = colors[foreground]

            if background ~= 0 and foreground ~= 0 then
                char = read(countCharBytes)
                mainWindow:set(1, 1, background, foreground, char)
            end
        end
    end
end
load()

while true do
    local eventData = {event.pull()}
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    local paletteWindowEventData = paletteWindow:uploadEvent(eventData)

    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[3] == 1 and statusWindowEventData[4] == 1 then
            break
        end
        if statusWindowEventData[3] >= 3 and statusWindowEventData[3] <= 6 then
            local num, str = calls.call("gui_context", screen, 4, 2, {"  close", "------------------", "  save"},
            {true, false, true})
            if num == 1 then
                break
            elseif num == 3 then
            end
        end
    end

    if paletteWindowEventData[1] == "touch" then
        if paletteWindowEventData[4] >= 2 and paletteWindowEventData[4] <= paletteWindow.sizeY - 1 then
            local colorIndex = paletteWindowEventData[4] - 1
            local to
            if paletteWindowEventData[3] >= 2 and paletteWindowEventData[3] <= 3 then
                to = false
            elseif paletteWindowEventData[3] >= 6 and paletteWindowEventData[3] <= 7 then
                to = true
            end
            if to == true then
                selectedColor2 = colorIndex
                drawSelectedColors()
            elseif to == false then
                selectedColor1 = colorIndex
                drawSelectedColors()
            end
        end
    end
end