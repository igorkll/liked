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
end
redraw()