local gui_container = require("gui_container")
local registry = require("registry")
local colorslib = require("colors")
local colors = gui_container.colors
local calls = require("calls")
local graphic = require("graphic")
local event = require("event")
local computer = require("computer")
local unicode = require("unicode")
local component = require("component")
local thread = require("thread")
local paths = require("paths")
local system = require("system")
local sound = require("sound")
local fs = require("filesystem")
local programs = require("programs")
local clipboard = require("clipboard")
local gui = {}

local smartShadowsColors = {
    colorslib.lightGray, --1)  white
    colorslib.brown,     --2)  orange
    colorslib.purple,    --3)  magenta
    colorslib.cyan,      --4)  lightBlue
    colorslib.orange,    --5)  yellow
    colorslib.green,     --6)  lime
    colorslib.magenta,   --7)  pink
    colorslib.black,     --8)  gray
    colorslib.gray,      --9)  lightGray
    colorslib.blue,      --10) cyan
    colorslib.brown,     --11) purple
    colorslib.brown,     --12) blue
    colorslib.black,     --13) brown
    colorslib.brown,     --14) green
    colorslib.brown,     --15) red
    colorslib.gray       --16) black
}

------------------------------------

function gui.hideExtension(screen, path)
    local name = paths.name(path)
    if gui_container.viewFileExps[screen] then
        return name
    else
        return paths.hideExtension(name)
    end
end

------------------------------------

function gui.shadow(gpu, x, y, sx, sy, mul, full)
    local screen = gpu.getScreen()
    local depth = gpu.getDepth()

    local function getPoses()
        local shadowPosesX = {}
        local shadowPosesY = {}

        if full then
            for cx = x, x + (sx - 1) do
                for cy = y, y + (sy - 1) do
                    table.insert(shadowPosesX, cx)
                    table.insert(shadowPosesY, cy)
                end
            end
        else
            for i = x + 1, (x + sx) - 1 do
                table.insert(shadowPosesX, i)
                table.insert(shadowPosesY, y + sy)
            end
            for i = y + 1, y + sy do
                table.insert(shadowPosesX, x + sx)
                if registry.shadowMode == "full" then
                    table.insert(shadowPosesX, x + sx + 1)
                    table.insert(shadowPosesY, i)
                end
                table.insert(shadowPosesY, i)
            end
        end

        return shadowPosesX, shadowPosesY
    end

    local origs = {}
    if registry.shadowType == "advanced" then
        local shadowPosesX, shadowPosesY = getPoses()

        for i = 1, #shadowPosesX do
            local ok, char, fore, back = pcall(gpu.get, shadowPosesX[i], shadowPosesY[i])
            if ok and char and fore and back then
                table.insert(origs, {shadowPosesX[i], shadowPosesY[i], char, fore, back})

                gpu.setForeground(colorslib.colorMul(fore, mul or 0.6))
                gpu.setBackground(colorslib.colorMul(back, mul or 0.6))
                gpu.set(shadowPosesX[i], shadowPosesY[i], char)
            end
        end
    elseif registry.shadowType == "smart" then
        local shadowPosesX, shadowPosesY = getPoses()

        local palcache = {}
        local function getPalCol(source)
            if depth > 1 then
                for i = 0, 15 do
                    local col = palcache[i]
                    if not col then
                        col = gpu.getPaletteColor(i)
                        palcache[i] = col
                    end
                    if col == source then
                        return i
                    end
                end
            end
            return 0
        end

        for i = 1, #shadowPosesX do
            local ok, char, fore, back, forePal, backPal = pcall(gpu.get, shadowPosesX[i], shadowPosesY[i])
            if ok and char and fore and back then
                table.insert(origs, {shadowPosesX[i], shadowPosesY[i], char, fore, back})

                if not forePal then forePal = getPalCol(fore) end
                gpu.setForeground(smartShadowsColors[forePal + 1], depth > 1)
                if not backPal then backPal = getPalCol(back) end
                gpu.setBackground(smartShadowsColors[backPal + 1], depth > 1)
                
                gpu.set(shadowPosesX[i], shadowPosesY[i], char)
            end
        end
    elseif registry.shadowType == "simple" then
        local shadowPosesX, shadowPosesY = getPoses()
        for i = 1, #shadowPosesX do
            local ok, char, fore, back, forePal, backPal = pcall(gpu.get, shadowPosesX[i], shadowPosesY[i])
            if ok and char and fore and back then
                table.insert(origs, {shadowPosesX[i], shadowPosesY[i], char, fore, back})
            end
        end

        gpu.setBackground(colors.gray)
        if full then
            gpu.fill(x, y, sx, sy, " ")
        else
            gpu.fill(x + 1, y + 1, (sx + 1) + (registry.shadowMode == "compact" and -1 or 0), sy, " ")
        end
    end

    return function ()
        if gpu.getScreen() ~= screen then
            gpu.bind(screen, false)
        end
        for _, obj in ipairs(origs) do
            gpu.setForeground(obj[4])
            gpu.setBackground(obj[5])
            gpu.set(obj[1], obj[2], obj[3])
        end
    end
