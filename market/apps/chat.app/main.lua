local graphic = require("graphic")
local fs = require("filesystem")
local paths = require("paths")
local event = require("event")
local chat_lib = require("chat_lib")
local gui_container = require("gui_container")
local colorsApi = require("colors")
local unicode = require("unicode")
local liked = require("liked")
local computer = require("computer")
local screensaver = require("screensaver")
local thread = require("thread")
local image = require("image")
local serialization = require("serialization")

local colors = gui_container.colors
local indexsColors = gui_container.indexsColors
local screen, nickname, path = ...

------------------------------------

local isSendImage
if path and path:find("%:") then
    path = split(path, ":")[1]
    isSendImage = true
end

local historyPath = paths.concat(paths.path(getPath()), "history.dat")
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end
local window = graphic.createWindow(screen, 1, 1, rx, ry, true)

local history = {}

local function pushImage(data)
    local path = paths.concat("/tmp", tostring(math.floor(math.random(1, 99999))) .. ".t2p")

    local file = fs.open(path, "wb")
    file.write(data)
    file.close()

    return path
end

local function getMessageSize(tbl)
    local message = tbl[4]
    if tbl[3] == "text" then
        message = message .. unicode.len(tbl[1])
        if not tbl[5] then
            message = message .. "(you): "
        else
            if tbl[5] == 0 then
                message = message .. ": "
            else
                message = message .. " " .. tostring(math.roundTo(tbl[5], 1)) .. " blocks from you: "
            end
        end
    end

    if tbl[3] == "text" then
        return (unicode.len(message) // window.sizeX) + 1
    elseif tbl[3] == "file" then
        return 6
    elseif tbl[3] == "image" then
        local path = pushImage(message)
        local _, _, sy = pcall(image.size, path)
        fs.remove(path)
        return sy or 6
    end
end

local function addNullStrs(tbl)
    for i = 1, getMessageSize(tbl) - 1 do
        table.insert(history, false)
    end
end

local function updateHistory()
    if fs.exists(historyPath) then
        local file = fs.open(historyPath, "rb")
        local data = file.readAll()
        file.close()
    
        history = {}
        for i, v in ipairs(split(data, "\n")) do
            local tbl = serialization.unserialization(v)
            if tbl then
                table.insert(history, tbl)
                addNullStrs(tbl)
            end
        end
    end
end
updateHistory()

local function splitFile(data)
    local tbl = split(data, ":")
    local path = tbl[1]
    table.remove(tbl, 1)
    return path, table.concat(tbl, ":")
end

------------------------------------

local input
local scroll = 0
local function reinput()
    input = window:read(1, window.sizeY, window.sizeX, colors.gray, colors.white)
end
reinput()

--[[
local function getHistorySize()
    local value = 0
    for i, v in ipairs(history) do
        value = value + getMessageSize(v[3], v[4])
    end
    return value
end
]]

local function drawStatus()
    window:fill(1, 1, rx, 1, colors.gray, 0, " ")
    window:set(2, 1, colors.gray, colors.white, "Chat")
    window:set(window.sizeX, 1, colors.red, colors.white, "X")
    liked.drawUpBar(screen, true, colors.gray)
end

local isRedrawed
local exportButtons = {}
local existsCache = {}
local function draw()
    if screensaver.current(screen) then
        isRedrawed = true
        return
    end

    exportButtons = {}
    --window:clear(colors.white)
    window:fill(1, 2, window.sizeX - 1, window.sizeY - 2, colors.white, 0, " ")

    local historySize = #history
    for i, v in ipairs(history) do
        --(window.sizeY - ((#history - i) + 1)) + scroll
        if v then
            local posY = (window.sizeY - ((historySize - i) + 1)) + scroll
            if posY < window.sizeY and posY >= (3 - getMessageSize(v)) then
                window:setCursor(1, posY)
                window:write(v[1], colors.white, indexsColors[v[2] + 1])
                window.sizeX = window.sizeX - 1
                if not v[5] then
                    window:write("(you): ", colors.white, colors.black, true)
                else
                    if v[5] == 0 then
                        window:write(": ", colors.white, colors.black, true)
                    else
                        window:write(" " .. tostring(math.roundTo(v[5], 1)) .. " blocks from you: ", colors.white, colors.black, true)                    
                    end
                end
                window.sizeX = window.sizeX + 1
                if v[3] == "text" then
                    window.sizeX = window.sizeX - 1
                    window:write(v[4], colors.white, colors.black, true)
                    window.sizeX = window.sizeX + 1
                elseif v[3] == "image" then
                    local cx, cy = window:getCursor()

                    local path = pushImage(v[4])
                    image.draw(screen, path, cx, cy)
                    fs.remove(path)
                elseif v[3] == "file" then
                    local name = splitFile(v[4])
                    window:write("file: " .. name .. "  ", colors.white, colors.lime, true)

                    local cx, cy = window:getCursor()
                    local iconPath = paths.concat("/system/icons", (paths.extension(name) or "") .. ".t2p")

                    if existsCache[iconPath] == nil then
                        existsCache[iconPath] = fs.exists(iconPath)
                    end
                    if not existsCache[iconPath] then
                        iconPath = "/system/icons/unkownfile.t2p"
                    end

                    window:fill(cx, cy, 10, 6, colors.green, 0, " ")
                    image.draw(screen, iconPath, cx + 1, cy + 1)

                    window:set(cx - 7, cy + 2, colors.green, colors.yellow, "EXPORT")
                    table.insert(exportButtons, {cx - 7, cy + 2, function()
                        local savepath = gui_filepicker(screen, nil, nil, nil, paths.extension(name), true, false, nil, paths.hideExtension(name))
                        --local savepath = gui_selectfile(screen, nil, nil, 2, paths.extension(name), "file", {"this_type"}, paths.hideExtension(name))
                        if savepath then
                            local file, err = fs.open(savepath, "wb")
                            if file then
                                local _, data = splitFile(v[4])
                                file.write(data)
                                file.close()
                            else
                                gui_warn(screen, nil, nil, "error to save: " .. (err or "unknown"))
                            end
                        end
                        draw()
                    end})
                end
            end
        end
    end

    input.redraw()
    drawStatus()

    window:fill(rx, 2, 1, ry - 2, colors.lightGray, 0, " ")
    local pos = math.map(scroll, 0, (historySize - window.sizeY) + 1, window.sizeY - 1, 2)
    window:set(rx, pos, colors.green, 0, " ")
end
draw()

local function send(nickname, messageType, message)
    local packet = {nickname, colorsApi.red, messageType, message}
    chat_lib.send(table.unpack(packet))
    table.insert(history, packet)
    addNullStrs(packet)
    scroll = 0
    draw()
    reinput()
end

------------------------------------

if path then
    local file = fs.open(path, "rb")
    local data = file.readAll()
    file.close()

    send(nickname, isSendImage and "image" or "file", isSendImage and data or (paths.name(path) .. ":" .. data))
end

local oldStatusTime = computer.uptime()
local baseTh = thread.current()
local t
t = thread.createBackground(function()
    while true do
        local eventData = {event.pull(0.1)}
        if eventData[1] == "chat_message" then
            local tbl = {table.unpack(eventData, 2)}
            table.insert(history, tbl)
            addNullStrs(tbl)
            
            if scroll ~= 0 then
                scroll = scroll + 1
            else
                draw()
            end
        end

        if not screensaver.current(screen) then
            if computer.uptime() - oldStatusTime > 5 then
                drawStatus()
                oldStatusTime = computer.uptime()
            end

            if isRedrawed then
                isRedrawed = nil
                draw()
            end

            local windowEventData = window:uploadEvent(eventData)
            local inputData = input.uploadEvent(eventData)
            if inputData then
                if inputData ~= true then
                    if inputData ~= "" then
                        local nickname = eventData[5]
                        send(nickname, "text", inputData)
                    end
                else
                    break
                end
            end
            
            if windowEventData[1] == "touch" then
                if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
                    break
                else
                    for i, v in ipairs(exportButtons) do
                        if v then
                            if windowEventData[4] == v[2] and windowEventData[3] >= v[1] and windowEventData[3] < (v[1] + 6) then
                                v[3]()
                            end
                        end
                    end
                end
            elseif windowEventData[1] == "scroll" then
                if windowEventData[5] > 0 then
                    if scroll <= (#history - window.sizeY) then
                        scroll = scroll + 1
                        draw()
                    end
                else
                    if scroll > 0 then
                        scroll = scroll - 1
                        draw()
                    end
                end
            end

            if windowEventData[1] == "touch" or windowEventData[1] == "drag" then
                if windowEventData[3] == window.sizeX and windowEventData[4] > 1 and windowEventData[4] < window.sizeY then
                    local newscroll = math.round(map(windowEventData[4], 2, window.sizeY - 1, #history - window.sizeY, 0))
                    if newscroll <= (#history - window.sizeY) and newscroll > 0 then
                        if newscroll ~= scroll then
                            scroll = newscroll
                            draw()
                        end
                    end
                end
            end
        end
    end
    baseTh:kill()
    t:kill()
end)
t.parentData.screen = screen
t:resume()
event.wait()