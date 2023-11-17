local graphic = require("graphic")
local uix = require("uix")
local gui = require("gui")
local colorlib = require("colors")
local component = require("component")
local fs = require("filesystem")

local screen = ...
local cardwriter = gui.selectcomponentProxy(screen, nil, nil, {"os_cardwriter"}, true)
if not cardwriter then
    return
end

local guimanager = uix.manager(screen)
local rx, ry = graphic.getResolution(screen)
local layout = guimanager:create("Card Writer")

local count = 1
local lblcount = layout:createLabel(10, 2, 5, 1)
function lblcount.update()
    lblcount.text = tostring(count)
    lblcount:draw()
end
lblcount.update()

local subcount = layout:createButton(6, 2, 3, 1, nil, nil, "-")
function subcount:onClick()
    count = count - 1
    if count < 1 then
        count = 1
    else
        lblcount.update()
    end
end

local subcount2 = layout:createButton(2, 2, 4, 1, nil, nil, "--")
function subcount2:onClick()
    count = count - 10
    if count < 1 then
        count = 1
    end
    lblcount.update()
end

local addcount = layout:createButton(16, 2, 3, 1, nil, nil, "+")
function addcount:onClick()
    count = count + 1
    if count > 999 then
        count = 999
    end
    lblcount.update()
end

local addcount2 = layout:createButton(16 + 3, 2, 4, 1, nil, nil, "++")
function addcount2:onClick()
    count = count + 10
    if count > 999 then
        count = 999
    end
    lblcount.update()
end

layout:createText(2, 8, nil, "make readonly:")
local readonly = layout:createSwitch(17, 8, false, uix.colors.red)

local color = colorlib.cyan
local selectColor = layout:createButton(2, 4, 16, 1, uix.colors.cyan, nil, "Select Color", true)
function selectColor:onClick()
    local newcolor = gui.selectcolor(screen)
    if newcolor then
        color = newcolor
        uix.doColor(selectColor, uix.colors[colorlib[color]])
        selectColor.fore2 = selectColor.back
        selectColor.back2 = selectColor.fore
    end
    layout:draw()
end

local labelInput = layout:createInput(25, 2, 48, nil, nil, false, "key card", nil, 32)


local dataLed = layout:createLabel(27, 6, 3, 1, uix.colors.gray)
layout:createText(2, 6, nil, "data file: ")

local data
local loadDataFile = layout:createButton(13, 6, 6, 1, nil, nil, "load", true)
function loadDataFile:onClick()
    local file = gui_filepicker(screen)
    if file then
        data = fs.readFile(file)
        if data then
            dataLed.back = uix.colors.yellow
        end
    end
    layout:draw()
end

local clrDataFile = layout:createButton(20, 6, 6, 1, nil, nil, "clr")
function clrDataFile:onClick()
    data = nil
    dataLed.back = uix.colors.gray
    dataLed:draw()
end



local writeButton = layout:createButton(2, 10, 8, 1, nil, nil, "Write", true)
function writeButton:onClick()
    gui.status(screen, nil, nil, "writing...")
    for i = 1, count do
        local ok, err = cardwriter.write(data or "", labelInput.read.getBuffer(), not not readonly.state, color)
        if not ok then
            gui.warn(screen, nil, nil, err or "unknown error")
            break
        end
    end
    layout:draw()
end

local writeButton = layout:createButton(11, 10, 8, 1, nil, nil, "Flash", true)
function writeButton:onClick()
    gui.status(screen, nil, nil, "flashing...")
    for i = 1, count do
        local ok, err = cardwriter.flash(data or "", labelInput.read.getBuffer(), not not readonly.state)
        if not ok then
            gui.warn(screen, nil, nil, err or "unknown error")
            break
        end
    end
    layout:draw()
end

guimanager:loop()