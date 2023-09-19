local screen, _, path = ...

local graphic = require("graphic")
local colors = require("colors")
local fs = require("filesystem")
local computer = require("computer")
local component = require("component")
local paths = require("paths")
local advLabeling = require("advLabeling")
local gui_container = require("gui_container")

gui_container.noScreenSaver[screen] = true

graphic.setResolution(screen, 80, 25)
local rx, ry = graphic.getResolution(screen)
local photoResolution = ry * 2
local photoFov = 90
local photoDist = 60
local photo

local window = graphic.createWindow(screen, 1, 1, 160, 50, nil, true)

local function setSmall()
    rx, ry = 80, 25
    graphic.setResolution(screen, rx, ry)

    photoResolution = ry * 2
    photo = nil
    redrawAll()

    return true
end

local function setBig()
    local mx = graphic.maxResolution(screen)
    if mx >= 160 then
        rx, ry = 160, 50
        graphic.setResolution(screen, rx, ry)

        photoResolution = ry * 2
        photo = nil
        redrawAll()

        return true
    else
        warn("not supported on your device")
    end
end

local function palette_bw()
    for i = 0, 15 do
        local grayCol = (i / 15) * 255
        graphic.setPaletteColor(screen, i, colors.blend(grayCol, grayCol, grayCol))
    end
end

local function palette_color() --сначала нужно вызвать palette_bw, для заполнения индексов 0 и 15
    for i = 1, 14 do
        local grayCol = (i / 15) * 200
        graphic.setPaletteColor(screen, i, colors.blend(grayCol, 0, 255 - grayCol))
    end
end

palette_bw()
--palette_color()

local camera = component.proxy(component.list("camera")() or "")

function warn(str)
    local clear = saveZone(screen)
    gui_warn(screen, nil, nil, str or "unknown error")
    clear()
end

local function makePhoto()
    if camera then
        local clear = saveZone(screen)
        gui_status(screen, nil, nil, "generating a photo...")
        
        photo = {}
        local max = photoResolution - 1
        for cx = 0, max do
            photo[cx + 1] = {}
            for cy = 0, max do
                local offsetX = -math.rad(((cx / max) - 0.5) * photoFov)
                local offsetY = -math.rad(((cy / max) - 0.5) * photoFov)
                local distance = camera.distance(offsetX, offsetY)
                local col = 0
                if distance > 0 then
                    col = math.floor(math.map(distance, 0, photoDist, 15, 0) + 0.5)
                    if col < 0 then col = 0 end
                    if col > 15 then col = 15 end
                end
                photo[cx + 1][cy + 1] = col
            end
        end

        clear()
    else
        warn("first select the camera")
    end
end

local function savePhoto()
    if not photo then
        warn("to save, you first need to take a picture")
        return
    end
    
    local clear = saveBigZone(screen)
    local path = gui_filepicker(screen, nil, nil, "/data/userdata/photos", "cam", true)
    clear()
    
    if not path then return end

    fs.makeDirectory(paths.path(path))

    local file, err = fs.open(path, "wb")
    if not file then
        warn(err)
        return
    end

    file.write("CAM_____")
    file.write(string.char(photoResolution))

    local currentByte = 0
    local buff = {}
    for posX, line in ipairs(photo) do
        for posY, col in ipairs(line) do
            if posY % 2 == 0 then
                for i = 0, 3 do
                    currentByte = bit32.writebit(currentByte, i + 4, bit32.readbit(col, i))
                end

                table.insert(buff, string.char(currentByte))
                currentByte = 0
            else
                for i = 0, 3 do
                    currentByte = bit32.writebit(currentByte, i, bit32.readbit(col, i))
                end
            end
        end
    end

    local ok, err = file.write(table.concat(buff))
    file.close()

    if not ok then
        warn(err)
    end
end

