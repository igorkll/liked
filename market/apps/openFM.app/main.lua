local uix = require("uix")
local gui = require("gui")
local component = require("component")
local colorlib = require("colors")
local system = require("system")
local paths = require("paths")
local fs = require("filesystem")
local parser = require("parser")
local unicode = require("unicode")

local colors = uix.colors

local selffolder = paths.path(system.getSelfScriptPath())
local stationsStrs = parser.split(unicode, assert(fs.readFile(paths.concat(selffolder, "list.txt"))), "\n")
local stations = {}
for index, str in ipairs(stationsStrs) do
    stations[index] = parser.split(unicode, str, ";")
end

local settings = require("registry").new(paths.concat(selffolder, "settings.dat"))
local screen = ...

local fm = gui.selectcomponent(screen, nil, nil, {"openfm_radio"}, true)
if not fm then
    return
else
    if not settings[fm] then
        settings[fm] = {url = stations[1][1], label = stations[1][2], index = 1}
    end
    fm = component.proxy(fm)
end

local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local cx, cy = math.round(rx / 2), math.round(ry / 2)
local layout = ui:create("OpenFM", colors.black)

local selectColor = layout:createButton(cx + 8, 2, 16, 1, colors.green, colors.gray, "Screen Color", true)
selectColor.fore = fm.getScreenColor()
if selectColor.fore == selectColor.back then
    if selectColor.back == colors.lime then
        selectColor.back = colors.green
    else
        selectColor.back = colors.lime
    end
end

local volDown = layout:createButton(cx - 6, 2, 3, 1, nil, nil, "<")
local currentVol = layout:createLabel(cx - 2, 2, 5, 1, nil, nil, tostring(math.round(fm.getVol() * 10)))
local volUp = layout:createButton(cx + 4, 2, 3, 1, nil, nil, ">")

local statOld = layout:createButton(cx - 28, 6, 3, 1, nil, nil, "<")
local statNext = layout:createButton(cx + 25, 6, 3, 1, nil, nil, ">")

local fmLabel = layout:createInput(cx - 24, 4, 48, nil, nil, false, settings[fm.address].label, nil, 32, "label: ")
local urlLabel = layout:createInput(cx - 24, 6, 48, nil, nil, false, settings[fm.address].url, nil, 256, "url: ")

fm.setScreenText(settings[fm.address].label)
fm.setURL(settings[fm.address].url)

local isPlayingLed = layout:createLabel(cx - 1, 8, 3, 1)
local startButton = layout:createButton(cx - 8, 8, 7, 1, nil, nil, "start")
local stopButton = layout:createButton(cx + 2, 8, 7, 1, nil, nil, "stop")

function isPlayingLed:beforeRedraw()
    isPlayingLed.back = fm.isPlaying() and colors.yellow or colors.gray
end

function statOld:onClick()
    local index = settings[fm.address].index - 1
    if index < 1 then
        index = #stations
    end

    settings[fm.address].index = index
    settings[fm.address].label = stations[index][2]
    settings[fm.address].url = stations[index][1]
    settings.save()

    local isPlaying = fm.isPlaying()
    if isPlaying then fm.stop() end
    fm.setScreenText(settings[fm.address].label)
    fm.setURL(settings[fm.address].url)
    if isPlaying then fm.start() end

    fmLabel.read.setBuffer(settings[fm.address].label)
    urlLabel.read.setBuffer(settings[fm.address].url)
    fmLabel.read.setOffset(0, 0)
    urlLabel.read.setOffset(0, 0)

    fmLabel:draw()
    urlLabel:draw()
end

function statNext:onClick()
    local index = settings[fm.address].index + 1
    if index > #stations then
        index = 1
    end

    settings[fm.address].index = index
    settings[fm.address].label = stations[index][2]
    settings[fm.address].url = stations[index][1]
    settings.save()

    local isPlaying = fm.isPlaying()
    if isPlaying then fm.stop() end
    fm.setScreenText(settings[fm.address].label)
    fm.setURL(settings[fm.address].url)
    if isPlaying then fm.start() end

    fmLabel.read.setBuffer(settings[fm.address].label)
    urlLabel.read.setBuffer(settings[fm.address].url)
    fmLabel.read.setOffset(0, 0)
    urlLabel.read.setOffset(0, 0)

    fmLabel:draw()
    urlLabel:draw()
end

function selectColor:onClick()
    local color = gui.selectcolor(screen, nil, nil, "Screen Color")
    if color then
        if colorlib[color] and colors[colorlib[color]] then
            selectColor.fore = colors[colorlib[color]]
            if selectColor.fore == selectColor.back then
                if selectColor.back == colors.lime then
                    selectColor.back = colors.green
                else
                    selectColor.back = colors.lime
                end
            end
            fm.setScreenColor(selectColor.fore + 0.0)
        end
    end
    ui:draw()
end

function startButton:onClick()
    fm.start()
    isPlayingLed:beforeRedraw()
    isPlayingLed:draw()
end

function stopButton:onClick()
    fm.stop()
    isPlayingLed:beforeRedraw()
    isPlayingLed:draw()
end

function fmLabel:onTextChanged(text)
    fm.setScreenText(text)
    settings[fm.address].label = text
    settings.save()
end

function urlLabel:onTextChanged(text)
    fm.setURL(text)
    settings[fm.address].url = text
    settings.save()
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

ui:loop()