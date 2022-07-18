local graphic = require("graphic")
local fs = require("filesystem")
local calls = require("calls")
local eventData = require("event")
local colors = require("gui_container").colors
local component = require("component")
local computer = require("computer")

------------------------------------

local screen = ...

local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1)

------------------------------------

local mainurl = "https://raw.githubusercontent.com/igorkll/liked/main/market/list.lua"
local list = assert(load(assert(calls.call("getInternetFile", mainurl))))()

------------------------------------

local listOffSet = 1
local appsTbl = {}
local function draw()
    statusWindow:clear(colors.gray)
    statusWindow:set(1, 1, colors.gray, colors.white, "MARKET")
    statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")

    appsTbl = {}
    local count = 1
    for k, v in pairs(list) do
        if count >= listOffSet and count <= window.sizeY then
            window:set(1, 1, colors.gray, colors.white, k .. ":" .. (v.isInstalled() and "installed" or "no installed"))
            table.insert(appsTbl, 2)
        end
        count = count + 1
    end
end

------------------------------------

while true do
    local eventData = {computer.pullSignal()}
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    local windowEventData = window:uploadEvent(eventData)

    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[3] == statusWindow.sizeX and statusWindowEventData[4] == statusWindow.sizeY then
            break
        end
    end

    if windowEventData[1] == "touch" then
        local current = appsTbl[windowEventData[4]]
        if current then
            if current.isInstalled() then
                local yes = calls.call("gui_yesno", screen, nil, nil, "remove current?")
                if yes then
                    current.uninstall()
                end
                draw()
            else
                local yes = calls.call("gui_yesno", screen, nil, nil, "install current?")
                if yes then
                    current.install()
                end
                draw()
            end
        end
    elseif windowEventData[1] == "scroll" then
        if windowEventData[5] > 0 then
            listOffSet = listOffSet + 1
        else
            listOffSet = listOffSet - 1
        end
        if listOffSet > #appsTbl then
            listOffSet = #appsTbl
        elseif listOffSet < 1 then
            listOffSet = 1
        else
            draw()
        end
    end
end