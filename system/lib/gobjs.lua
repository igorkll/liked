local uix = require("uix")
local parser = require("parser")
local unicode = require("unicode")
local graphic = require("graphic")
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

function gobjs.scrolltext:onEvent(eventData)
    eventData = uix.objEvent(self, eventData)
    if eventData and eventData[1] == "scroll" then
        self:reLines()
        local max = #self.lines

        local oldScroll = self.scroll
        self.scroll = self.scroll - eventData[5]
        if self.scroll < 0 then self.scroll = 0 end
        if self.scroll >= max then self.scroll = max - 1 end
        if self.scroll ~= oldScroll then
            self:draw()
        end
    end
end

function gobjs.scrolltext:onDraw()
    self:reLines()
    self.w:fill(self.x, self.y, self.sizeX, self.sizeY, self.bg, 0, " ")
    for i, str in ipairs(self.lines) do
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



function gobjs.scrolltext:reLines()
    self.lines = self.lines or parser.split(unicode, self.text, "\n")
end

function gobjs.scrolltext:setText(text)
    self.scroll = 0
    self.text = text
    self.lines = nil
end

-------------------------------- layout manager

gobjs.manager = {}

function gobjs.manager:onCreate(sizeX, sizeY)
    self.sizeX = sizeX
    self.sizeY = sizeY
    self.screen = self.gui.window.screen
    self.current = nil
end

function gobjs.manager:onDraw()
    if self.current then
        self.current:draw()
    end
end

function gobjs.manager:onEvent(eventData)
    if self.current then
        self.current:uploadEvent(eventData)
    end
end



function gobjs.manager:fullStop()
    if self.current then
        self.current:fullStop()
    end
end

function gobjs.manager:fullStart()
    if self.current then
        self.current:fullStart()
    end
end

function gobjs.manager:select(layout)
    if self.current then
        self.current:fullStop()
    end

    self.current = layout
    if self.current then
        self.current.smartGuiManager = self
        self.current.allowAutoActive = nil
        self.current:fullStart()
        if self.current.onSelect then
            self.current:onSelect()
        end
        self.current:draw()
    end
end

function gobjs.manager:create(bgcolor, style)
    local window = graphic.create(self.screen, self.x, self.y, self.sizeX, self.sizeY)
    local layout = uix.createSimpleLayout(window, bgcolor, style)
    layout.bgWork = false
    layout.allowAutoActive = nil
    if not self.current then
        self:select(layout)
    end
    return layout
end

function gobjs.manager:size()
    return self.sizeX, self.sizeY
end

--------------------------------

gobjs.unloadable = true
return gobjs