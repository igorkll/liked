local graphic = require("graphic") --только при отрисовке в оперу лезет
local gui_container = require("gui_container")
local event = require("event")
local unicode = require("unicode")

local colors = gui_container.colors

------------------------------------

local screen, cx, cy, str, backgroundColor = ...
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

local window = graphic.createWindow(screen, cx, cy, 32, 8)

local color = backgroundColor or colors.lightGray

--window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
require("gui").shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)
window:clear(color)

local textColor = colors.white
if color == textColor then
    textColor = colors.black
end
for i, v in ipairs(restrs(str, 22)) do
    window:set(10, i + 1, color, textColor, v)
end

--window:set(2, 2, color, colors.blue, "  █  ")
--window:set(2, 3, color, colors.blue, " ███ ")
--window:set(2, 4, color, colors.blue, "█████")

window:set(2, 2, color, colors.blue, "  " .. unicode.char(0x2800+192) ..  "  ")
window:set(2, 3, color, colors.blue, " ◢█◣ ")
window:set(2, 4, color, colors.blue, "◢███◣")
window:set(4, 3, colors.blue, colors.white, "P")

graphic.forceUpdate()
event.yield()
--[[
if require("registry").soundEnable then
    computer.beep(500, 0.1)
end
]]