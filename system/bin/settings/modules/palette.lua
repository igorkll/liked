local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local themesPath = "/system/themes"

------------------------------------

local selectWindow = graphic.classWindow:new(screen, posX, posY, 16, ry - (posY - 1))
local limit = 0
local themes = {}
for i, file in ipairs(fs.list(themesPath) or {}) do
    limit = limit + 1
    table.insert(themes, file)
end

local selected = 1

------------------------------------

local function draw()
    selectWindow:clear(colors.gray)
    selectWindow:setCursor(1, 1)
    for i, file in ipairs(themes) do
        local str = paths.hideExtension(file) .. string.rep(" ", (selectWindow.sizeX - 2) - unicode.len(file))

        local background = colors.lightGray
        local foreground = selected == i and colors.white or colors.black

        selectWindow:write("╔" .. string.rep("═", unicode.len(str)) .. "╗\n", background, foreground)
        selectWindow:write("║", background, foreground)
        selectWindow:write(str, background, foreground)
        selectWindow:write("║" .. "\n", background, foreground)
        selectWindow:write("╚" .. string.rep("═", unicode.len(str)) .. "╝", background, foreground)

        if i ~= limit then selectWindow:write("\n") end
    end
end
draw()