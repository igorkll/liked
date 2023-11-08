local graphic = require("graphic")
local uix = require("uix")
local gui = require("gui")
local colorlib = require("colors")

local screen = ...
local guimanager = {}
local rx, ry = graphic.getResolution(screen)
local layout = uix.createAuto(screen, "Card Writer")

local score = 1
local lblScore = layout:createLabel(10, 3, 5, 1)
function lblScore.update()
    lblScore.text = tostring(score)
    lblScore:draw()
end
lblScore.update()

local subScore = layout:createButton(6, 3, 3, 1, nil, nil, "-")
function subScore:onClick()
    score = score - 1
    if score < 1 then
        score = 1
    else
        lblScore.update()
    end
end

local subScore2 = layout:createButton(2, 3, 4, 1, nil, nil, "--")
function subScore2:onClick()
    score = score - 10
    if score < 1 then
        score = 1
    end
    lblScore.update()
end

local addScore = layout:createButton(16, 3, 3, 1, nil, nil, "+")
function addScore:onClick()
    score = score + 1
    lblScore.update()
end

local addScore2 = layout:createButton(16 + 3, 3, 4, 1, nil, nil, "++")
function addScore2:onClick()
    score = score + 10
    lblScore.update()
end

layout:createText(2, 7, nil, "make readonly:")
local readonly = layout:createSwitch(17, 7, false, uix.colors.red)

local color = colorlib.white
local selectColor = layout:createButton(2, 5, 16, 1, uix.colors.white, nil, "Select Color")
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



uix.loop(guimanager, layout)