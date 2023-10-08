local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local liked = require("liked")
local gui = require("gui")
local component = require("component")
local colors = require("gui_container").colors

local screen = ...

local fm = gui.selectcomponent(screen, nil, nil, {"openfm_radio"}, true)
if not fm then
    return
else
    fm = component.proxy(fm)
end

local rx, ry = graphic.getResolution(screen)
local cx, cy = math.round(rx / 2), math.round(ry / 2)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)

local volDown = layout:createButton(cx - 4, 3, 3, 1, nil, nil, "<")
local currentVol = layout:createLabel(cx - 1, 3, 3, 1)
local volUp = layout:createButton(cx + 2, 3, 3, 1, nil, nil, ">")

local fmLabel = layout:createInput(cx - 24, 5, 48, nil, nil, false, nil, nil, 32, "label: ")
local urlLabel = layout:createInput(cx - 24, 7, 48, nil, nil, false, nil, nil, 256, "url: ")

local startButton = layout:createButton(cx - 8, 9, 7, 1, nil, nil, "start")
local stopButton = layout:createButton(cx + 2, 9, 7, 1, nil, nil, "stop")

function startButton:onClick()
    fm.start()
end

function stopButton:onClick()
    fm.stop()
end

function fmLabel:onTextChanged(text)
    fm.setScreenText(text)
end

function urlLabel:onTextChanged(text)
    fm.setURL(text)
end

function volDown:onClick()
    fm.volDown()
    currentVol.text = tostring(math.round(fm.getVol() * 10))
    currentVol:draw()
end

function volUp:onClick()
    fm.volUp()
    currentVol.text = tostring(math.round(fm.getVol() * 10))
    currentVol:draw()
end

--------------------------------------------------------

currentVol.text = tostring(math.round(fm.getVol() * 10))

layout:draw()
liked.drawFullUpBar(screen, "OpenFM")

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] == rx and windowEventData[4] == 1 then
            break
        end
    end
end