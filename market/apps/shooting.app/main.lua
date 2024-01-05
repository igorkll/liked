local draw = require("draw")
local colors = require("colors")
local liked = require("liked")
local thread = require("thread")
local event = require("event")
local graphic = require("graphic")
local uix = require("uix")
local gui = require("gui")

local screen = ...
local rx, ry = graphic.getResolution(screen)
liked.drawFullUpBarTask(screen, "Shooting")
local exitFlag
liked.regExit(screen, function ()
    exitFlag = true
    event.stub()
end, true)

local showWindowSizeX = ry * 2

local shotWindow = graphic.createWindow(screen, 1, 2, showWindowSizeX, ry - 1)
local appWindow = graphic.createWindow(screen, showWindowSizeX + 1, 2, rx - showWindowSizeX, ry - 1)
local ui = uix.create(appWindow, draw.colors.black, uix.styles[2])
local render = draw.create(shotWindow, draw.modes.semi)
local sx, sy = render:size()

local cr = (sx / 2) - 2
local cx, cy = (sx / 2) - 1, (sy / 2) - 1

--------------------------------

local userNamePos = 4
local colorPos = 16
local scorePos = 22

local gameUsers = {}
local bg, fg = uix.colors.white, uix.colors.gray
local bl = uix.colors.black
local usedColors
local colorsEnd
local function recreateUsedColors()
    usedColors = {[bg] = true, [fg] = true, [bl] = true, [draw.colors.red] = true, [uix.colors.lightGray] = true}
end
recreateUsedColors()

ui:createLabel(3, 2, 26, 1, bg)
ui:createText(userNamePos, 2, fg, "User")
ui:createText(colorPos, 2, fg, "Color")
ui:createText(scorePos, 2, fg, "Score")

ui:createCustom(3, 3, {
    onCreate = function (self)
        self.w = self.gui.window
    end,
    draw = function (self)
        for i, data in ipairs(gameUsers) do
            local pos = self.y + (i - 1)
            local lbg = i % 2 == 0 and uix.colors.gray or uix.colors.lightGray
            self.w:fill(self.x, pos, 26, 1, lbg, 0, " ")
            self.w:set(1 + userNamePos, pos, lbg, bl, data.nickname)
            self.w:set(1 + colorPos, pos, data.color, 0, "  ")
            self.w:set(1 + scorePos, pos, lbg, bl, tostring(data.score))
        end
    end
})

--------------------------------

local function drawUsers()
    ui:draw()
end

local function redraw()
    drawUsers()

    render:clear(draw.colors.lightGray)
    local state = false
    for r = cr, 2, -3 do
        local color = state and draw.colors.gray or draw.colors.white
        if r == 2 then
            color = draw.colors.red
        end
        render:circle(cx, cy, r, color)
        state = not state
    end
end

--------------------------------

local function mathDist(x, y, x2, y2)
    return math.sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2))
end

local function mathScore(px, py)
    local dist = mathDist(cx, cy, px - 1, py - 1)
    local fraction = dist / cr
    if fraction < 1 then
        return math.round((1 - fraction) * 25)
    else
        return -math.round((fraction - 0.7) * 25)
    end
end

local function lowLevelGenerateColor()
    if graphic.getDepth(screen) == 8 then
        return colors.blend(math.random(0, 255), math.random(0, 255), math.random(0, 255))
    else
        local r = math.random(1, 8)
        if r == 1 then
            return draw.colors.cyan
        elseif r == 2 then
            return draw.colors.orange
        elseif r == 3 then
            return draw.colors.brown
        elseif r == 4 then
            return draw.colors.green
        elseif r == 5 then
            return draw.colors.lime
        elseif r == 6 then
            return draw.colors.pink
        elseif r == 7 then
            return draw.colors.purple
        elseif r == 8 then
            return draw.colors.magenta
        end
    end
    return draw.colors.black
end

local function generateColor()
    if not colorsEnd then
        for i = 1, 4096 do
            local color = lowLevelGenerateColor()
            if not usedColors[color] then
                return color
            end
        end
    end
    colorsEnd = true
    return lowLevelGenerateColor()
end

--------------------------------

local function findUser(nickname)
    for i, data in ipairs(gameUsers) do
        if data.nickname == nickname then
            return data
        end
    end
end

local function generateUser(nickname)
    local user = findUser(nickname)
    if not user then
        local color = generateColor()
        usedColors[color] = true
        user = {color = color, nickname = nickname, score = 0}
        table.insert(gameUsers, user)
    end
    return user
end

local recreate = ui:createButton(3, ui.window.sizeY - 1, 16, 1, nil, nil, "recreate", true)
function recreate:onClick()
    recreateUsedColors()
    gameUsers = {}
    colorsEnd = nil
    redraw()
end

redraw()

while true do
    local eventData = {event.pull()}
    local shotEventData = render:touchscreen(eventData)
    if shotEventData and shotEventData[1] == "touch" then
        local user = generateUser(shotEventData[6])
        local px, py = shotEventData[3], shotEventData[4]
        render:dot(px, py, user.color)
        render:dot(px, py+1, user.color)
        render:dot(px, py-1, user.color)
        render:dot(px+1, py, user.color)
        render:dot(px-1, py, user.color)
        user.score = user.score + mathScore(px, py)
        drawUsers()
    end

    ui:uploadEvent(eventData)

    if exitFlag then
        local clear = gui.saveZone(screen)
        if gui.yesno(screen, nil, nil, "are you sure you want to get out?") then
            return
        else
            clear()
        end

        exitFlag = nil
    end
end