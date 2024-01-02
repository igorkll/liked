local uix = require("uix")
local gobjs = require("gobjs")
local fs = require("filesystem")

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
    elseif self.count == 4 then
        color = uix.colors.black
    elseif self.count == 5 then
        color = uix.colors.gray
    elseif self.count == 6 then
        color = uix.colors.lightGray
    elseif self.count == 7 then
        color = uix.colors.white
    end

    local bg = uix.colors.cyan
    self.gui.window:set(self.x, self.y + 0 , bg, color, "███                 ███")
    self.gui.window:set(self.x, self.y + 1 , bg, color, "███                 ███")
    self.gui.window:set(self.x, self.y + 2 , bg, color, "███                    ")
    self.gui.window:set(self.x, self.y + 3 , bg, color, "█████████           ███")
    self.gui.window:set(self.x, self.y + 4 , bg, color, "██████████          ███")
    self.gui.window:set(self.x, self.y + 5 , bg, color, "███      ██         ███")
    self.gui.window:set(self.x, self.y + 6 , bg, color, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 7 , bg, color, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 8 , bg, color, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 9 , bg, color, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 10, bg, color, "███      ███        ███")
    self.gui.window:set(self.x, self.y + 11, bg, color, "███      ███        ███")

    self.count = self.count + 1
    if self.count >= 8 then
        self.count = 0
    end
end

--------------------------------

helloLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
helloLayout:createText(2, 1, uix.colors.white, "liked & likeOS")

hiObj = helloLayout:createCustom((rx / 2) - 11, (ry / 2) - 6, blinckedHi)
next1 = helloLayout:createButton((rx / 2) - 7, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, "next", true)

function next1:onClick()
    ui:select(licenseLayout)
end

helloLayout:timer(0.2, function ()
    hiObj:draw()
end, math.huge)

--------------------------------

licenseLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
licenseLayout:createCustom(2, 2, gobjs.scrolltext, rx - 2, ry - 4, assert(fs.readFile("/system/LICENSE")):gsub("\r", ""))

--------------------------------

ui:loop()