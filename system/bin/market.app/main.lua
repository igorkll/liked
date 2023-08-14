local graphic = require("graphic")
local fs = require("filesystem")
local calls = require("calls")
local eventData = require("event")
local gui_container = require("gui_container")
local component = require("component")
local computer = require("computer")
local paths = require("paths")
local unicode = require("unicode")

local colors = gui_container.colors

------------------------------------

local title = "MARKET"

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
        img = "/tmp/market/" .. (data.name or "unknown") .. ".t2p"
        if not fs.exists(img) then
            saveFile(img, getInternetFile(data.icon))
        end
    else
        img = "/system/icons/app.t2p"
    end

    local installed = data:isInstalled()

    local function draw()
        applabel:clear(colors.black)
        applabel:set(12, 2, colors.black, colors.white, "name  : " .. (data.name or "unknown"))
        applabel:set(12, 3, colors.black, colors.white, "verion: " .. (data.version or "unknown"))
        applabel:set(12, 4, colors.black, colors.white, "vendor: " .. (data.vendor or "unknown"))

        if installed and data.getVersion and data:getVersion() ~= data.version then
            applabel:set(applabel.sizeX - 13, 2, colors.orange, colors.white, "   update    ")
        elseif installed then
            applabel:set(applabel.sizeX - 13, 2, colors.red, colors.white,    "  uninstall  ")
        else
            applabel:set(applabel.sizeX - 13, 2, colors.green, colors.white,  "   install   ")
        end

        gui_drawimage(screen, img, applabel:toRealPos(2, 2))
    end
    draw()
    
    return {tick = function (eventData)
        local windowEventData = applabel:uploadEvent(eventData)
        if windowEventData[1] == "touch" then
            if windowEventData[3] >= (applabel.sizeX - 13) and windowEventData[3] < ((applabel.sizeX - 13) + 13) and windowEventData[4] == 2 then
                if installed and data.getVersion and data:getVersion() ~= data.version then
                    if gui_yesno(screen, nil, nil, "update?") then
                        gui_status(screen, nil, nil, "updating...")
                        data:install()
                    end
                elseif installed then
                    if gui_yesno(screen, nil, nil, "uninstall?") then
                        gui_status(screen, nil, nil, "uninstalling...")
                        data:uninstall()
                    end
                else
                    if gui_yesno(screen, nil, nil, "install?") then
                        gui_status(screen, nil, nil, "installation...")
                        data:install()
                    end
                end

                installed = data:isInstalled()
                draw()
                return true
            else
                return false
            end
        end
    end, draw = draw}
end

local function appInfo(data)
    local emptyDeskWindows = graphic.createWindow(screen, 2, 17, rx - 2, ry - 17)
    local deskWindows = graphic.createWindow(screen, 3, 18, rx - 4, ry - 19)

    local appLabel
    local function ldraw()
        statusWindow:clear(colors.gray)
        statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
        statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")
        statusWindow:set(1, statusWindow.sizeY, colors.red, colors.white, "<")

        window:clear(colors.white)

        appLabel = applicationLabel(data, 2, 3)
        
        emptyDeskWindows:clear(colors.black)
        deskWindows:clear(colors.black)
        deskWindows:setCursor(1, 1)
        deskWindows:write(data.description or "this application does not contain a description\nO_o", colors.black, colors.white, true)
    end
    ldraw()
    
    while true do
        local eventData = {computer.pullSignal()}
        if appLabel.tick(eventData) then
            ldraw()
        end

        local statusWindowEventData = statusWindow:uploadEvent(eventData)    
        if statusWindowEventData[1] == "touch" then
            if statusWindowEventData[3] == 1 and statusWindowEventData[4] == statusWindow.sizeY then
                break
            end
            if statusWindowEventData[3] == statusWindow.sizeX and statusWindowEventData[4] == statusWindow.sizeY then
                return true
            end
        end
    end
end

local listOffSet = 1
local appCount = 1
local appsTbl = {}
--[[
local function draw()
    window:clear(colors.white)

    statusWindow:clear(colors.gray)
    statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
    statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")

    appsTbl = {}
    appCount = 1
    for k, v in pairs(list) do
        if (not v.hided or gui_container.devModeStates[screen]) and appCount >= listOffSet and appCount <= window.sizeY then
            local installed = v:isInstalled()
            window:set(1, #appsTbl + 1, colors.white, installed and colors.green or colors.red, (v.name or k))
            --window:set(#(v.name or k) + 3, #appsTbl + 1, colors.white, installed and colors.green or colors.red, installed and "√" or "╳")
            table.insert(appsTbl, v)
        end
        appCount = appCount + 1
    end
end
]]

local appLabels = {}
local function draw()
    window:clear(colors.white)

    appLabels = {}
    appsTbl = {}
    appCount = 1
    for i, v in ipairs(list) do
        if (not v.hided or gui_container.devModeStates[screen]) then
            table.insert(appLabels, applicationLabel(v, 2, 4 + ((appCount - listOffSet) * 7)))
            table.insert(appsTbl, v)
        end
        appCount = appCount + 1
    end

    
    statusWindow:clear(colors.gray)
    statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
    statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")
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
        for index, value in ipairs(appLabels) do
            local ret = value.tick(eventData)
            if ret == false then
                gui_status(screen, nil, nil, "loading...")
                if appInfo(appsTbl[index]) then
                    return
                end
                draw()
            elseif ret then
                draw()
            end
        end

        local current = appsTbl[windowEventData[4]]
        if current then
            
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