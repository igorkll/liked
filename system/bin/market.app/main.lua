local graphic = require("graphic")
local fs = require("filesystem")
local calls = require("calls")
local eventData = require("event")
local gui_container = require("gui_container")
local component = require("component")
local computer = require("computer")

local colors = gui_container.colors

------------------------------------

local screen = ...

local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)

------------------------------------

local netver = getInternetFile("https://raw.githubusercontent.com/igorkll/liked/main/system/version.cfg")

if not netver then
    gui_warn(screen, nil, nil, "connection error")
    return
end

if tonumber(netver) > getOSversion() then
    gui_warn(screen, nil, nil, "please update the system, until the system is updated, the market will not work")
    return
end

------------------------------------

local mainurl = "https://raw.githubusercontent.com/igorkll/liked/main/market/list.lua"
local list = assert(load(assert(calls.call("getInternetFile", mainurl))))()

------------------------------------

local listOffSet = 1
local appCount = 1
local appsTbl = {}
local function draw()
    statusWindow:clear(colors.gray)
    window:clear(colors.white)

    statusWindow:set(1, 1, colors.gray, colors.white, "MARKET")
    statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")

    appsTbl = {}
    appCount = 1
    for k, v in pairs(list) do
        if (not v.hided or gui_container.devModeStates[screen]) and appCount >= listOffSet and appCount <= window.sizeY then
            local installed = v.isInstalled()
            window:set(1, #appsTbl + 1, colors.white, installed and colors.green or colors.red, (v.name or k))
            --window:set(#(v.name or k) + 3, #appsTbl + 1, colors.white, installed and colors.green or colors.red, installed and "√" or "╳")
            table.insert(appsTbl, v)
        end
        appCount = appCount + 1
    end
end
draw()

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
            listOffSet = listOffSet - 1
        else
            listOffSet = listOffSet + 1
        end
        if listOffSet > appCount - 1 then
            listOffSet = appCount - 1
        end
        if listOffSet < 1 then
            listOffSet = 1
        end
        draw()
    end
end