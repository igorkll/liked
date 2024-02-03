local uix = require("uix")
local image = require("image")
local gui = require("gui")
local system = require("system")
local colorlib = require("colors")
local unicode = require("unicode")
local graphic = require("graphic")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local layout = ui:create("Clock", uix.colors.blue)

local currentNum = 1
local function addButton(num, x, y, ipath, title)
    ipath = system.getResourcePath(ipath)

    local sx, sy = image.size(ipath, screen)
    local button = layout:createButton(x, y, sx, sy, nil, nil, title, true)
    button.noDropDraw = true
    
    function button:draw()
        local icol
        if currentNum == num then
            icol = colorlib.red
        else
            icol = colorlib.white
        end

        local px, py = self.gui.window:toRealPos(self.x, self.y)
        image.draw(screen, ipath, px, py, true, nil, nil, nil, uix.colors.white, {icol})
        gui.drawtext(screen, px + (8 - (unicode.len(self.text) / 2)), py + 9, uix.colors.white, self.text)
    end

    function button:onClick()
        currentNum = num
        ui:draw()
    end

    return button
end

local dist = rx / 5
local add = -7
addButton(1, add + dist, 2, "alarm.t2p", "alarm")
addButton(2, add + (dist * 2), 2, "clock.t2p", "clock")
addButton(3, add + (dist * 3), 2, "timer.t2p", "timer")
addButton(4, add + (dist * 4), 2, "stopwatch.t2p", "stopwatch")

ui:loop()