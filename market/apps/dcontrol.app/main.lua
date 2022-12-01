local likenet = require("likenet")
local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")

local screen = ...
local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)
local colors = gui_container.colors
local client
local buttons = {}
local devices

local function draw()
    window:clear(colors.black)
    window:fill(1, 1, sizeX, 1, colors.gray, 0, " ")
    window:set(sizeX, 1, colors.red, colors.white, "X")
    
    if client and not client.connected then
        client = nil
    end

    if client then
        devices = nil
        window:set(1, 1, colors.red, colors.white, "<")
    else
        if not devices then
            devices = {}
            for i, device in ipairs(likenet.list()) do
                if device.name:sub(1, 9) == "dcontrol_" then
                    table.insert(devices, device)
                end
            end
        end

        for i, device in ipairs(devices) do
            window:set(1, i + 1, colors.lightGray, colors.gray, device.name)
        end
    end
end

local function getPress(eventData)
    
end

draw()

------------------------------------

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[4] == 1 then
            if windowEventData[3] == 1 then
                if client then client:disconnect() end
                draw()
            elseif windowEventData[3] == sizeX then
                if client then client:disconnect() end
                break
            end
        end

        if not client then
            local device = devices[windowEventData[4] - 1]
            if device then
                local lclient, err = likenet.connect(device, "584", "dcontrol")
                if lclient then
                    client = lclient
                else
                    gui_warn(screen, nil, nil, err or "unknown")
                end
                draw()
            end
        end
    end
end