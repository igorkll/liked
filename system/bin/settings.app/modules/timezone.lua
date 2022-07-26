local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local timeZonePath = "/data/timeZone.dat"

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local function draw()
    local currentTimezone = 3
    if fs.exists(timeZonePath) then
        local file = fs.open(timeZonePath, "rb")
        local data = tonumber(file.readAll())
        file.close()
        if data then
            currentTimezone = data
        end
    end

    window:clear(colors.black)
    window:set(1, 1, colors.lightGray, colors.white, "current timezone: " .. tostring(currentTimezone))
    window:set(1, 2, colors.lightGray, colors.white, "set new timezone")
end
draw()

------------------------------------

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] == 2 and windowEventData[3] >= 1 and windowEventData[3] <= 16 then
            local data = calls.call("gui_input", screen, nil, nil, "timezone")
            if data then
                data = tonumber(data)
                if not data then
                    calls.call("gui_warn", screen, nil, nil, "uncorrent input")
                else
                    local file = fs.open(timeZonePath, "wb")
                    file.write(tostring(data))
                    file.close()
                    _G.timeZone = nil
                end
            end
            draw()
        end
    end
end