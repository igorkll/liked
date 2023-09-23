local graphic = require("graphic")
local fs = require("filesystem")
local event = require("event")
local gui_container = require("gui_container")
local calls = require("calls")
local component = require("component")
local unicode = require("unicode")
local computer = require("computer")
local lastinfo = require("lastinfo")
local gui = require("gui")

local colors = gui_container.colors
local indexsColors = gui_container.indexsColors

------------------------------------

local screen, nickname, filepath = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local mainWindow = graphic.createWindow(screen, 1, 2, rx - 8, ry - 1)
local paletteWindow = graphic.createWindow(screen, rx - 7, 2, 8, 18)
local nullWindow2 = graphic.createWindow(screen, rx - 7, 2 + paletteWindow.sizeY, 8, ry - 19)

------------------------------------

local selectedColor1 = 1
local selectedColor2 = 1
local noSaved
local selectedChar = " "
local image = 
{
    sizeX = 8,
    sizeY = 4,

    {
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "}
    },
    {
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "}
    },
    {
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "}
    },
    {
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "},
        {0, 0, " "}
    },
}

local function drawSelectedColors()
    nullWindow2:fill(1, 1, nullWindow2.sizeX, nullWindow2.sizeY, colors.green, colors.black, "▒")

    nullWindow2:set(2, nullWindow2.sizeY, colors.green, colors.black, "B")
    nullWindow2:set(nullWindow2.sizeX - 2, nullWindow2.sizeY, colors.green, colors.black, "F")
    nullWindow2:set(nullWindow2.sizeX - 4, nullWindow2.sizeY, colors.green, colors.black, "C")

    nullWindow2:fill(2, 2, 2, nullWindow2.sizeY - 2, indexsColors[selectedColor1], 0, " ")
    nullWindow2:fill(nullWindow2.sizeX - 2, 2, 2, nullWindow2.sizeY - 2, indexsColors[selectedColor2], 0, " ")

    nullWindow2:set(nullWindow2.sizeX - 4, nullWindow2.sizeY - 1, colors.green, colors.lime, ">")
    nullWindow2:set(nullWindow2.sizeX - 3, nullWindow2.sizeY - 1, indexsColors[selectedColor1], indexsColors[selectedColor2], selectedChar)
end

local function drawColors()
    paletteWindow:fill(1, 1, paletteWindow.sizeX, paletteWindow.sizeY, colors.brown, colors.black, "▒")
    for i, v in ipairs(indexsColors) do
        paletteWindow:set(2, i + 1, v, 0, "      ")
    end
    paletteWindow:fill(4, 1, 2, paletteWindow.sizeY, colors.brown, colors.black, "▒")
end

local function drawUi()
    mainWindow:fill(1, 1, mainWindow.sizeX, mainWindow.sizeY, colors.white, colors.black, "▓")

    statusWindow:clear(colors.gray)
    statusWindow:set(1, 1, colors.red, colors.white, "X")
    statusWindow:set(rx - 5, 1, colors.gray, colors.white, "paint")
    statusWindow:set(3, 1, colors.white, colors.black, "file")
    statusWindow:set(8, 1, colors.white, colors.black, "edit")
end

local function drawPixel(x, y, pixel)
    if pixel[1] ~= 0 or pixel[2] ~= 0 then
        mainWindow:set(x, y, indexsColors[pixel[1] + 1], indexsColors[pixel[2] + 1], pixel[3])
    else
        mainWindow:set(x, y, colors.white, colors.black, "▒")
    end
end

