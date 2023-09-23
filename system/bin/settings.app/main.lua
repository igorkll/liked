local graphic = require("graphic")
local event = require("event")
local programs = require("programs")
local fs = require("filesystem")
local calls = require("calls")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local computer = require("computer")
local bootloader = require("bootloader")

local colors = gui_container.colors

------------------------------------

local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()
local path = paths.path(calls.call("getPath"))
local modulesPath = paths.concat(path, "modules")

------------------------------------

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local selectWindow = graphic.createWindow(screen, 1, 2, rx // 4, ry - 1)
local modulWindow = graphic.createWindow(screen, (rx // 4) + 2, 2, (rx - (rx // 4)) - 1, ry)
local lineWindows = graphic.createWindow(screen, (rx // 4) + 1, 2, 1, ry - 1)

local selected = 1
local limit = 0
local modules = {}
for i, file in ipairs(fs.list(modulesPath) or {}) do
    limit = limit + 1
    table.insert(modules, file)
end

local currentModule, moduleEnd
local function draw()
    selectWindow:clear(colors.lightGray)
    modulWindow:clear(colors.gray)
    statusWindow:clear(colors.gray)
    lineWindows:clear(colors.brown)
    statusWindow:set(statusWindow.sizeX, 1, colors.red, colors.white, "X")
    statusWindow:set((statusWindow.sizeX / 2) - 4, 1, colors.gray, colors.white, "Settings")

    for i, file in ipairs(modules) do
        file = file:sub(3, #file)
        local str = paths.hideExtension(file)

        --selectWindow:write("╔" .. string.rep("═", unicode.len(str)) .. "╗\n", background, foreground)
        --selectWindow:write("║", background, foreground)
        local selColor = selected == i and colors.white or colors.black
        selectWindow:fill(1, i, selectWindow.sizeX, 1, selColor, colors.lightGray, " ")
        selectWindow:set(3, i, selColor, colors.lightGray, str)
        if selected == i then
            selectWindow:set(1, i, selColor, colors.lightGray, ">")
        end
        --selectWindow:write("║" .. "\n", background, foreground)
        --selectWindow:write("╚" .. string.rep("═", unicode.len(str)) .. "╝", background, foreground)
    end

    if moduleEnd then
        moduleEnd()
    end
    local code = loadfile(paths.concat(modulesPath, modules[selected]), nil, bootloader.createEnv())
    modulWindow:clear(colors.black)
    currentModule, moduleEnd = code(screen, modulWindow.x, modulWindow.y)
end
draw()

while true do
    local eventData = {computer.pullSignal()}
    local selectWindowEventData = selectWindow:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)

    if selectWindowEventData[1] == "scroll" then
        local oldselected = selected
        if selectWindowEventData[5] > 0 then
            selected = selected - 1
            if selected < 1 then selected = 1 end
        else
            selected = selected + 1
            if selected > limit then selected = limit end
        end
        if selected ~= oldselected then
            draw()
        end
    elseif selectWindowEventData[1] == "touch" then
        --local posY = ((selectWindowEventData[4] - 1) // 3) + 1
        local posY = (selectWindowEventData[4] - 1) + 1

        if posY >= 1 and posY <= limit then
            if posY ~= selected then
                selected = posY
                draw()
            end
        end
    elseif selectWindowEventData[1] == "key_down" then
        local oldselected = selected
        if selectWindowEventData[4] == 200 then
            selected = selected - 1
            if selected < 1 then selected = 1 end
        elseif selectWindowEventData[4] == 208 then
            selected = selected + 1
            if selected > limit then selected = limit end
        end
        if selected ~= oldselected then
            draw()
        end
    end

    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] == statusWindow.sizeX then
            if moduleEnd then
                moduleEnd()
            end
            break
        end
    end

    if currentModule then
        currentModule(eventData)
    end
end