local fs = require("filesystem")
local unicode = require("unicode")
local calls = require("calls")
local graphic = require("graphic")
local calls = require("calls")
local computer = require("computer")
local gui_container = require("gui_container")
local component = require("component")

local screen, path = ...

local colors = gui_container.colors
local rx, ry
do
    local gpu = graphic.findGpu()
    rx, ry = gpu.getResolution()
end

------------------------------------

local lines = {}

local function saveFile()
    local file = fs.open(path, "w")
    for i, v in ipairs(lines) do
        file.write(v .. "\n")
    end
    file.close()
end

local function loadFile()
    local file = fs.open(path, "r")
    local data = file.readAll()
    file.close()
    lines = calls.call("split", data, "\n")
end

------------------------------------

local offsetX = 0
local offsetY = 0
local cursorX = 1
local cursorY = 1

local function redraw()
    local gpu = graphic.findGpu(screen)
    gpu.setForeground(colors.black)
    gpu.setBackground(colors.white)
    gpu.fill(1, 1, rx, ry, " ")
    for cy = 1, ry do
        local line = lines[cy + offsetY]
        if line then
            gpu.set(1 + offsetX, cy, line)
        end
    end
    local char, fore, back = gpu.get(cursorX, cursorY)
    gpu.setForeground(back)
    gpu.setForeground(fore)
    gpu.set(cursorX, cursorY, char)
end
redraw()

------------------------------------

local function mathLinePos()
    return cursorX - offsetX, cursorY - offsetY
end

local function getLine()
    local px, py = mathLinePos()
    return lines[py], px
end

local function checkPos()
    if cursorX > rx then
        offsetX = offsetX + 1
        cursorX = rx
    elseif cursorX < 1 then
        offsetX = offsetX - 1
        cursorX = 1
    end
    if cursorY > ry then
        offsetY = offsetY + 1
        cursorY = ry
    elseif cursorY < 1 then
        offsetY = offsetY - 1
        cursorY = 1
    end

    local linesize = #getLine()
    local px, py = mathLinePos()
    if py > #lines then
        py = #lines
    end
    if px > linesize then
        
    end
end

------------------------------------

while true do
    local eventData = {computer.pullSignal()}
    if eventData[1] == "key_down" then
        local ok
        for i, v in ipairs(component.invoke(screen, "getKeyboards")) do
            if v == eventData[2] then
                ok = true
                break
            end
        end
        if ok then
            if eventData[4] == 200 then
                cursorY = cursorY + 1
                checkPos()
            elseif eventData[4] == 208 then
                cursorY = cursorY - 1
                checkPos()
            elseif eventData[4] == 203 then
                cursorX = cursorX - 1
                checkPos()
            elseif eventData[4] == 205 then
                cursorX = cursorX + 1
                checkPos()
            end
        end
    end
end