local graphic = require("graphic")
local uix = require("uix")
local gui = require("gui")
local colorlib = require("colors")
local component = require("component")
local fs = require("filesystem")

local screen = ...
local cardwriter = gui.selectcomponentProxy(screen, nil, nil, {"os_cardwriter"}, true)
local guimanager = {}
local rx, ry = graphic.getResolution(screen)
local layout = uix.createAuto(screen, "Card Writer")

local count = 1
local lblcount = layout:createLabel(10, 3, 5, 1)
function lblcount.update()
    lblcount.text = tostring(count)
    lblcount:draw()
end
lblcount.update()

local subcount = layout:createButton(6, 3, 3, 1, nil, nil, "-")
function subcount:onClick()
    count = count - 1
    if count < 1 then
        count = 1
    else
        lblcount.update()
    end
end

local subcount2 = layout:createButton(2, 3, 4, 1, nil, nil, "--")
function subcount2:onClick()
    count = count - 10
    if count < 1 then
        count = 1
    end
    lblcount.update()
end

local addcount = layout:createButton(16, 3, 3, 1, nil, nil, "+")
function addcount:onClick()
    count = count + 1
    lblcount.update()
end

local addcount2 = layout:createButton(16 + 3, 3, 4, 1, nil, nil, "++")
function addcount2:onClick()
    count = count + 10
    lblcount.update()
end

layout:createText(2, 7, nil, "make readonly:")
local readonly = layout:createSwitch(17, 7, false, uix.colors.red)

local color = colorlib.cyan
local selectColor = layout:createButton(2, 5, 16, 1, uix.colors.cyan, nil, "Select Color")
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

local labelInput = layout:createInput(25, 3, 48, nil, nil, false, "key card", nil, 32)
local dataLed = layout:createLabel(32, 5, 3, 1, uix.colors.gray)

local data
local loadDataFile = layout:createButton(19, 5, 6, 1, nil, nil, "load")
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

local clrDataFile = layout:createButton(25, 5, 6, 1, nil, nil, "clr")
function clrDataFile:onClick()
    data = nil
    dataLed.back = uix.colors.gray
    layout:draw()
end

local writeButton = layout:createButton(2, 9, 8, 1, nil, nil, "Write")
function writeButton:onClick()
    for i = 1, count do
        cardwriter.write(data or "", labelInput.reader.getBuffer(), not not readonly.state, color)
    end
end

uix.loop(guimanager, layout)