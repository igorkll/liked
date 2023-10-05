local graphic = require("graphic")
local gui_container = require("gui_container")
local uix = require("uix")
local fs = require("filesystem")
local gui = require("gui")
local component = require("component")
local liked = require("liked")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local layout = uix.create(window)

local labelInput = layout:createInput(2, 2, 30, colors.white, colors.gray, false, nil, nil, 24)

local codeSizeLabel = layout:createText(2, 4, colors.white)
local dataSizeLabel = layout:createText(2, 5, colors.white)
local maxCodeSizeLabel = layout:createText(18, 4, colors.white)
local maxDataSizeLabel = layout:createText(18, 5, colors.white)
local checksumLabel = layout:createText(2, 6, colors.white)
local addrLabel = layout:createText(2, 7, colors.white)
local writeLabel = layout:createText(2, 8, colors.white)

local flashButton = layout:createButton(2, 10, 16, 1, colors.white, colors.gray, "Flash")
local dumpButton = layout:createButton(2, 12, 16, 1, colors.white, colors.gray, "Dump")
local makeReadOnlyButton = layout:createButton(20, 10, 16, 1, colors.white, colors.gray, "Make R/O")

local eepromMissingString = "EEPROM IS MISSING"

function labelInput:onTextChanged(newlabel)
    if component.eeprom then
        local result = {component.eeprom.setLabel(newlabel)}
        if result[1] then
            if labelInput.read.getBuffer() ~= result[1] then
                labelInput.read.setBuffer(result[1])
                labelInput.oldText = result[1]
                self:draw()
            end
        else
            local label = component.eeprom.getLabel()
            labelInput.read.setBuffer(label)
            labelInput.oldText = label
            self:draw()

            gui.warn(screen, nil, nil, tostring(result[2]))
            redraw()
        end
    else
        if labelInput.read.getBuffer() ~= eepromMissingString then
            labelInput.read.setBuffer(eepromMissingString)
            labelInput.oldText = eepromMissingString
            self:draw()
        end
    end
end

function flashButton:onClick()
    if component.eeprom then
        os.sleep(0.1)
        self.state = false
        self:draw()
        graphic.forceUpdate()
        
        if gui.pleaseCharge(screen, 20, "flash") then
            local path = gui_filepicker(screen, nil, nil, nil, "lua", false, false)
            if path then
                local maxSize = math.round(component.eeprom.getSize())
                local data = fs.readFile(path)
                local fsize = #data
                if fsize > maxSize then
                    gui.warn(screen, nil, nil, "it is not possible to write a " .. fsize .. " bytes file to an EEPROM with a capacity of " .. maxSize .. " bytes")
                elseif gui.pleaseType(screen, "FLASH", "flash eeprom") then
                    gui_status(screen, nil, nil, "flashing...")
                    local result = {pcall(component.eeprom.set, data)}
                    if not result[1] then
                        gui.warn(screen, nil, nil, tostring(result[2] or "unknown error"))
                    elseif result[3] then
                        gui.warn(screen, nil, nil, tostring(result[3] or "unknown error"))
                    end
                end
            end
        end

        gRedraw()
        redraw()
    end
end

function dumpButton:onClick()
    if component.eeprom then
        os.sleep(0.1)
        self.state = false
        self:draw()
        graphic.forceUpdate()

        local path = gui_filepicker(screen, nil, nil, nil, "lua", true, false)
        if path then
            local data = component.eeprom.get()
            liked.assert(screen, fs.writeFile(path, data))
        end

        gRedraw()
        redraw()
    end
end

function makeReadOnlyButton:onClick()
    if component.eeprom then
        os.sleep(0.1)
        self.state = false
        self:draw()
        graphic.forceUpdate()

        if gui.pleaseCharge(screen, 20, "readonly") and gui.pleaseType(screen, "READONLY", "make readonly") then
            pcall(component.eeprom.makeReadonly, component.eeprom.getChecksum())
        end

        gRedraw()
        redraw()
    end
end

------------------------------------

function redraw()
    window:clear(colors.black)
    if component.eeprom then
        codeSizeLabel.text = "code size: " .. math.round(#component.eeprom.get())
        dataSizeLabel.text = "data size: " .. math.round(#component.eeprom.getData())
        maxCodeSizeLabel.text = "/ " .. math.round(tonumber(component.eeprom.getSize()) or 0)
        maxDataSizeLabel.text = "/ " .. math.round(tonumber(component.eeprom.getDataSize()) or 0)
        checksumLabel.text = "checksum : " .. tostring(component.eeprom.getChecksum())
        addrLabel.text     = "address  : " .. component.eeprom.address
        
        local writeble = not not component.eeprom.setLabel(component.eeprom.getLabel())
        writeLabel.text    = "storage  : " .. (writeble and "R/W" or "R/O")

        local label = component.eeprom.getLabel()
        labelInput.read.setBuffer(label)
        labelInput.oldText = label
    else
        codeSizeLabel.text = "code size: none"
        dataSizeLabel.text = "data size: none"
        maxCodeSizeLabel.text = "/ none"
        maxDataSizeLabel.text = "/ none"
        checksumLabel.text = "checksum : none"
        addrLabel.text     = "address  : none"
        labelInput.read.setBuffer(eepromMissingString)
        labelInput.oldText = eepromMissingString
    end
    layout:draw()
end
redraw()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)

    if (eventData[1] == "component_added" or eventData[1] == "component_removed") and eventData[3] == "eeprom" then
        redraw()
    end
end