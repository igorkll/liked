local unicode = require("unicode")
local gui_container = require("gui_container")
local gui = require("gui")
local graphic = require("graphic")
local liked = require("liked")
local thread = require("thread")
local colors = gui_container.colors
local uix = {}
uix.styles = {
    "round",
    "square"
}

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
    if self.type == "button" or self.type == "context" then
        if self.state and (eventData[1] == "touch" or eventData[1] == "drop") then
            self.state = false
            self:draw()

            if self.onDrop then
                self:onDrop(eventData[5], eventData[6])
            end
        elseif not self.state and eventData[1] == "touch" and eventData[3] >= self.x and eventData[4] >= self.y and eventData[3] < self.x + self.sx and eventData[4] < self.y + self.sy then
            if self.type == "context" then
                self.state = true
                self:draw()

                local x, y = self.gui.window:toRealPos(self.x + 1, self.y + 1)
                local px, py, sx, sy = gui.contentPos(self.gui.window.screen, x, y, gui.contextStrs(self.strs))
                local clear = graphic.screenshot(self.gui.window.screen, px, py, sx + 2, sy + 1)
                local _, num = gui.context(self.gui.window.screen, px, py, self.strs, self.actives)
                clear()
                if num and self.funcs[num] then
                    self.funcs[num]()
                end

                self.state = false
                self:draw()
            else
                self.state = true
                self:draw()
                if self.autoRelease then
                    os.sleep(0.1)
                    self.state = false
                    self:draw()
                    graphic.forceUpdate()
                end
                
                if self.onClick then
                    self:onClick(eventData[5], eventData[6])
                end
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
    elseif self.type == "input" then
        self.read.uploadEvent(eventData)
        local text = self.read.getBuffer()
        if text ~= self.oldText then
            self.oldText = text
            if self.onTextChanged then
                self:onTextChanged(text)
            end
        end
    elseif self.type == "seek" then
        local function doSeek(oldValue)
            if self.value < 0 then self.value = 0 end
            if self.value > 1 then self.value = 1 end
            if self.onSeek then
                self:onSeek(self.value, oldValue)
            end
            self:draw()
        end

        if eventData[1] == "scroll" then
            if self.vertical then
                if self.globalScroll or (eventData[3] == self.x and eventData[4] >= self.y and eventData[4] < self.y + self.size) then
                    local oldValue = self.value
                    self.value = self.value - (eventData[5] / self.size)
                    doSeek(oldValue)
                end
            else
                if self.globalScroll or (eventData[4] == self.y and eventData[3] >= self.x and eventData[3] < self.x + self.size) then
                    local oldValue = self.value
                    self.value = self.value + (eventData[5] / self.size)
                    doSeek(oldValue)
                end
            end
        else
            if self.vertical then
                if eventData[1] == "touch" and eventData[3] == self.x and eventData[4] >= self.y and eventData[4] < self.y + self.size then
                    self.focus = true
                elseif eventData[1] == "drop" or eventData[1] == "touch" then
                    self.focus = false
                end
            else
                if eventData[1] == "touch" and eventData[4] == self.y and eventData[3] >= self.x and eventData[3] < self.x + self.size then
                    self.focus = true
                elseif eventData[1] == "drop" or eventData[1] == "touch" then
                    self.focus = false
                end
            end
            if (eventData[1] == "touch" or eventData[1] == "drag") and self.focus then
                local oldValue = self.value
                if self.vertical then
                    self.value = (eventData[4] - self.y) / (self.size - 1)
                else
                    self.value = (eventData[3] - self.x) / (self.size - 1)
                end
                doSeek(oldValue)
            end
        end
    end
end

