local graphic = require("graphic")
local event = require("event")
local programs = require("programs")
local fs = require("filesystem")
local calls = require("calls")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local computer = require("computer")

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

local currentModule
local function draw()
    selectWindow:clear(colors.lightGray)
    modulWindow:clear(colors.gray)
    statusWindow:clear(colors.black)
    lineWindows:clear(colors.brown)
    statusWindow:set(1, 1, colors.red, colors.white, "X")
    statusWindow:set(3, 1, colors.black, colors.white, "settings")

    selectWindow:setCursor(1, 1)
    for i, file in ipairs(modules) do
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

    local currentFile = paths.concat(modulesPath, modules[selected])
    local file = assert(fs.open(currentFile, "rb"))
    local data = file.readAll()
    file.close()

    local code = assert(load(data, "=module", nil, calls.call("createEnv")))
    currentModule = code(screen, modulWindow.x, modulWindow.y)
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
        local posY = ((selectWindowEventData[4] - 1) // 3) + 1

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
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] == 1 then
            break
        end
    end

    if currentModule then
        currentModule(eventData)
    end
end