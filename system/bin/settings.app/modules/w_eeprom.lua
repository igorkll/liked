local graphic = require("graphic")
local gui_container = require("gui_container")
local uix = require("uix")
local fs = require("filesystem")
local gui = require("gui")
local component = require("component")
local event = require("event")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local layout = uix.create(window)

local checksumLabel = layout:createText(2, 2, colors.white)

local flashButton = layout:createButton(2, 4, 16, 1, colors.white, colors.gray, "Flash")
local dumpButton = layout:createButton(2, 6, 16, 1, colors.white, colors.gray, "Dump")
local makeReadOnlyButton = layout:createButton(20, 4, 16, 1, colors.white, colors.gray, "Make R/O")

function flashButton:onClick()
    os.sleep(0.1)
    self.state = false
    self:draw()
    graphic.forceUpdate()
    
    local path = gui_filepicker(screen, wx, wy, nil, "lua", false, false)
    if path then
        local maxSize = math.round(component.eeprom.getSize())
        local data = fs.readFile(path)
        local fsize = #data
        if fsize > maxSize then
            gui.warn(screen, nil, nil, "it is not possible to write a " .. fsize .. " bytes file to an EEPROM with a capacity of " .. maxSize .. " bytes")
        else
            gui_status(screen, nil, nil, "flashing...")
            local result = {pcall(component.eeprom.set, data)}
            if not result[1] then
                gui.warn(screen, nil, nil, tostring(result[2] or "unknown error"))
            elseif result[3] then
                gui.warn(screen, nil, nil, tostring(result[3] or "unknown error"))
            end
        end
    end

    gRedraw()
    redraw()
end

------------------------------------

function redraw()
    window:clear(colors.black)
    checksumLabel.text = "checksum: " .. tostring(component.eeprom.getChecksum())
    layout:draw()
end
redraw()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] >= 2 and windowEventData[3] <= 19 then
            if windowEventData[4] == 2 then
                --wipeUserData()
            elseif windowEventData[4] == 4 then
                --updateSystem()
            end
        end
    end
end