local function raw_save(path)
    local buffer = ""
    buffer = buffer .. string.char(image.sizeX)
    buffer = buffer .. string.char(image.sizeY)
    buffer = buffer .. string.rep(string.char(0), 8)

    local writebit = calls.load("writebit")
    local readbit = calls.load("readbit")
    
    for y, tbl in ipairs(image) do
        for x, pixel in ipairs(tbl) do
            local bg = 0
            for i = 0, 3 do
                bg = writebit(bg, i, readbit(pixel[1], i))
                bg = writebit(bg, i + 4, readbit(pixel[2], i))
            end
            buffer = buffer .. string.char(bg)
            buffer = buffer .. string.char(#pixel[3])
            buffer = buffer .. pixel[3]
        end
    end

    local file = assert(fs.open(path, "wb"))
    file.write(buffer)
    file.close()
end

local function drawImage()
    if image then
        mainWindow:fill(1, 1, image.sizeX, image.sizeY, colors.white, colors.black, "▒")
        --[[
        for y, tbl in ipairs(image) do
            for x, pixel in ipairs(tbl) do
                drawPixel(x, y, pixel)
            end
        end
        ]]
        local tmp = os.tmpname()
        raw_save(tmp)
        gui_drawimage(screen, tmp, mainWindow:toRealPos(1, 1))
        fs.remove(tmp)
    end
end

local function draw()
    drawUi()
    drawColors()
    drawSelectedColors()
    drawImage()
end
draw()

local function load()
    image = {}

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

    image.sizeX = sizeX
    image.sizeY = sizeY

    local colorByte, countCharBytes, background, foreground, char
    for cy = 1, sizeY do
        image[cy] = {}
        for cx = 1, sizeX do
            colorByte      = string.byte(read(1))
            countCharBytes = string.byte(read(1))

            background = 
            ((readbit(colorByte, 0) and 1 or 0) * 1) + 
            ((readbit(colorByte, 1) and 1 or 0) * 2) + 
            ((readbit(colorByte, 2) and 1 or 0) * 4) + 
            ((readbit(colorByte, 3) and 1 or 0) * 8)
            foreground = 
            ((readbit(colorByte, 4) and 1 or 0) * 1) + 
            ((readbit(colorByte, 5) and 1 or 0) * 2) + 
            ((readbit(colorByte, 6) and 1 or 0) * 4) + 
            ((readbit(colorByte, 7) and 1 or 0) * 8)

            char = read(countCharBytes)

            if background == foreground then --во избежаниия визуальных артефактов отбражения unicode
                char = " "
            end

            image[cy][cx] = {background, foreground, char}
        end
    end
end

local function save()
    noSaved = false
    if not image then return end
    raw_save(filepath)
end

if fs.exists(filepath) then
    load()
    drawImage()
end

local function exitAllow()
    if not noSaved then return true end
    local clear = saveZone(screen)
    local ok = calls.call("gui_yesno", screen, nil, nil, "image do not saved!\nare you sure you want to get out?")
    clear()
    return ok
end

local function resize(newx, newy)
    newx = math.floor(newx + 0.5)
    newy = math.floor(newy + 0.5)
    if newx <= 0 or newy <= 0 then
        local clear = saveZone(screen)
        calls.call("gui_warn", screen, nil, nil, "uncorrent input", colors.white)
        clear()
        return
    end

    if newy > image.sizeY then
        for i = 1, math.abs(image.sizeY - newy) do
            local tbl = {}
            for i = 1, image.sizeX do
                table.insert(tbl, {0, 0, " "})
            end
            table.insert(image, tbl)
        end
    end
    if newx > image.sizeX then
        for i, v in ipairs(image) do
            for i = 1, math.abs(image.sizeX - newx) do
                table.insert(v, {0, 0, " "})
            end
        end
    end
    
    if newy < image.sizeY then
        for i = 1, math.abs(image.sizeY - newy) do
            table.remove(image, #image)
        end
    end
    if newx < image.sizeX then
        for i, v in ipairs(image) do
            for i = 1, math.abs(image.sizeX - newx) do
                table.remove(v, #v)
            end
        end
    end

    image.sizeX = newx
    image.sizeY = newy

    draw()
end

while true do
    local eventData = {computer.pullSignal()}
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    local paletteWindowEventData = paletteWindow:uploadEvent(eventData)
    local nullWindowEventData = nullWindow2:uploadEvent(eventData)
    local mainWindowEventData = mainWindow:uploadEvent(eventData)

    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[3] == 1 and statusWindowEventData[4] == 1 and exitAllow() then
            break
        end
        if statusWindowEventData[3] >= 3 and statusWindowEventData[3] <= 6 then
            local clear = calls.call("screenshot", screen, 4, 2, 20, 4)
            local str, num = calls.call("gui_context", screen, 4, 2, {"  close", true, "  save"},
            {true, false, true})
            clear()
            if num == 1 then
                if exitAllow() then
                    break
                end
            elseif num == 3 then
                save()
            end
        end

        if statusWindowEventData[3] >= 8 and statusWindowEventData[3] <= 11 then
            local gclear = calls.call("screenshot", screen, 4, 2, 20, 4)
            local str, num = gui.context(screen, 4, 2, {"  resize", "  color change", "  bg / fg invert"},
            {true, true, true})
            
            if num == 1 then
                noSaved = true

                gclear()

                local clear = saveZone(screen)
                local str = calls.call("gui_input", screen, nil, nil, "newX newY", nil, colors.white)
                clear()
                if str then
                    local x, y = table.unpack(calls.call("split", str, " "))
                    x = tonumber(x)
                    y = tonumber(y)
                    if x and y then
                        resize(x, y)
                    else
                        local clear = saveZone(screen)
                        calls.call("gui_warn", screen, nil, nil, "incorrent input", colors.white)
                        clear()
                    end
                end
            elseif num == 2 then
                noSaved = true

                local str, num = gui.context(screen, 21, 3, {"  background", "  foreground", "  bg / fg"})

                if num then
                    local from = gui.selectcolor(screen, nil, nil, "choose color to change")
                    if from then
                        local to = gui.selectcolor(screen, nil, nil, "choose new color")
                        if to then
                            for y, tbl in ipairs(image) do
                                for x, pixel in ipairs(tbl) do
                                    if num == 1 or num == 3 then
                                        if pixel[1] == from then
                                            pixel[1] = to
                                        end
                                    end
                                    if num == 2 or num == 3 then
                                        if pixel[2] == from then
                                            pixel[2] = to
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                draw()
            elseif num == 3 then
                for y, tbl in ipairs(image) do
                    for x, pixel in ipairs(tbl) do
                        pixel[1], pixel[2] = pixel[2], pixel[1]
                    end
                end

                draw()
            else
                gclear()
            end
        end
    end

    if paletteWindowEventData[1] == "touch" or paletteWindowEventData[1] == "drag" then
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

    if eventData[1] == "key_down" then
        local ok
        for i, v in ipairs(lastinfo.keyboards[screen]) do
            if v == eventData[2] then
                ok = true
                break
            end
        end
        if ok then
            if eventData[3] == 19 and eventData[4] == 31 then
                save()
            elseif eventData[3] == 23 and eventData[4] == 17 then
                if exitAllow() then
                    break
                end
            end
        end
    end

    if nullWindowEventData[1] == "touch" then
        if nullWindowEventData[3] >= 4 and nullWindowEventData[3] <= 5 and nullWindowEventData[4] == nullWindow2.sizeY - 1 then
            ::tonew::
            local clear = saveZone(screen)
            local entered = calls.call("gui_input", screen, nil, nil, "char", nil, colors.white)
            clear()
            if entered then
                if unicode.len(entered) ~= 1 then
                    local clear = saveZone(screen)
                    calls.call("gui_warn", screen, nil, nil, "enter one char\nor cancel menu", colors.white)
                    clear()
                    goto tonew
                else
                    selectedChar = entered
                    drawSelectedColors()
                end
            end
        end
    end

    if (mainWindowEventData[1] == "touch" or mainWindowEventData[1] == "drag") and image then
        if mainWindowEventData[3] <= image.sizeX and
        mainWindowEventData[4] <= image.sizeY then
            local pixel = image[mainWindowEventData[4]][mainWindowEventData[3]]
            if mainWindowEventData[5] == 0 then
                pixel[1] = selectedColor1 - 1
                pixel[2] = selectedColor2 - 1
                pixel[3] = selectedChar
                if pixel[1] == pixel[2] and pixel[1] == 0 then
                    pixel[2] = 15
                    pixel[3] = " "
                end
            else
                pixel[1] = 0
                pixel[2] = 0
                pixel[3] = " "
            end
            drawPixel(mainWindowEventData[3], mainWindowEventData[4], pixel)
            noSaved = true
        end
    end
end