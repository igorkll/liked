local fs = require("filesystem")
local paths = require("paths")
local graphic = require("graphic")
local computer = require("computer")
local calls = require("calls")
local component = require("component")
local colors = require("gui_container").colors

local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local path = paths.path(getPath())

--------------------------------------------

local window = graphic.createWindow(screen, 1, 1, rx, ry)

local setPos = (rx // 2) - 5

local function draw()
    window:clear(colors.white)
    window:set(setPos, 1, colors.lightGray, colors.white, "current version: " .. calls.call("getOSversion"))
    window:set(setPos, (ry // 2) + 0, colors.lightGray, colors.white, "Update")
    window:set(setPos, (ry // 2) + 1, colors.lightGray, colors.white, "Reinstall OS")
    window:set(setPos, (ry // 2) + 2, colors.lightGray, colors.white, "Recover OS")
    window:set(setPos, (ry // 2) + 3, colors.lightGray, colors.white, "Factory Reset")
    window:set(setPos, (ry // 2) + 4, colors.lightGray, colors.white, "Exit")
end
draw()


local function writeCustomInit()
    assert(fs.copy(paths.concat(path, "init.lua"), "/init.lua"))
end

local function removeUserData()
    fs.remove("/data")
end

local function removeSystem()
    fs.remove("/system")
end

local function endProcess()
    computer.shutdown("fast") --fast для быстрой перезагрузки, чтобы не показывалось меню bios(мой стандарт)
end

--------------------------------------------

while true do
    local eventData = {computer.pullSignal()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" then
        if windowEventData[3] >= setPos and windowEventData[3] <= setPos + 16 then
            if windowEventData[4] == (ry // 2) + 0 then --Update
                if not component.list("internet")() then
                    calls.call("gui_warn", screen, nil, nil, "no internet card found")
                    draw()
                else
                    local inetVersion = tonumber(assert(calls.call("getInternetFile",
                    "https://raw.githubusercontent.com/igorkll/liked/main/system/version.cfg")))
                    local localVersion = calls.call("getOSversion")
                    if inetVersion > localVersion then
                        if calls.call("gui_yesno", screen, nil, nil, "update to version " .. tostring(inetVersion)) then
                            writeCustomInit()
                            removeSystem()
                            endProcess()
                        else
                            draw()
                        end
                    else
                        calls.call("gui_warn", screen, nil, nil, "update is not found")
                        draw()
                    end
                end
            elseif windowEventData[4] == (ry // 2) + 1 then --reinstall os
                if not component.list("internet")() then
                    calls.call("gui_warn", screen, nil, nil, "no internet card found")
                    draw()
                else
                    if calls.call("gui_yesno", screen, nil, nil, "reinstall os? all data will be deleted!") then
                        writeCustomInit()
                        removeSystem()
                        removeUserData()
                        endProcess()
                    else
                        draw()
                    end
                end
            elseif windowEventData[4] == (ry // 2) + 2 then --recover os
                if not component.list("internet")() then
                    calls.call("gui_warn", screen, nil, nil, "no internet card found")
                    draw()
                else
                    if calls.call("gui_yesno", screen, nil, nil, "recover os?") then
                        writeCustomInit()
                        removeSystem()
                        endProcess()
                    else
                        draw()
                    end
                end
            elseif windowEventData[4] == (ry // 2) + 3 then --factory reset
                if calls.call("gui_yesno", screen, nil, nil, "factory reset? all data will be deleted!") then
                    removeUserData()
                    endProcess()
                else
                    draw()
                end
            elseif windowEventData[4] == (ry // 2) + 4 then --exit
                break
            end
        end
    end
end