local unicode = require("unicode")
local gui_container = require("gui_container")
local colors = gui_container.colors
local uix = {}

---------------------------------- obj class

local objclass = {}

function objclass:destroy()
    for i = #self.gui.objs, 1, -1 do
        if self.gui.objs[i] == self then
            table.remove(self.gui.objs, i)
        end
    end
end

function objclass:uploadEvent(eventData)
    if self.type == "button" then
        if eventData[1] == "touch" and eventData[3] >= self.x and eventData[4] >= self.y and eventData[3] < self.x + self.sx and eventData[4] < self.y + self.sy then
            self.state = true
            self:draw()
            
            if self.onClick then
                self:onClick(eventData[5], eventData[6])
            end
        elseif eventData[1] == "drop" and self.state then
            self.state = false
            self:draw()

            if self.onDrop then
                self:onDrop(eventData[5], eventData[6])
            end
        end
    elseif self.type == "switch" then
        if eventData[1] == "touch" and eventData[3] >= self.x and eventData[3] < self.x + 6 and eventData[4] == self.y then
            self.state = not self.state
            self:draw()

            if self.onSwitch then
                self:onSwitch(eventData[5], eventData[6])
            end
        end
    end
end

function objclass:draw()
    if self.type == "bg" then
        self.gui.window:clear(self.color)
    elseif self.type == "label" or self.type == "button" then
        local back, fore = self.back, self.fore
        if self.state then
            back, fore = self.back2 or back, self.fore2 or fore
        end

        local x, y, sx, sy = self.x, self.y, self.sx, self.sy
        local tx, ty = (x + math.round(sx / 2)) - math.round(unicode.len(self.text) / 2), y + (math.round(sy / 2) - 1)
        local _, _, bg = self.gui.window:get(x, y)
        self.gui.window:fill(x, y, sx, sy, back, 0, " ")
        self.gui.window:set(x, y, bg, back, "◖")
        self.gui.window:set(x + (sx - 1), y, bg, back, "◗")
        

        if self.text then
            self.gui.window:set(tx, ty, back, fore, self.text)
        end
    elseif self.type == "switch" then
        local bg = self.state and self.enableColor or self.disableColor
        local _, _, fg = self.gui.window:get(self.x, self.y)

        self.gui.window:set(self.x, self.y, fg, bg, "◖████◗")
        if self.state then
            self.gui.window:set(self.x + 4, self.y, bg, self.pointerColor, "◖")
            self.gui.window:set(self.x + 5, self.y, fg, self.pointerColor, "◗")
        else
            self.gui.window:set(self.x, self.y, fg, self.pointerColor, "◖")
            self.gui.window:set(self.x + 1, self.y, bg, self.pointerColor, "◗")
        end
    elseif self.type == "text" then
        if self.text then
            local _, _, bg = self.gui.window:get(self.x, self.y)
            self.gui.window:set(self.x, self.y, bg, self.color, self.text)
        end
    end
end

----------------------------------

function uix:createBg(color)
    local obj = setmetatable({gui = self, type = "bg"}, {__index = objclass})
    obj.color = color

    table.insert(self.objs, obj)
    return obj
end

function uix:createLabel(x, y, sx, sy, back, fore, text)
    local obj = setmetatable({gui = self, type = "label"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.back = back or colors.white
    obj.fore = fore or colors.gray
    obj.text = text

    table.insert(self.objs, obj)
    return obj
end

function uix:createButton(x, y, sx, sy, back, fore, text)
    local obj = setmetatable({gui = self, type = "button"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.back = back or colors.white
    obj.fore = fore or colors.gray
    obj.back2 = fore
    obj.fore2 = back
    obj.text = text
    obj.state = false

    table.insert(self.objs, obj)
    return obj
end

function uix:createSwitch(x, y, state, enableColor, disableColor, pointerColor)
    local obj = setmetatable({gui = self, type = "switch"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.state = not not state
    obj.enableColor = enableColor or colors.lime
    obj.disableColor = disableColor or colors.gray
    obj.pointerColor = pointerColor or colors.white

    table.insert(self.objs, obj)
    return obj
end

function uix:createText(x, y, color, text)
    local obj = setmetatable({gui = self, type = "text"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.color = color
    obj.text = text

    table.insert(self.objs, obj)
    return obj
end



function uix:uploadEvent(eventData)
    if not eventData.windowEventData then
        eventData = self.window:uploadEvent(eventData)
    end

    for _, obj in ipairs(self.objs) do
        obj:uploadEvent(eventData)
    end
end

function uix:draw()
    for _, obj in ipairs(self.objs) do
        obj:draw()
    end
end

function uix.create(window, bgcolor)
    local guiobj = setmetatable({}, {__index = uix})
    guiobj.window = window
    guiobj.objs = {}

    if bgcolor then
        guiobj:createBg(bgcolor)
    end

    return guiobj
end

return uix