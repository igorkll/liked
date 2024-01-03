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
    self.padding = true
    self.scrollBar = false
end

function gobjs.scrolltext:uploadEvent(eventData)
    eventData = uix.objEvent(self, eventData)
    if eventData and eventData[1] == "scroll" then
        local max = #(parser.split(unicode, self.text, "\n"))

        local oldScroll = self.scroll
        self.scroll = self.scroll - eventData[5]
        if self.scroll < 0 then self.scroll = 0 end
        if self.scroll >= max then self.scroll = max - 1 end
        if self.scroll ~= oldScroll then
            self:draw()
        end
    end
end

function gobjs.scrolltext:draw()
    self.w:fill(self.x, self.y, self.sizeX, self.sizeY, self.bg, 0, " ")
    for i, str in ipairs(parser.split(unicode, self.text, "\n")) do
        local linePos = (self.y + (i - 1)) - self.scroll
        local minLinePos = self.y
        local maxLinePos = self.y + self.sizeY
        if self.padding then
            maxLinePos = maxLinePos - 1
            minLinePos = minLinePos + 1
            linePos = linePos + 1
        end
        if linePos >= minLinePos and linePos < maxLinePos then
            local maxSize = self.sizeX
            if self.padding then
                maxSize = maxSize - 2
            end
            str = unicode.sub(str, 1, maxSize)
            
            local linePosX = self.x
            if self.padding then
                linePosX = linePosX + 1
            end
            self.w:set(linePosX, linePos, self.bg, self.fg, str)
        end
    end
end

--------------------------------

gobjs.unloadable = true
return gobjs