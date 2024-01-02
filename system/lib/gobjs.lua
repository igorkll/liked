local uix = require("uix")
local parser = require("parser")
local unicode = require("unicode")
local gobjs = {}

-------------------------------- scroll text

gobjs.scrolltext = {}

function gobjs.scrolltext:onCreate(sizeX, sizeY, text)
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.text = text or ""
    self.scroll = 0
    self.w = self.gui.window

    self.bg = uix.colors.white
    self.fg = uix.colors.gray
end

function gobjs.scrolltext:uploadEvent(eventData)
    eventData = uix.objEvent(self, eventData)
    if eventData and eventData[1] == "scroll" then
        local max = #(parser.split(unicode, self.text, "\n"))

        self.scroll = self.scroll - eventData[5]
        if self.scroll < 0 then self.scroll = 0 end
        if self.scroll >= max then self.scroll = max - 1 end
        self:draw()
    end
end

function gobjs.scrolltext:draw()
    self.w:fill(self.x, self.y, self.sizeX, self.sizeY, self.bg, 0, " ")
    for i, str in ipairs(parser.split(unicode, self.text, "\n")) do
        local linePos = (self.y + (i - 1)) - self.scroll
        if linePos >= self.y and linePos < self.y + self.sizeY then
            self.w:set(self.x, linePos, self.bg, self.fg, str)
        end
    end
end

--------------------------------

gobjs.unloadable = true
return gobjs