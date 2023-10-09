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

    window:set(32 - 4, 7, colors.lightBlue, colors.white, " ok ")
    local function drawYes()
        window:set(32 - 4, 7, colors.blue, colors.white, " ok ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    graphic.forceUpdate()
    if registry.soundEnable then
        computer.beep(100)
        computer.beep(100)
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
        window:set(3, 2, color,         colors.gray, unicode.char(0x2800+192) .. "█" .. unicode.char(0x2800+192))
        window:set(3, 3, color,         colors.gray, "█ █")
        window:set(3, 4, colors.yellow, colors.gray, "█ █")
        window:set(3, 5, color,         colors.gray, "███")
    end)

    window:set(32 - 4, 7, colors.lightBlue, colors.white, " ok ")
    local function drawYes()
        window:set(32 - 4, 7, colors.blue, colors.white, " ok ")
        graphic.forceUpdate()
        event.sleep(0.1)
    end

    graphic.forceUpdate()
    if registry.soundEnable then
        computer.beep(300)
        computer.beep(300)
        computer.beep(600)
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

    local sizeX, sizeY = 0, #strs
    for i, v in ipairs(strs) do
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

function gui.context(screen, posX, posY, strs, active)
    local gpu = graphic.findGpu(screen)
    local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)

    local sep = string.rep(gui_container.chars.splitLine, sizeX)

    local window = graphic.createWindow(screen, posX, posY, sizeX, sizeY)
    --window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
    gui.shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)

    local function redrawStrs(selected)
        for i, str in ipairs(strs) do
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

function gui.select(screen, cx, cy, label, actions, scroll, noCloseButton)
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

    local function drawScrollBar()
        window:fill(50, 2, 1, 15, colors.blue, 0, " ")
        window:set(50, math.round(math.map(scroll, 0, #actions - 1, 2, 16)), colors.lime, 0, " ")
    end

    local function drawBase()
        window:clear(colors.gray)
        window:fill(1, 1, window.sizeX, 1, colors.lightGray, 0, " ")
        if label then
            window:set(2, 1, colors.lightGray, colors.white, label)
        end
        if not noCloseButton then
            window:set(window.sizeX, 1, colors.red, colors.white, "X")
        end
    end

    local function draw()
        drawBase()
        
        addrs = {}
        addrsIdx = {}
        for index, action in ipairs(actions) do
            local y = (index + 1) - scroll
            if y >= 2 and y <= window.sizeY then
                window:fill(1, y, window.sizeX, 1, colors.black, colors.white, " ")
                window:set(2, y, colors.black, colors.white, action)

                addrs[y] = action
                addrsIdx[y] = index
            end
        end

        drawScrollBar()
    end

    local function drawUp()
        scroll = scroll - 1
        window:copy(1, 2, window.sizeX - 1, 14, 0, 1)
        
        addrs = {}
        addrsIdx = {}
        for index, action in ipairs(actions) do
            local y = (index + 1) - scroll
            if y >= 2 and y <= window.sizeY then
                if y == 2 then
                    window:fill(1, y, window.sizeX, 1, colors.black, colors.white, " ")
                    window:set(2, y, colors.black, colors.white, action)
                end

                addrs[y] = action
                addrsIdx[y] = index
            end
        end

        drawScrollBar()
    end

    local function drawDown()
        scroll = scroll + 1
        window:copy(1, 3, window.sizeX - 1, 14, 0, -1)
        
        local noDraw
        window:fill(1, window.sizeY, window.sizeX, 1, colors.black, colors.white, " ")
        addrs = {}
        addrsIdx = {}
        for index, action in ipairs(actions) do
            local y = (index + 1) - scroll
            if y >= 2 and y <= window.sizeY then
                if y == window.sizeY then
                    window:set(2, y, colors.black, colors.white, action)
                    noDraw = true
                end

                addrs[y] = action
                addrsIdx[y] = index
            end
        end
        if not noDraw then
            window:fill(1, window.sizeY, window.sizeX - 1, 1, colors.gray, 0, " ")
        end

        drawScrollBar()
    end

    draw()

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)

        if windowEventData[1] == "touch" then
            if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
                if not noCloseButton then
                    return nil, scroll
                end
            elseif addrsIdx[windowEventData[4]] and windowEventData[3] < window.sizeX then
                return addrsIdx[windowEventData[4]], scroll, windowEventData[5]
            end
        elseif windowEventData[1] == "scroll" then
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

    if not cx or not cy then
        cx, cy = graphic.getResolution(screen)
        cx = cx / 2
        cy = cy / 2
        cx = cx - 25
        cy = cy - 8
        cx = math.floor(cx + 0.5)
        cy = math.floor(cy + 0.5)
    end

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
                    table.insert(strs, ctype .. string.rep(" ", 38 - unicode.wlen(ctype) - unicode.wlen(clabel)) .. clabel .. string.rep(" ", (1 - unicode.wlen(clabel)) + unicode.wlen(clabel)) .. addr:sub(1, 8))
                end
            end

            if allowAutoConfirm and #addresses == 1 then
                out = addresses[1]
                th:kill()
                return
            end

            local idx, lscroll, button = gui.select(screen, cx, cy, typesstr, strs, scroll, control)
            scroll = lscroll

            if idx then
                local addr = addresses[idx]
                if button == 0 and not control then
                    out = addr
                    th:kill()
                    return
                else
                    local str = gui.input(screen, (cx + 25) - 16, cy + 4, "new name", nil, nil, advLabeling.getLabel(addr))
                    if type(str) == "string" then
                        advLabeling.setLabel(addr, str)
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

calls.loaded.gui_warn = gui.warn
calls.loaded.gui_drawtext = gui.drawtext
calls.loaded.gui_context = gui.context
calls.loaded.gui_input = gui.input
calls.loaded.gui_select = gui.select
calls.loaded.gui_selectcomponent = gui.selectcomponent
calls.loaded.gui_checkPassword = gui.checkPassword
calls.loaded.gui_status = gui.status
return gui