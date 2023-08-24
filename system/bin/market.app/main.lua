local graphic = require("graphic")
local fs = require("filesystem")
local calls = require("calls")
local eventData = require("event")
local gui_container = require("gui_container")
local component = require("component")
local computer = require("computer")
local paths = require("paths")
local unicode = require("unicode")
local programs = require("programs")

local colors = gui_container.colors

------------------------------------

local title = "MARKET"

local screen, nickname = ...
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local rootfs = fs.get("/")

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
local list = assert(load(assert(calls.call("getInternetFile", mainurl))))(screen, nickname)

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

    local supportErr
    if data.minDiskSpace then
        local freeSpace = (rootfs.spaceTotal() - rootfs.spaceUsed()) / 1024
        if freeSpace < data.minDiskSpace then
            supportErr = "not enough space to install. need: " .. tostring(data.minDiskSpace) .. "KB"
        end
    end
    if data.minColorDepth and graphic.findGpu(screen).maxDepth() < data.minColorDepth then
        local level = -1
        if data.minColorDepth == 1 then
            level = 1
        elseif data.minColorDepth == 4 then
            level = 2
        elseif data.minColorDepth == 8 then
            level = 3
        end
        supportErr = "the graphics system level is too low. need: " .. tostring(level)
    end

    local function draw()
        applabel:clear(colors.black)
        applabel:set(12, 2, colors.black, colors.white, "name  : " .. (data.name or "unknown"))
        applabel:set(12, 3, colors.black, colors.white, "verion: " .. (data.version or "unknown"))
        applabel:set(12, 4, colors.black, colors.white, "vendor: " .. (data.vendor or "unknown"))

        if data.license then
            applabel:set(applabel.sizeX - 13, 3, colors.blue, colors.white, "   license   ")
        end

        local altCol = supportErr and colors.gray
        if installed and data.getVersion and data:getVersion() ~= data.version then
            applabel:set(applabel.sizeX - 13, 2, altCol or colors.orange, colors.white, "   update    ")
        elseif installed then
            applabel:set(applabel.sizeX - 13, 2, altCol or colors.red, colors.white,    "  uninstall  ")
        else
            applabel:set(applabel.sizeX - 13, 2, altCol or colors.green, colors.white,  "   install   ")
        end

        gui_drawimage(screen, img, applabel:toRealPos(2, 2))
    end

    if y > -4 and y <= ry then
        draw()
    end
    
    
    return {tick = function (eventData)
        local windowEventData = applabel:uploadEvent(eventData)
        if windowEventData[1] == "touch" then
            if windowEventData[3] >= (applabel.sizeX - 13) and windowEventData[3] < ((applabel.sizeX - 13) + 13) and windowEventData[4] == 3 then
                if data.license then
                    local license = "/tmp/market/" .. (data.name or "unknown") .. ".txt"

                    gui_status(screen, nil, nil, "license loading...")
                    assert(saveFile(license, assert(getInternetFile(data.license))))
                    programs.execute("edit", screen, nickname, license, true)
                    fs.remove(license)

                    return true
                end
            elseif windowEventData[3] >= (applabel.sizeX - 13) and windowEventData[3] < ((applabel.sizeX - 13) + 13) and windowEventData[4] == 2 then
                local formattedName = " \"" .. (data.name or "unknown") .. "\"?"
                local formattedName2 = " \"" .. (data.name or "unknown") .. "\"..."
                if installed and data.getVersion and data:getVersion() ~= data.version then
                    if supportErr then
                        gui_warn(screen, nil, nil, supportErr)
                    elseif gui_yesno(screen, nil, nil, "update" .. formattedName) then
                        gui_status(screen, nil, nil, "updating" .. formattedName2)
                        data:install()
                    end
                elseif installed then
                    if gui_yesno(screen, nil, nil, "uninstall" .. formattedName) then
                        gui_status(screen, nil, nil, "uninstalling" .. formattedName2)
                        data:uninstall()
                    end
                else
                    if supportErr then
                        gui_warn(screen, nil, nil, supportErr)
                    elseif gui_yesno(screen, nil, nil, "install" .. formattedName) then
                        gui_status(screen, nil, nil, "installation" .. formattedName2)
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
                    break
                end
                draw()
            elseif ret then
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
        elseif listOffSet < 1 then
            listOffSet = 1
        else
            draw()
        end
    end
end

fs.remove("/tmp/market")