function objclass:draw()
    if self.hidden then return end
    if self.type == "bg" then
        self.gui.window:clear(self.color)
    elseif self.type == "label" or self.type == "button" or self.type == "context" then
        local back, fore = self.back, self.fore
        if self.state then
            back, fore = self.back2 or back, self.fore2 or fore
        end

        local x, y, sx, sy = self.x, self.y, self.sx, self.sy
        
        if self.sy == 1 and self.gui.style == "round" then
            local _, _, bg = self.gui.window:get(x, y)
            self.gui.window:fill(x + 1, y, sx - 2, sy, back, 0, " ")
            self.gui.window:set(x, y, bg, back, "◖")
            self.gui.window:set(x + (sx - 1), y, bg, back, "◗")
        else
            self.gui.window:fill(x, y, sx, sy, back, 0, " ")
        end

        if self.text then
            local tx, ty = (x + math.round(sx / 2)) - math.round(unicode.len(self.text) / 2), y + (math.round(sy / 2) - 1)
            self.gui.window:set(tx, ty, back, fore, self.text)
        end
    elseif self.type == "switch" then
        local bg = self.state and self.enableColor or self.disableColor
        local _, _, fg = self.gui.window:get(self.x, self.y)

        if self.gui.style == "round" then
            self.gui.window:set(self.x, self.y, fg, bg, "◖████◗")
            if self.state then
                self.gui.window:set(self.x + 3, self.y, bg, self.pointerColor, "◖█")
                self.gui.window:set(self.x + 5, self.y, fg, self.pointerColor, "◗")
            else
                self.gui.window:set(self.x, self.y, fg, self.pointerColor, "◖")
                self.gui.window:set(self.x + 1, self.y, bg, self.pointerColor, "█◗")
            end
        else
            self.gui.window:set(self.x, self.y, fg, bg, "██████")
            if self.state then
                self.gui.window:set(self.x + 3, self.y, bg, self.pointerColor, "███")
            else
                self.gui.window:set(self.x, self.y, fg, self.pointerColor, "███")
            end
        end
    elseif self.type == "text" then
        if self.text then
            local _, _, bg = self.gui.window:get(self.x, self.y)
            self.gui.window:set(self.x, self.y, bg, self.color, self.text)
        end
    elseif self.type == "input" then
        local _, _, bg = self.gui.window:get(self.x, self.y)
        if self.gui.style == "round" then
            self.gui.window:set(self.x, self.y, bg, self.back, "◖")
            self.gui.window:set(self.x + (self.sx - 1), self.y, bg, self.back, "◗")
        end
        
        self.read.redraw()
    elseif self.type == "seek" then
        local _, _, bg = self.gui.window:get(self.x, self.y)
        local dotpos = math.round((self.size - 1) * self.value)

        if self.vertical then
            self.gui.window:fill(self.x, self.y, 1, dotpos, bg, self.fillColor, "┃")
            self.gui.window:fill(self.x, self.y + dotpos, 1, self.size - dotpos, bg, self.color, "┃")
            if self.gui.style == "round" then
                self.gui.window:set(self.x, self.y + dotpos, bg, self.dotcolor, "●")
            else
                self.gui.window:set(self.x, self.y + dotpos, bg, self.dotcolor, "█")
            end
        else
            self.gui.window:fill(self.x, self.y, dotpos, 1, bg, self.fillColor, gui_container.chars.wideSplitLine)
            self.gui.window:fill(self.x + dotpos, self.y, self.size - dotpos, 1, bg, self.color, gui_container.chars.wideSplitLine)
            if self.gui.style == "round" then
                if dotpos >= self.size - 1 then dotpos = dotpos - 1 end
                self.gui.window:set(self.x + dotpos, self.y, bg, self.dotcolor, "◖◗")
            else
                self.gui.window:set(self.x + dotpos, self.y, bg, self.dotcolor, "█")
            end
        end
    elseif self.type == "up" then
        liked.drawFullUpBar(self.gui.window.screen, self.title, self.withoutFill, self.bgcolor)
    elseif self.type == "plane" then
        self.gui.window:fill(self.x, self.y, self.sx, self.sy, self.color, 0, " ")
    elseif self.type == "image" then
        local x, y = self.gui.window:toRealPos(self.x, self.y)
        gui_drawimage(self.gui.window.screen, self.path, x, y, self.wallpaperMode)
    elseif self.type == "drawer" then
        self:func(self.gui.window:toRealPos(self.x, self.y))
    end
end

----------------------------------

function uix:createBg(color)
    local obj = setmetatable({gui = self, type = "bg"}, {__index = objclass})
    obj.color = color

    table.insert(self.objs, obj)
    return obj
end

