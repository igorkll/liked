local fs = require("filesystem")
local unicode = require("unicode")
local calls = require("calls")
local graphic = require("graphic")
local calls = require("calls")
local gui_container = require("gui_container")

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
        cursorX = rx
    elseif cursorX < 1 then
        cursorX = 1
    end
    if cursorY > ry then
        cursorY = ry
    elseif cursorY < 1 then
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

local function moveCursorXPos()
    local linesize = #getLine()

end

------------------------------------

while true do
    
end