local function drawPhoto()
    local gpu = graphic.findGpu(screen)

    if photo then
        for posX, line in ipairs(photo) do
            local oldBack, oldFore, oldX, oldY
            local currentBack, currentFore

            for posY, col in ipairs(line) do
                if posY % 2 == 0 then
                    currentFore = col

                    oldBack = oldBack or currentBack
                    oldFore = oldFore or currentFore
                    oldX = oldX or posX
                    oldY = oldY or posY
                    if currentBack ~= oldBack or currentFore ~= oldFore or oldX ~= posX then
                        gpu.setBackground(oldBack, true)
                        gpu.setForeground(oldFore, true)
                        gpu.fill(oldX, oldY // 2, 1, ((posY  // 2) - (oldY // 2)) + 1, "▄")

                        oldBack = currentBack
                        oldFore = currentFore
                        oldX = posX
                        oldY = posY
                    end
                else
                    currentBack = col
                end
            end

            gpu.setBackground(oldBack, true)
            gpu.setForeground(oldFore, true)
            gpu.fill(oldX, oldY // 2, 1, ((#line  // 2) - (oldY // 2)) + 1, "▄")
        end
    else
        gpu.setBackground(7, true)
        gpu.setForeground(0 , true)
        gpu.fill(1, 1, photoResolution, photoResolution // 2, " ")
    end
end

local function loadPhoto(path)
    if not path then
        local clear = saveBigZone(screen)
        path = gui_filepicker(screen, nil, nil, "/data/userdata/photos", "cam", false)
        clear()
        
        if not path then return end
    end

    local file, err = fs.open(path, "rb")
    if not file then
        warn(err)
        return
    end

    if file.read(8) == "CAM_____" then
        if string.byte(file.read(1)) > 50 then
            if not setBig() then
                file.close()
                return
            end
        else
            setSmall()
        end

        local content = file.readAll()
        
        photo = {}
        local i = 1
        local max = photoResolution - 1
        for cx = 0, max do
            photo[cx + 1] = {}
            for cy = 0, max, 2 do
                local lastByte = content:byte(i)
                i = i +1

                local byte1 = 0
                local byte2 = 0

                for i = 0, 3 do
                    byte1 = bit32.writebit(byte1, i, bit32.readbit(lastByte, i))
                end
                for i = 0, 3 do
                    byte2 = bit32.writebit(byte2, i, bit32.readbit(lastByte, i + 4))
                end

                photo[cx + 1][cy + 1] = byte1
                photo[cx + 1][cy + 2] = byte2
            end
        end

        drawPhoto()
    else
        warn("invalid file format")
        file.close()
    end
end

--------------------------------------------------

local readDist
local readFov

local function printCam()
    local gpu = graphic.findGpu(screen)
    gpu.setBackground(15, true)
    gpu.setForeground(0, true)
    gpu.set(rx - 14 - 12,  ry - 1, "                         ")
    if camera then
        local str = camera.address:sub(1, 4)
        local label = advLabeling.getLabel(camera.address)
        if label then
            str = str .. ":" .. label
        end
        gpu.set(rx - 14 - 12,  ry - 1, "cam: " .. str)
    else
        gpu.set(rx - 14 - 12,  ry - 1, "camera not selected")
    end
end

local function bg(col)
    local gpu = graphic.findGpu(screen)
    if gpu.getDepth() == 8 then
        gpu.setBackground(col)
    end
end

function redrawAll()
    local gpu = graphic.findGpu(screen)
    gpu.setBackground(0, true)
    gpu.setForeground(15, true)
    gpu.fill(1, 1, rx, ry, " ")

    printCam()

    bg(0xff0000)
    gpu.set(rx, 1, "X")

    bg(0xffff00)
    gpu.set(rx - 14, 2, " take ")
    gpu.set(rx - 7,  2, " clr  ")
    
    bg(0x00ff00)
    gpu.set(rx - 14, 4, " load ")
    gpu.set(rx - 7,  4, " save ")

    bg(0xff00ff)
    gpu.set(rx - 14, 6, " change size ")

    bg(0xffffff)
    gpu.set(rx - 14 - 12, ry - 2, "      select camera      ")
    
    drawPhoto()

    gpu.setBackground(4, true)
    gpu.fill(photoResolution + 1, 1, 1, ry, " ")
    
    gpu.setBackground(0, true)
    gpu.setForeground(15, true)

    readDist = window:read(rx - 14 - 12, 2, 11, 15, 0, "dist: ", nil, tostring(photoDist), true)
    readFov =  window:read(rx - 14 - 12, 3, 11, 15, 0, "fov : ", nil, tostring(photoFov), true)
end
redrawAll()

if path then
    loadPhoto(path)
end

while true do
    local eventData = {computer.pullSignal()}
    local windowEventData = window:uploadEvent(eventData)

    do
        local customDist = readDist.uploadEvent(windowEventData)
        if customDist == true then customDist = 60 end

        local allowUse = readDist.getAllowUse()
        if customDist or (not allowUse and readDist.oldAllowUse) then
            local dist = tonumber(customDist or readDist.getBuffer())
            if not dist then
                readDist.setBuffer(tostring(photoDist))
                readDist.redraw()
                warn("invalid input")
            else
                photoDist = dist
            end
        end
        readDist.oldAllowUse = allowUse
    end

    do
        local customFov = readFov.uploadEvent(windowEventData)
        if customFov == true then customFov = 90 end

        local allowUse = readFov.getAllowUse()
        if customFov or (not allowUse and readFov.oldAllowUse) then
            local fov = tonumber(customFov or readFov.getBuffer())
            if not fov then
                readFov.setBuffer(tostring(photoFov))
                readFov.redraw()
                warn("invalid input")
            else
                photoFov = fov
            end
        end
        readFov.oldAllowUse = allowUse
    end

    if windowEventData[1] == "touch" then
        if windowEventData[3] == rx and windowEventData[4] == 1 then
            break
        end

        if windowEventData[3] >= rx - 14 and windowEventData[3] <= rx - 2 then
            if windowEventData[4] == 2 then
                if windowEventData[3] <= (rx - 14) + 5 then
                    makePhoto()
                    drawPhoto()
                elseif windowEventData[3] > (rx - 14) + 6 then
                    photo = nil
                    drawPhoto()
                end
            elseif windowEventData[4] == 4 then
                if windowEventData[3] <= (rx - 14) + 5 then
                    loadPhoto()
                elseif windowEventData[3] > (rx - 14) + 6 then
                    savePhoto()
                end
            elseif windowEventData[4] == 6 then
                if rx == 160 then
                    setSmall()
                else
                    setBig()
                end
            end
        end

        if windowEventData[3] >= rx - 14 - 12 and windowEventData[3] <= rx - 2 then
            if windowEventData[4] == ry - 2 then
                local clear = saveBigZone(screen)
                local addr = gui_selectcomponent(screen, nil, nil, {"camera"})
                clear()

                if addr then
                    camera = component.proxy(addr)
                end
                printCam()
            end
        end
    end
end

gui_initScreen(screen)
gui_container.noScreenSaver[screen] = nil