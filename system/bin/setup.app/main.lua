local uix = require("uix")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:size()

-------------------------------- blincked hi

local blinckedHi = {}

function blinckedHi:onCreate()
    self.count = 0
end

function blinckedHi:draw()
    local color
    if self.count == 0 then
        color = uix.colors.white
    elseif self.count == 1 then
        color = uix.colors.lightGray
    elseif self.count == 2 then
        color = uix.colors.gray
    elseif self.count == 3 then
        color = uix.colors.black
    end

    self.gui.window:set(self.x, self.y + 0 , color, 0, "███                 ███")
    self.gui.window:set(self.x, self.y + 1 , color, 0, "███                 ███")
    self.gui.window:set(self.x, self.y + 2 , color, 0, "███                    ")
    self.gui.window:set(self.x, self.y + 3 , color, 0, "█████████           ███")
    self.gui.window:set(self.x, self.y + 4 , color, 0, "██████████          ███")
    self.gui.window:set(self.x, self.y + 5 , color, 0, "███      ██         ███")
    self.gui.window:set(self.x, self.y + 6 , color, 0, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 7 , color, 0, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 8 , color, 0, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 9 , color, 0, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 10, color, 0, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 11, color, 0, "███      ███        ███")

    self.count = self.count + 1
    if self.count >= 4 then
        self.count = 0
    end
end

--------------------------------

helloLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
helloLayout:createText(2, 1, uix.colors.white, "liked & likeOS")

hiObj = helloLayout:createCustom(rx / 2, ry / 2, blinckedHi)

helloLayout:timer(0.2, function ()
    hiObj:draw()
end, math.huge)

--------------------------------

ui:loop()