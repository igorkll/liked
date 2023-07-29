local graphic = require("graphic")
local fs = require("filesystem")
local calls = require("calls")
local eventData = require("event")
local gui_container = require("gui_container")
local component = require("component")
local computer = require("computer")
local paths = require("paths")

local colors = gui_container.colors

------------------------------------

local screen = ...
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

------------------------------------

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

local function applicationLabel(data, x, y)
    local applabel = graphic.createWindow(screen, x, y, rx - 2, 6)

    local img
    if data.icon then
        img = "/tmp/currentApp.t2p"
        local file = fs.open(img, "wb")
        file.write(getInternetFile(data.icon))
        file.close()
    else
        img = "/system/icons/app.t2p"
    end

    local installed = data:isInstalled()

    local function draw()
        applabel:clear(colors.gray)
        applabel:set(12, 2, colors.gray, colors.white, "name: " .. (data.name or "unknown"))
        applabel:set(12, 3, colors.gray, colors.white, "verion: " .. (data.version or "unknown"))
        applabel:set(12, 4, colors.gray, colors.white, "vendor: " .. (data.vendor or "unknown"))

        if installed then
            applabel:set(applabel.sizeX - 13, 2, colors.red, colors.white,   "   remove   ")
        else
            applabel:set(applabel.sizeX - 13, 2, colors.green, colors.white, "   install  ") 
        end

        gui_drawimage(screen, img, applabel:toRealPos(2, 2))
    end
    draw()
    
    return {tick = function (eventData)
        local windowEventData = applabel:uploadEvent(eventData)
        if windowEventData[1] == "touch" then
            if windowEventData[3] >= (applabel.sizeX - 13) and windowEventData[3] < ((applabel.sizeX - 13) + 12) and windowEventData[4] == 2 then
                if installed then
                    if gui_yesno(screen, nil, nil, "remove current?") then
                        data:uninstall()
                    end
                else
                    if gui_yesno(screen, nil, nil, "install current?") then
                        data:install()
                    end
                end

                installed = data:isInstalled()
                draw()
                return true
            end
        end
    end}
end

local function appInfo(data)
    local emptyDeskWindows = graphic.createWindow(screen, 2, 17, rx - 2, ry - 17)
    local deskWindows = graphic.createWindow(screen, 3, 18, rx - 4, ry - 19)

    local appLabel
    local function ldraw()
        statusWindow:clear(colors.gray)
        --statusWindow:set(1, 1, colors.gray, colors.white, "   ")
        statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "<")

        window:clear(colors.white)

        appLabel = applicationLabel(data, 2, 3)
        
        emptyDeskWindows:clear(colors.gray)
        deskWindows:clear(colors.gray)
        deskWindows:setCursor(1, 1)
        deskWindows:write(data.description or "this application does not contain a description\nO_o", colors.gray, colors.white, true)
    end
    ldraw()
    
    while true do
        local eventData = {computer.pullSignal()}
        if appLabel.tick(eventData) then
            ldraw()
        end

        local statusWindowEventData = statusWindow:uploadEvent(eventData)    
        if statusWindowEventData[1] == "touch" then
            if statusWindowEventData[3] == statusWindow.sizeX and statusWindowEventData[4] == statusWindow.sizeY then
                break
            end
        end
    end
end

local listOffSet = 1
local appCount = 1
local appsTbl = {}
local function draw()
    statusWindow:clear(colors.gray)
    window:clear(colors.white)

    statusWindow:set(1, 1, colors.gray, colors.white, "   MARKET")
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
            appInfo(current)
            draw()
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