function uix:createUpBar(title, withoutFill, bgcolor) --working only in fullscreen ui
    local obj = setmetatable({gui = self, type = "up"}, {__index = objclass})
    obj.title = title
    obj.withoutFill = withoutFill
    obj.bgcolor = bgcolor

    obj.close = self:createButton(self.window.sizeX, 1, 1, 1)
    obj.close.hidden = true

    --тут некоректно использовать таймер, так как он продолжит тикать даже если система приостановит программу для работы screensaver
    obj.thread = thread.create(function ()
        while true do
            obj:draw()
            os.sleep(10)
        end
    end)
    obj.thread:resume()

    local destroy = obj.destroy
    function obj:destroy()
        destroy(obj)
        obj.close:destroy()
    end

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

function uix:createButton(x, y, sx, sy, back, fore, text, autoRelease)
    local obj = setmetatable({gui = self, type = "button"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.back = back or colors.white
    obj.fore = fore or colors.gray
    obj.back2 = obj.fore
    obj.fore2 = obj.back
    obj.text = text
    obj.state = false
    obj.autoRelease = not not autoRelease

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
    obj.color = color or colors.white
    obj.text = text

    table.insert(self.objs, obj)
    return obj
end

function uix:createInput(x, y, sx, back, fore, hidden, default, syntax, maxlen, preStr, titleColor, title)
    local obj = setmetatable({gui = self, type = "input"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.back = back or colors.white
    obj.fore = fore or colors.gray
    obj.hidden = hidden
    obj.default = default
    obj.syntax = syntax
    obj.titleColor = titleColor or colors.lightGray
    obj.title = title

    if self.style == "round" then
        obj.read = self.window:readNoDraw(x + 1, y, sx - 2, obj.back, obj.fore, preStr, hidden, default, true, syntax)
    else
        obj.read = self.window:readNoDraw(x, y, sx, obj.back, obj.fore, preStr, hidden, default, true, syntax)
    end
    
    obj.oldText = obj.read.getBuffer()
    if maxlen then
        obj.read.setMaxStringLen(maxlen)
    end

    if obj.title then
        obj.read.setTitle(obj.title, obj.titleColor)
    end

    table.insert(self.objs, obj)
    return obj
end

function uix:createSeek(x, y, size, color, fillColor, dotcolor, value, vertical, globalScroll)
    local obj = setmetatable({gui = self, type = "seek"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.size = size
    obj.color = color or colors.lightGray
    obj.fillColor = fillColor or colors.lime
    obj.dotcolor = dotcolor or colors.white
    obj.value = value or 0
    obj.vertical = not not vertical
    obj.globalScroll = not not globalScroll

    table.insert(self.objs, obj)
    return obj
end

function uix:createPlane(x, y, sx, sy, color)
    local obj = setmetatable({gui = self, type = "plane"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.color = color or colors.gray

    table.insert(self.objs, obj)
    return obj
end

function uix:createContext(x, y, sx, sy, back, fore, text, strs, funcs, actives)
    local obj = setmetatable({gui = self, type = "context"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.back = back or colors.white
    obj.fore = fore or colors.gray
    obj.back2 = obj.fore
    obj.fore2 = obj.back
    obj.text = text
    obj.state = false

    obj.strs = strs or {}
    obj.funcs = funcs or {}
    obj.actives = actives

    if not obj.actives then
        obj.actives = {}
        for i in ipairs(obj.strs) do
            obj.actives[i] = true
        end
    end

    table.insert(self.objs, obj)
    return obj
end

function uix:createImage(x, y, path, wallpaperMode)
    local obj = setmetatable({gui = self, type = "image"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.path = path
    obj.wallpaperMode = not not wallpaperMode

    table.insert(self.objs, obj)
    return obj
end

function uix:createDrawer(x, y, func)
    local obj = setmetatable({gui = self, type = "drawer"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.func = func

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
    if self.onRedraw then
        self:onRedraw()
    end
    for _, obj in ipairs(self.objs) do
        obj:draw()
    end
end

function uix.create(window, bgcolor, style)
    local guiobj = setmetatable({}, {__index = uix})
    guiobj.window = window
    guiobj.style = style or "round"
    guiobj.objs = {}
    guiobj.selected = false
    
    if bgcolor then
        guiobj:createBg(bgcolor)
    end

    return guiobj
end

uix.unloadable = true
return uix