end

function gui.pleaseType(screen, str, tostr)
    tostr = tostr or "confirm"
    while true do
        local input = gui.input(screen, nil, nil, "TYPE '" .. str .. "' TO " .. tostr:upper())
        if input then
            if input == str then
                return true
            else
                gui.warn(screen, nil, nil, "to " .. tostr .. ", you need to type '" .. str .. "'")
            end
        else
            return false
        end
    end
end

function gui.smallWindow(screen, cx, cy, str, backgroundColor, icon)
    --◢▲◣▲▴▴
    local gpu = graphic.findGpu(screen)

    if not cx or not cy then
        cx, cy = gpu.getResolution()
        cx = cx / 2
        cy = cy / 2
        cx = cx - 16
        cy = cy - 4
        cx = math.floor(cx) + 1
        cy = math.floor(cy) + 1
    end

    local window = graphic.createWindow(screen, cx, cy, 32, 8, true)

    local color = backgroundColor or colors.lightGray

    --window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
    local noShadow = gui.shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)
    window:clear(color)

    local textColor = colors.white
    if color == textColor then
        textColor = colors.black
    end
    for i, v in ipairs(restrs(str, 24)) do
        window:set(8, i + 1, color, textColor, v)
    end

    if icon then
        icon(window, color)
    end

    return window, noShadow
end

function gui.status(screen, cx, cy, str, backgroundColor)
    gui.smallWindow(screen, cx, cy, str, backgroundColor or colors.lightGray, function (window, color)
        window:set(2, 2, color, colors.blue, "  " .. unicode.char(0x2800+192) ..  "  ")
        window:set(2, 3, color, colors.blue, " ◢█◣ ")
        window:set(2, 4, color, colors.blue, "◢███◣")
        window:set(4, 3, colors.blue, colors.white, "P")
    end)
    graphic.forceUpdate()
    event.yield()
end

function gui.warn(screen, cx, cy, str, backgroundColor)
    local window, noShadow = gui.smallWindow(screen, cx, cy, str, backgroundColor, function (window, color)
        window:set(2, 2, color, colors.yellow, "  " .. unicode.char(0x2800+192) ..  "  ")
        window:set(2, 3, color, colors.yellow, " ◢█◣ ")
        window:set(2, 4, color, colors.yellow, "◢███◣")
        window:set(4, 3, colors.yellow, colors.white, "!")
    end)

    window:set(32 - 4, 7, colors.lightBlue, colors.white, " OK ")
    local function drawYes()
        window:set(32 - 4, 7, colors.blue, colors.white, " OK ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    graphic.forceUpdate()
    if registry.soundEnable then
        sound.warn()
    end

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[1] == "touch" and windowEventData[5] == 0 then
            if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
                drawYes()
                break
            end
        elseif windowEventData[1] == "key_down" and windowEventData[4] == 28 then
            drawYes()
            break
        end
    end
    noShadow()
end

function gui.pleaseCharge(screen, minCharge, str)
    minCharge = minCharge or 40
    str = str or "this action"

    if system.getCharge() >= minCharge then return true end

    local clear = saveZone(screen)

    local window = gui.smallWindow(screen, nil, nil, "in order to make " .. str .. ",\nthe charge level of the device must be at least " .. tostring(math.floor(minCharge)) .. "%", nil, function (window, color)
        window:set(2, 2, color, colors.red, "  " .. unicode.char(0x2800+192) ..  "  ")
        window:set(2, 3, color, colors.red, " ◢█◣ ")
        window:set(2, 4, color, colors.red, "◢███◣")
        window:set(4, 3, colors.red, colors.white, "!")
    end)

    window:set(32 - 4, 7, colors.lightBlue, colors.white, " OK ")
    local function drawYes()
        window:set(32 - 4, 7, colors.blue, colors.white, " OK ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    graphic.forceUpdate()
    if registry.soundEnable then
        sound.warn()
    end

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[1] == "touch" and windowEventData[5] == 0 then
            if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
                drawYes()
                clear()
                return false
            end
        elseif windowEventData[1] == "key_down" and windowEventData[4] == 28 then
            drawYes()
            clear()
            return false
        end
    end
end

function gui.pleaseSpace(screen, minSpace, str)
    minSpace = minSpace or 64
    str = str or "this action"

    local root = fs.get("/")
    if (root.spaceTotal() - root.spaceUsed()) >= minSpace then return true end

    local clear = saveZone(screen)

    local window = gui.smallWindow(screen, nil, nil, "in order to make " .. str .. ",\nyou need a minimum " .. tostring(math.floor(minSpace)) .. "KB space", nil, function (window, color)
        window:set(2, 2, color, colors.red, "  " .. unicode.char(0x2800+192) ..  "  ")
        window:set(2, 3, color, colors.red, " ◢█◣ ")
        window:set(2, 4, color, colors.red, "◢███◣")
        window:set(4, 3, colors.red, colors.white, "!")
    end)

    window:set(32 - 4, 7, colors.lightBlue, colors.white, " OK ")
    local function drawYes()
        window:set(32 - 4, 7, colors.blue, colors.white, " OK ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    graphic.forceUpdate()
    if registry.soundEnable then
        sound.warn()
    end

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[1] == "touch" and windowEventData[5] == 0 then
            if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
                drawYes()
                clear()
                return false
            end
        elseif windowEventData[1] == "key_down" and windowEventData[4] == 28 then
            drawYes()
            clear()
            return false
        end
    end
end

function gui.selectcolor(screen, cx, cy, str)
    --◢▲◣▲▴▴
    local gpu = graphic.findGpu(screen)

    if not cx or not cy then
        cx, cy = gpu.getResolution()
        cx = cx / 2
        cy = cy / 2
        cx = cx - 12
        cy = cy - 6
        cx = math.floor(cx) + 1
        cy = math.floor(cy) + 1
    end

    local window = graphic.createWindow(screen, cx, cy, 24, 12, true)
    local noShadow = gui.shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)
    window:clear(colors.gray)
    window:fill(3, 2, 20, 10, colors.brown, colors.white, "▒")
    window:set(2, 1, colors.gray, colors.white, str or "select color")
    window:set(window.sizeX, 1, colors.red, colors.white, "X")

    local cols = {}
    for i = 1, 12 do
        cols[i] = {}
    end
    for x = 0, 3 do
        for y = 0, 3 do
            local colNum = x + (y * 4)
            local col = colors[colorslib[colNum]]
            local setX, setY = 5 + (x * 4), 3 + (y * 2)
            window:set(setX, setY, col, 0, "    ")
            window:set(setX, setY + 1, col, 0, "    ")
            for addY = 0, 1 do
                for addX = 0, 3 do
                    cols[setY + addY][setX + addX] = colNum
                end
            end
        end
    end
    graphic.forceUpdate()

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[1] == "touch" then
            if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
                noShadow()
                return
            elseif cols[windowEventData[4]] and cols[windowEventData[4]][windowEventData[3]] then
                noShadow()
                return cols[windowEventData[4]][windowEventData[3]]
            end
        end
    end
end

function gui.selectfullcolor(screen, cx, cy, str)
    local col = gui.selectcolor(screen, cx, cy, str)
    if col and colorslib[col] and colors[colorslib[col]] then
        return colors[colorslib[col]]
    end
end

function gui.input(screen, cx, cy, str, hidden, backgroundColor, default, disableStartSound)
    local gpu = graphic.findGpu(screen)

    if not cx or not cy then
        cx, cy = gpu.getResolution()
        cx = cx / 2
        cy = cy / 2
        cx = cx - 16
        cy = cy - 4
        cx = math.floor(cx) + 1
        cy = math.floor(cy) + 1
    end

    local window = graphic.createWindow(screen, cx, cy, 32, 8, true)

    --window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
    local noShadow = gui.shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)
    window:clear(backgroundColor or colors.lightGray)

    local pos = math.round((window.sizeX / 2) - (unicode.wlen(str) / 2)) + 1
    window:fill(1, 1, window.sizeX, 1, colors.gray, 0, " ")
    window:set(pos, 1, colors.gray, colors.white, str)

    window:set(32 - 4 - 3, 7, colors.lightBlue, colors.white, " enter ")
    window:set(2, 7, colors.red, colors.white, " cancel ")

    local reader = window:read(2, 3, window.sizeX - 2, colors.gray, colors.white, nil, hidden, default)

    graphic.forceUpdate()
    if registry.soundEnable and not disableStartSound then
        computer.beep(2000)
        computer.beep(1500)
    end

    local function drawOk()
        window:set(32 - 4 - 3, 7, colors.blue, colors.white, " enter ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    local function drawCancel()
        window:set(2, 7, colors.orange, colors.white, " cancel ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    while true do
        local eventData = {event.pull()}
        local windowEventData = window:uploadEvent(eventData)
        local out = reader.uploadEvent(eventData)
        if out then
            if out == true then
                drawCancel()
                noShadow()
                return false
            end
            drawOk()
            noShadow()
            return out
        end
        if windowEventData[1] == "touch" and windowEventData[5] == 0 then
            if windowEventData[4] == 7 and windowEventData[3] > (32 - 5 - 3) and windowEventData[3] <= ((32 - 5) + 4) then
                drawOk()
                noShadow()
                return reader.getBuffer()
            elseif windowEventData[4] == 7 and windowEventData[3] >= 2 and windowEventData[3] <= (2 + 7) then
                drawCancel()
                noShadow()
                return false
            end
        end
    end
end

function gui.contentPos(screen, posX, posY, strs)
    local gpu = graphic.findGpu(screen)
    local rx, ry = gpu.getResolution()
    local drawStrs = gui.contextStrs(strs)

    local sizeX, sizeY = 0, #drawStrs
    for i, v in ipairs(drawStrs) do
        if type(v) == "string" and unicode.wlen(v) > sizeX then
            sizeX = unicode.wlen(v)
        end
    end
    sizeX = sizeX + 1
    while posX + (sizeX - 1) > rx do
        posX = posX - 1
    end
    while posY + (sizeY - 1) > ry do
        posY = posY - 1
    end

    return posX, posY, sizeX, sizeY
end

function gui.contextStrs(strs)
    local drawStrs = {}
    for index, value in ipairs(strs) do
        if type(value) == "string" then
            if value:sub(1, 2) ~= "  " then
                drawStrs[index] = "  " .. value
            else
                drawStrs[index] = value
            end
        else
            drawStrs[index] = value
        end
    end
    return drawStrs
end

function gui.context(screen, posX, posY, strs, active)
    local gpu = graphic.findGpu(screen)
    local drawStrs = gui.contextStrs(strs)
    local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, drawStrs)
    local sep = string.rep(gui_container.chars.splitLine, sizeX)

    local window = graphic.createWindow(screen, posX, posY, sizeX, sizeY)
    --window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
    gui.shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)

    local function redrawStrs(selected)
        for i, str in ipairs(drawStrs) do
            local isSep
            if str == true then
                isSep = true
                str = sep
            end

            local color = colors.white
            local color2 = colors.black
            if (not active or active[i]) and not isSep then
                if selected == i then
                    color = colors.blue
                    color2 = colors.white
                end
                window:set(1, i, color, color2, str .. (string.rep(" ", sizeX - unicode.wlen(str))))
            else
                window:set(1, i, color, colors.lightGray, str .. (string.rep(" ", sizeX - unicode.wlen(str))))
            end
        end
        graphic.forceUpdate()
    end
    redrawStrs()

    local selectedNum
    while true do
        local eventData = {computer.pullSignal()}
        if eventData[2] == screen then
            local windowEventData = window:uploadEvent(eventData)
            if windowEventData[1] == "drop" and windowEventData[5] == 0 then
                local num = windowEventData[4]
                if not active or active[num] then
                    event.sleep(0.05)
                    return strs[num], num
                end
            elseif (windowEventData[1] == "touch" or windowEventData[1] == "drag") and windowEventData[5] == 0 then
                if windowEventData[1] == "touch" and selectedNum and selectedNum == windowEventData[4] then
                    if not active or active[selectedNum] then
                        event.sleep(0.05)
                        return strs[selectedNum], selectedNum
                    end
                end
                redrawStrs(windowEventData[4])
                selectedNum = windowEventData[4]
            elseif eventData[1] == "drag" then
                selectedNum = nil
                redrawStrs()
            elseif eventData[1] == "touch" or eventData[1] == "scroll" then
                event.push(table.unpack(eventData))
                return nil, nil
            end
        end
    end
end

function gui.contextAuto(screen, posX, posY, strs, active)
    local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
    local clear = graphic.screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
    local result = {gui.context(screen, posX, posY, strs, active)}
    clear()
    return table.unpack(result)
end

function gui.drawtext(screen, posX, posY, foreground, text)
    local gpu = graphic.findGpu(screen)

    ------------------------------------

    gpu.setForeground(foreground)

    local buff = ""
    local oldBack, oldI
    for i = 1, unicode.wlen(text) do
        local ok, char, fore, back = pcall(gpu.get, posX + (i - 1), posY)
        if ok then
            oldI = oldI or i
            oldBack = oldBack or back
            if back ~= oldBack then
                gpu.setBackground(oldBack)
                gpu.set(posX + (oldI - 1), posY, buff)

                buff = ""
                oldBack = back
                oldI = i
            end
            buff = buff .. unicode.sub(text, i, i)
        end
    end

    if oldBack then
        gpu.setBackground(oldBack)
        gpu.set(posX + (oldI - 1), posY, buff)
    end
end

function gui.select(screen, cx, cy, label, actions, scroll)
    --=gui_select(screen, nil, nil, "LOLZ", {"test 1", "test 2", "test 3"})

    local gpu = graphic.findGpu(screen)
    if not cx or not cy then
        cx, cy = gpu.getResolution()
        cx = cx / 2
        cy = cy / 2
        cx = cx - 25
        cy = cy - 8
        cx = math.round(cx) + 1
        cy = math.round(cy) + 1
    end

    local window = graphic.createWindow(screen, cx, cy, 50, 16, true)

    --------------------------------------------

    scroll = scroll or 0
    local addrs
    local addrsIdx
    local sel

    local function drawScrollBar()
        window:fill(50, 2, 1, 14, colors.purple, 0, " ")
        window:set(50, math.round(math.map(scroll, 0, #actions - 1, 2, 15)), colors.pink, 0, " ")
    end

    local function redrawButton()
        window:set(window.sizeX - 9, window.sizeY, sel and colors.lime or colors.green, colors.white, " CONFIRM ")
    end

    local function drawBase()
        --window:clear(colors.brown)
        window:fill(1, 1, window.sizeX, 1, colors.lightGray, 0, " ")
        if label then
            window:set(2, 1, colors.lightGray, colors.white, label)
        end
        window:set(window.sizeX, 1, colors.red, colors.white, "X")
        window:fill(1, window.sizeY, window.sizeX, 1, colors.lightGray, 0, " ")
        redrawButton()
    end

    local function getCol(idx)
        return sel == idx and colors.blue or colors.gray
    end

    local function draw(pos)
        if not pos then
            drawBase()
        end
        
        addrs = {}
        addrsIdx = {}
        local lastLine = 1
        for index, action in ipairs(actions) do
            local y = (index + 1) - scroll
            if y >= 2 and y < window.sizeY then
                if not pos or pos == index then
                    window:fill(1, y, window.sizeX - 1, 1, getCol(index), colors.white, " ")
                    window:set(2, y, getCol(index), colors.white, action)
                    lastLine = y
                end

                addrs[y] = action
                addrsIdx[y] = index
            end
        end
        if not pos then
            lastLine = lastLine + 1
            window:fill(1, lastLine, window.sizeX - 1, window.sizeY - lastLine, colors.brown, 0, " ")
        end

        if not pos then
            drawScrollBar()
        end
    end

    local function drawUp()
        scroll = scroll - 1
        window:copy(1, 2, window.sizeX - 1, 13, 0, 1)
        
        addrs = {}
        addrsIdx = {}
        for index, action in ipairs(actions) do
            local y = (index + 1) - scroll
            if y >= 2 and y < window.sizeY then
                if y == 2 then
                    window:fill(1, y, window.sizeX - 1, 1, getCol(index), colors.white, " ")
                    window:set(2, y, getCol(index), colors.white, action)
                end

                addrs[y] = action
                addrsIdx[y] = index
            end
        end

        drawScrollBar()
    end

    local function drawDown()
        scroll = scroll + 1
        window:copy(1, 3, window.sizeX - 1, 13, 0, -1)
        
        local noDraw
        addrs = {}
        addrsIdx = {}
        for index, action in ipairs(actions) do
            local y = (index + 1) - scroll
            if y >= 2 and y < window.sizeY then
                if y == window.sizeY - 1 then
                    window:fill(1, y, window.sizeX, 1, getCol(index), 0, " ")
                    window:set(2, y, getCol(index), colors.white, action)
                    noDraw = true
                end

                addrs[y] = action
                addrsIdx[y] = index
            end
        end
        if not noDraw then
            window:fill(1, window.sizeY - 1, window.sizeX - 1, 1, colors.brown, 0, " ")
        end

        drawScrollBar()
    end

    draw()

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)

        if windowEventData[1] == "touch" then
            if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
                return nil, scroll, windowEventData[5], windowEventData
            elseif windowEventData[3] >= window.sizeX - 9 and windowEventData[3] < window.sizeX and windowEventData[4] == window.sizeY then
                if sel then
                    return sel, scroll, windowEventData[5], windowEventData
                end
            end
        end

        if windowEventData[1] == "touch" or windowEventData[1] == "drag" then
            if addrsIdx[windowEventData[4]] and windowEventData[3] < window.sizeX and windowEventData[4] < window.sizeY then
                if windowEventData[5] == 1 and (not sel or sel ~= addrsIdx[windowEventData[4]]) then
                    local oldsel = sel
                    sel = addrsIdx[windowEventData[4]]
                    if sel ~= oldsel then
                        if oldsel then
                            draw(oldsel)
                        end
                        if sel then
                            draw(sel)
                        end
                        redrawButton()
                    end
                end
                if windowEventData[1] == "touch" and sel and sel == addrsIdx[windowEventData[4]] then
                    draw(sel)
                    redrawButton()
                    return sel, scroll, windowEventData[5], windowEventData
                end
                local oldsel = sel
                sel = addrsIdx[windowEventData[4]]
                if sel ~= oldsel then
                    if oldsel then
                        draw(oldsel)
                    end
                    if sel then
                        draw(sel)
                    end
                    redrawButton()
                end
            elseif sel then
                local lsel = sel
                sel = nil
                draw(lsel)
                redrawButton()
            end
        end

        if windowEventData[1] == "scroll" then
            if windowEventData[5] > 0 then
                if scroll > 0 then
                    drawUp()
                end
            else
                if scroll < #actions - 1 then
                    drawDown()
                end
            end
        end
    end
end

function gui.selectcomponent(screen, cx, cy, types, allowAutoConfirm, control) --=gui_selectcomponent(screen, nil, nil, {"computer"}, true)
    local advLabeling = require("advLabeling")

    if types and type(types) ~= "table" then
        types = {types}
    end

    if not cx or not cy then
        cx, cy = graphic.getResolution(screen)
        cx = cx / 2
        cy = cy / 2
        cx = cx - 25
        cy = cy - 8
        cx = math.round(cx) + 1
        cy = math.round(cy) + 1
    end
    local checkWindow = graphic.createWindow(screen, cx, cy, 50, 16)

    local function allTypes()
        types = {}
        local added = {}
        for addr, ctype in component.list() do
            if not added[ctype] then
                table.insert(types, ctype)
                added[ctype] = true
            end
        end
        table.sort(types)
    end

    local allTypesFlag
    local typesstr = "select "
    if types then
        typesstr = typesstr .. table.concat(types, "/")
    else
        typesstr = typesstr .. "component"
        allTypesFlag = true
    end
    if control then
        typesstr = "components"
    end

    local cancel, out

    local th
    th = thread.create(function ()
        if allTypesFlag then
            allTypes()
        end

        local scroll

        while true do
            local strs = {}
            local addresses = {}

            for _, ctype in ipairs(types) do
                local addrs = {}
                for addr in component.list(ctype, true) do
                    table.insert(addrs, addr)
                end
                table.sort(addrs)
                for _, addr in ipairs(addrs) do
                    table.insert(addresses, addr)

                    local ctype = component.type(addr)
                    local clabel = advLabeling.getLabel(addr) or ""
                    if fs.bootaddress == addr then
                        clabel = clabel .. " (system)"
                    end
                    clabel = gui_container.short(clabel, 20)

                    table.insert(strs, ctype .. string.rep(" ", 38 - unicode.wlen(ctype) - unicode.wlen(clabel)) .. clabel .. string.rep(" ", (1 - unicode.wlen(clabel)) + unicode.wlen(clabel)) .. addr:sub(1, 8))
                end
            end

            if allowAutoConfirm and #addresses == 1 then
                out = addresses[1]
                th:kill()
                return
            end

            local idx, lscroll, button, eventData = gui.select(screen, cx, cy, typesstr, strs, scroll, control)
            scroll = lscroll

            if idx then
                local addr = addresses[idx]
                if button == 0 and not control then
                    out = addr
                    th:kill()
                    return
                else
                    local strs = {
                        "copy name",
                        "copy address",
                        "set label",
                        "clear label",
                        "view api"
                    }
                    local px, py = checkWindow:toRealPos(eventData[3], eventData[4])
                    local x, y, sx, sy = gui.contentPos(screen, px, py, strs)
                    local clear = graphic.screenshot(screen, x, y, sx + 2, sy + 1)
                    local _, action = gui.context(screen, x, y, strs)
                    clear()
                    if action == 1 then 
                        clipboard.set(eventData[6], component.type(addr))
                    elseif action == 2 then
                        clipboard.set(eventData[6], addr)
                    elseif action == 3 then
                        local str = gui.input(screen, (cx + 25) - 16, cy + 4, "new name", nil, nil, advLabeling.getLabel(addr))
                        if type(str) == "string" then
                            advLabeling.setLabel(addr, str)
                        end
                    elseif action == 4 then
                        if gui.yesno(screen, (cx + 25) - 16, cy + 4, "clear label on \"" .. (advLabeling.getLabel(addr) or component.type(addr)) .. "\"?") then
                            advLabeling.setLabel(addr, nil)
                        end
                    elseif action == 5 then
                        local format = require("format")

                        local tempfile = paths.concat("/tmp", component.type(addr) .. "_" .. math.round(math.random(0, 9999)) .. ".txt")
                        local file = fs.open(tempfile, "wb")
                        local methods = component.methods(addr)
                        local maxMethodLen = 0
                        for name in pairs(methods) do
                            if unicode.len(name) > maxMethodLen then
                                maxMethodLen = unicode.len(name)
                            end
                        end
                        for name, direct in pairs(methods) do
                            local smart = format.smartConcat()
                            smart.add(1, name)
                            smart.add(maxMethodLen + 1, " - " .. (component.doc(addr, name) or "Undocumented") .. "\n")
                            file.write(smart.get())
                        end
                        file.close()

                        local clear = graphic.screenshot(screen)
                        programs.execute("edit", screen, nil, tempfile, true)
                        clear()
                        fs.remove(tempfile)
                    end
                end
            else
                cancel = true
                th:kill()
                return
            end
        end
    end)
    th:resume()
    
    while true do
        local eventData = {computer.pullSignal(0.1)}

        if cancel or out then
            return out
        end

        if eventData[1] == "component_added" or eventData[1] == "component_removed" then
            th:kill()
            th = thread.create(th.func)
            th:resume()
        end
    end
end

function gui.checkPassword(screen, cx, cy, disableStartSound, diskAddress)
    local regData = require("liked").getRegistry(diskAddress)
    if regData then
        if regData.password then
            local clear = saveZone(screen)
            local password = gui.input(screen, cx, cy, "enter password", true, nil, nil, disableStartSound)
            clear()

            if password then
                if require("sha256").sha256(password .. (regData.passwordSalt or "")) == regData.password then
                    return true
                else
                    local clear = saveZone(screen)
                    gui.warn(screen, cx, cy, "invalid password")
                    clear()
                end
            else
                return false --false означает что пользователь отказался от ввода пароля
            end
        else
            return true
        end
    else
        return true
    end
end

function gui.checkPasswordLoop(...)
    while true do
        local ret = gui.checkPassword(...)
        if ret ~= nil then
            return ret
        end
    end
end

function gui.yesno(screen, cx, cy, str, backgroundColor)
    local window, noShadow = gui.smallWindow(screen, cx, cy, str, backgroundColor, function (window, color)
        window:set(2, 2, color, colors.green, "  " .. unicode.char(0x2800+192) ..  "  ")
        window:set(2, 3, color, colors.green, " ◢█◣ ")
        window:set(2, 4, color, colors.green, "◢███◣")
        window:set(4, 3, colors.green, colors.white, "?")
    end)

    window:set(32 - 5, 7, colors.lime, colors.white, " yes ")
    window:set(2, 7, colors.red, colors.white, " no ")

    graphic.forceUpdate()
    if registry.soundEnable then
        computer.beep(2000)
    end

    local function drawYes()
        window:set(32 - 5, 7, colors.green, colors.white, " yes ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[1] == "touch" and windowEventData[5] == 0 then
            if windowEventData[4] == 7 and windowEventData[3] > (32 - 6) and windowEventData[3] <= ((32 - 5) + 4) then
                drawYes()
                noShadow()
                return true
            elseif windowEventData[4] == 7 and windowEventData[3] >= 2 and windowEventData[3] <= (2 + 3) then
                window:set(2, 7, colors.orange, colors.white, " no ")
                graphic.forceUpdate()
                event.sleep(0.1)
                noShadow()
                return false
            end
        elseif windowEventData[1] == "key_down" and windowEventData[4] == 28 then
            drawYes()
            noShadow()
            return true
        end
    end
end

calls.loaded.gui_yesno = gui.yesno
calls.loaded.gui_warn = gui.warn
calls.loaded.gui_drawtext = gui.drawtext
calls.loaded.gui_context = gui.context
calls.loaded.gui_input = gui.input
calls.loaded.gui_select = gui.select
calls.loaded.gui_selectcomponent = gui.selectcomponent
calls.loaded.gui_checkPassword = gui.checkPassword
calls.loaded.gui_status = gui.status
return gui