local unicode = require("unicode")
local gui_container = require("gui_container")
local gui = require("gui")
local graphic = require("graphic")
local liked = require("liked")
local thread = require("thread")
local event = require("event")
local image = require("image")

local colors = gui_container.colors
local uix = {colors = colors}
uix.styles = {
    "round",
    "square"
}

---------------------------------- canvas

local canvasClass = {}

function canvasClass:onCreate(sx, sy, back, fore, char)
    self.back = back or colors.black
    self.fore = fore or colors.white
    self.char = char or " "
    self.sx = sx
    self.sy = sy
end

function canvasClass:draw()
    self.drawed = true
    if self.screenshot then
        self.screenshot()
        self.screenshot = nil
    else
        self.gui.window:fill(self.x, self.y, self.sx, self.sy, self.back, self.fore, self.char)
    end
end

function canvasClass:set(x, y, back, fore, text, vertical)
    if vertical then
        if x < 1 or x > self.sx then return end
        while y < 1 do
            y = y + 1
            text = unicode.sub(text, 2, unicode.len(text))
        end
        while y + (unicode.len(text) - 1) > self.sy do
            y = y - 1
            text = unicode.sub(text, 1, unicode.len(text) - 1)
        end
    else
        if y < 1 or y > self.sy then return end
        while x < 1 do
            x = x + 1
            text = unicode.sub(text, 2, unicode.len(text))
        end
        while x + (unicode.len(text) - 1) > self.sx do
            x = x - 1
            text = unicode.sub(text, 1, unicode.len(text) - 1)
        end
    end
    self.gui.window:set(self.x + (x - 1), self.y + (y - 1), back or self.back, fore or self.fore, text, vertical)
end

function canvasClass:fill(x, y, sx, sy, back, fore, text)
    self.gui.window:fill(self.x + (x - 1), self.y + (y - 1), sx, sy, back or self.back, fore or self.fore, text)
end

function canvasClass:centerText(x, y, back, fore, text, vertical)
    local offset = math.round(unicode.len(text) / 2) - 1
    if offset < 0 then offset = 0 end
    local offsetX, offsetY = offset, 0
    if vertical then
        offsetX, offsetY = offsetY, offsetX
    end
    self:set(x - offsetX, y - offsetY, back, fore, text, vertical)
end

function canvasClass:clear(color)
    self:fill(1, 1, self.sx, self.sy, color, 0, " ")
end

function canvasClass:stop()
    if self.drawed then
        local x, y = self.gui.window:toRealPos(self.x, self.y)
        self.screenshot = graphic.screenshot(self.gui.screen, x, y, self.sx, self.sy)
        self.drawed = nil
    end
end

function canvasClass:beforeRedraw()
    if self.drawed then
        local x, y = self.gui.window:toRealPos(self.x, self.y)
        self.screenshot = graphic.screenshot(self.gui.screen, x, y, self.sx, self.sy)
    end
end

---------------------------------- obj class

local objclass = {}

function objclass:destroy()
    if self.onDestroy then
        self:onDestroy()
    end
    
    for i = #self.gui.objs, 1, -1 do
        if self.gui.objs[i] == self then
            table.remove(self.gui.objs, i)
        end
    end
end

function objclass:stop()
    if self.type == "context" then
        self.state = false
        if self.th then
            self.th:kill()
            self.th = nil
        end
    elseif self.type == "button" then
        self.state = false
        if self.onDrop then
            self:onDrop()
        end
    end
end

function objclass:uploadEvent(eventData)
    if self.disabled then return end
    if self.type == "button" or self.type == "context" then
        if self.state and (eventData[1] == "touch" or eventData[1] == "drop") then
            if self.type ~= "context" then
                self.state = false
                self:draw()

                if self.onDrop then
                    self:onDrop(eventData[5], eventData[6], eventData)
                end
            end
        elseif not self.state and eventData[1] == "touch" and eventData[3] >= self.x and eventData[4] >= self.y and eventData[3] < self.x + self.sx and eventData[4] < self.y + self.sy then
            if self.type == "context" then
                self.state = true
                self:draw()

                if not self.th then
                    self.th = thread.create(function ()
                        local x, y = self.gui.window:toRealPos(self.x + 1, self.y + 1)
                        local px, py, sx, sy = gui.contentPos(self.gui.window.screen, x, y, gui.contextStrs(self.strs))
                        local clear = graphic.screenshot(self.gui.window.screen, px, py, sx + 2, sy + 1)
                        local oldControlLock = self.gui.controlLock
                        self.gui.controlLock = true
                        local _, num = gui.context(self.gui.window.screen, px, py, self.strs, self.actives)
                        self.gui.controlLock = oldControlLock
                        clear()
                        if num and self.funcs[num] then
                            self.funcs[num]()
                        end

                        self.state = false
                        self:draw()

                        self.th:suspend()
                        self.th = nil
                    end)
                    self.th:resume()
                end
            else
                self.state = true
                self:draw()
                graphic.forceUpdate(self.gui.window.screen)
                if self.autoRelease then
                    os.sleep(0.1)
                    self.state = false
                    self:draw()
                    graphic.forceUpdate(self.gui.window.screen)
                end
                
                if self.onClick then
                    self:onClick(eventData[5], eventData[6], eventData)
                end
            end
        end
    elseif self.type == "big_switch" then
        if eventData[1] == "touch" and eventData[3] >= self.x and eventData[3] < self.x + self.sizeX and eventData[4] >= self.y and eventData[4] < self.y + self.sizeY then
            self.state = not self.state
            self:draw()

            if self.onSwitch then
                self:onSwitch(eventData[5], eventData[6], eventData)
            end
        end
    elseif self.type == "switch" then
        local size = self.checkbox and 2 or 6
        if eventData[1] == "touch" and eventData[3] >= self.x and eventData[3] < self.x + size and eventData[4] == self.y then
            self.state = not self.state
            self:draw()

            if self.onSwitch then
                self:onSwitch(eventData[5], eventData[6], eventData)
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
    elseif self.type == "up" then
        if self.gui.returnLayout then
            local _, py = self.gui.window:toFakePos(1, 1)
            if eventData[1] == "touch" and eventData[3] >= 1 and eventData[3] <= 3 and eventData[4] == py then
                self.gui.returnLayout:select()
            end
        end
    elseif self.type == "seek" then
        local function doSeek(oldValue, isTouch)
            if self.value < 0 then self.value = 0 end
            if self.value > 1 then self.value = 1 end
            if self.onSeek then
                self:onSeek(self.value, oldValue, isTouch)
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
                doSeek(oldValue, true)
            end
        end
    end
end

function objclass:draw()
    if self.hidden then return end
    if self.type == "label" or self.type == "button" or self.type == "context" then
        local back, fore = self.back, self.fore
        if self.state then
            back, fore = self.back2 or back, self.fore2 or fore
        end

        local x, y, sx, sy = self.x, self.y, self.sx, self.sy
        
        local isRound = self.sy == 1 and self.gui.style == "round"
        if isRound then
            local _, _, bg = self.gui.window:get(x, y)
            self.gui.window:fill(x + 1, y, sx - 2, sy, back, 0, " ")
            self.gui.window:set(x, y, bg, back, "◖")
            self.gui.window:set(x + (sx - 1), y, bg, back, "◗")
        else
            self.gui.window:fill(x, y, sx, sy, back, 0, " ")
        end

        if self.text then
            local tx
            local ty = y + (math.round(sy / 2) - 1)
            if self.alignment == "left" then
                tx = x
                if isRound then
                    tx = tx + 1
                end
            elseif self.alignment == "right" then
                tx = (x + sx) - unicode.len(self.text)
                if isRound then
                    tx = tx - 1
                end
            else
                tx = (x + math.round(sx / 2)) - math.round(unicode.len(self.text) / 2)
            end
            self.gui.window:set(tx, ty, back, fore, self.text)
        end
    elseif self.type == "switch" then
        local bg = self.state and self.enableColor or self.disableColor
        local _, _, fg = self.gui.window:get(self.x, self.y)

        if self.checkbox then
            if self.gui.style == "round" then
                self.gui.window:set(self.x, self.y, self.pointerColor, bg, "◖◗")
            else
                self.gui.window:set(self.x, self.y, self.pointerColor, bg, "⠰⠆")
            end
        else
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
        end
    elseif self.type == "big_switch" then
        self.gui.window:fill(self.x, self.y, self.sizeX, self.sizeY, self.color, 0, " ")
        local x, y = self.gui.window:toRealPos(self.x, self.y)
        image.draw(self.gui.window.screen, self.state and "/system/images/switch_on.t2p" or "/system/images/switch_off.t2p", x, y, true)
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
        liked.drawFullUpBar(self.gui.window.screen, (self.gui.returnLayout and "   " or "") .. self.title, self.withoutFill, self.bgcolor, self.wide)
        if self.gui.returnLayout then
            local px, py = self.gui.window:toFakePos(1, 1)
            self.gui.window:set(px, py, colors.red, colors.white, " < ")
        end
    elseif self.type == "plane" then
        self.gui.window:fill(self.x, self.y, self.sx, self.sy, self.color, 0, " ")
    elseif self.type == "image" then
        local x, y = self.gui.window:toRealPos(self.x, self.y)
        image.draw(self.gui.window.screen, self.path, x, y, self.wallpaperMode)
    elseif self.type == "drawer" then
        self:func(self.gui.window:toRealPos(self.x, self.y))
    elseif self.type == "progress" then
        local _, _, bg = self.gui.window:get(self.x, self.y)
        local pos = math.round(math.map(self.value, 0, 1, 0, self.sx))
        self.gui.window:fill(self.x + pos, self.y, self.sx - pos, 1, bg, self.back, gui_container.chars.splitLine)
        self.gui.window:fill(self.x, self.y, pos, 1, bg, self.fore, gui_container.chars.wideSplitLine)
    end

    if self.postDraw then
        self:postDraw()
    end
end

---------------------------------- layout methods

function uix:createUpBar(title, withoutFill, bgcolor) --working only in fullscreen ui
    local obj = setmetatable({gui = self, type = "up"}, {__index = objclass})
    obj.title = title
    obj.withoutFill = withoutFill
    obj.bgcolor = bgcolor
    obj.wide = true

    local px, py = self.window:toFakePos(self.window.sizeX, 1)
    obj.close = self:createButton(px - 2, py, 3, 1)
    obj.close.hidden = true

    --тут некоректно использовать таймер, так как он продолжит тикать даже если система приостановит программу для работы screensaver
    obj.thread = thread.create(function ()
        while true do
            os.sleep(10)
            if self.active then
                obj:draw()
            end
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

function uix:createUp(title, withoutFill, bgcolor)
    local upbar = self:createUpBar(title, withoutFill, bgcolor)

    function upbar.close.onClick()
        if self.smartGuiManager and self.smartGuiManager.onExit then
            self.smartGuiManager:onExit()
        else
            os.exit()
        end
    end

    return upbar
end
uix.createAutoUpBar = uix.createUp --legacy

function uix:createLabel(x, y, sx, sy, back, fore, text)
    local obj = setmetatable({gui = self, type = "label"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.text = text
    uix.doColor(obj, back, fore)
    obj.alignment = "center"

    table.insert(self.objs, obj)
    return obj
end

function uix:createButton(x, y, sx, sy, back, fore, text, autoRelease)
    local obj = setmetatable({gui = self, type = "button"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.sy = sy
    obj.text = text
    obj.state = false
    obj.autoRelease = not not autoRelease
    uix.doColor(obj, back, fore)
    obj.back2 = obj.fore
    obj.fore2 = obj.back
    obj.alignment = "center"

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

function uix:createCheckbox(...)
    local obj = self:createSwitch(...)
    obj.checkbox = true
    return obj
end

function uix:createBigSwitch(x, y, state, color)
    local obj = setmetatable({gui = self, type = "big_switch"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sizeX = 16
    obj.sizeY = 16
    obj.color = color or colors.gray
    obj.state = not not state

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
    obj.hidden = hidden
    obj.default = default
    obj.syntax = syntax
    obj.titleColor = titleColor or colors.lightGray
    obj.title = title
    uix.doColor(obj, back, fore)

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
    obj.alignment = "center"

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

function uix:createProgress(x, y, sx, fore, back, value)
    local obj = setmetatable({gui = self, type = "progress"}, {__index = objclass})
    obj.x = x
    obj.y = y
    obj.sx = sx
    obj.fore = fore or colors.lime
    obj.back = back or colors.blue
    obj.value = value or 0

    table.insert(self.objs, obj)
    return obj
end

function uix:createCustom(x, y, cls, ...)
    if not cls.destroy then
        cls.destroy = objclass.destroy
    end

    local obj = setmetatable({gui = self}, {__index = cls})
    obj.x = x
    obj.y = y
    obj.args = {...}

    if obj.onCreate then
        obj:onCreate(...)
    end

    table.insert(self.objs, obj)
    return obj
end

function uix:createCanvas(x, y, sx, sy, back, fore, char)
    return self:createCustom(x, y, canvasClass, sx, sy, back, fore, char)
end

function uix:setReturnLayout(returnLayout)
    self.returnLayout = returnLayout
end



function uix:uploadEvent(eventData)
    if self.controlLock or not self.active then return end

    if not eventData.windowEventData then
        eventData = self.window:uploadEvent(eventData)
    end

    if self.onEvent then
        self:onEvent(eventData)
    end

    for _, obj in ipairs(self.objs) do
        if obj.uploadEvent then
            obj:uploadEvent(eventData)
        end
    end
end

function uix:draw()
    if self.allowAutoActive then
        self.allowAutoActive = nil
        self.active = true
    end

    if not self.active then
        return
    end

    for _, obj in ipairs(self.objs) do
        if obj.beforeRedraw then
            obj:beforeRedraw()
        end
    end

    if self.bgcolor then
        self.window:clear(self.bgcolor)
    end

    if self.onRedraw then
        self:onRedraw()
    end

    for _, obj in ipairs(self.objs) do
        if obj.draw then
            obj:draw()
        end
    end
end

function uix:stop()
    for _, obj in ipairs(self.objs) do
        if obj.stop then
            obj:stop()
        end
    end
end

function uix:select()
    if self.smartGuiManager then
        self.smartGuiManager:select(self)
    end
end

---------------------------------- uix methods

function uix.doColor(obj, back, fore)
    obj.back = back or colors.white
    obj.fore = fore
    if not obj.fore then
        if back then
            if back == colors.white then
                obj.fore = colors.black
            else
                obj.fore = colors.white
            end
        else
            obj.fore = colors.gray
        end
    end
end

function uix.create(window, bgcolor, style)
    local guiobj = setmetatable({}, {__index = uix})
    guiobj.window = window
    guiobj.screen = window.screen
    guiobj.style = style or "round"
    guiobj.objs = {}
    guiobj.selected = false
    guiobj.bgcolor = bgcolor
    guiobj.controlLock = false
    guiobj.active = false
    guiobj.allowAutoActive = true

    return guiobj
end

function uix.createAuto(screen, title, bgcolor, style) --legacy
    local rx, ry = graphic.getResolution(screen)
    local window = graphic.createWindow(screen, 1, 1, rx, ry)

    local layout = uix.create(window, bgcolor or colors.black, style)
    layout:createUp(title)
    return layout
end

function uix.createLayout(screen, title, bgcolor, style)
    local rx, ry = graphic.getResolution(screen)
    local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)
    window.outsideEvents = true

    local layout = uix.create(window, bgcolor or colors.black, style)
    layout:createUp(title or liked.selfApplicationName())
    return layout
end

function uix.loop(guimanager, layout, func) --legacy manager
    function guimanager.select(newLayout)
        if layout then
            layout.active = false
            layout:stop()
        end
        layout = newLayout
        if layout then
            layout.active = true
        end
        layout:draw()
    end

    layout:draw()
    while true do
        local eventData = {event.pull()}
        layout:uploadEvent(eventData)
        if func then
            func(eventData)
        end
    end
end

---------------------------------- manager

local manager = {}

function manager:select(layout)
    if self.current then
        self.current.active = false
        self.current:stop()
    end

    self.current = layout
    self.current.smartGuiManager = self
    self.current.allowAutoActive = nil
    self.current.active = true
    self.current:draw()
end

function manager:loop()
    if self.firstLayout and not self.current then
        self:select(self.firstLayout)
    end

    while true do
        local eventData = {event.pull()}
        self.current:uploadEvent(eventData)

        if self.onEvent then
            self:onEvent(eventData)
        end
    end
end

function manager:create(...)
    local layout = uix.createLayout(self.screen, ...)
    layout.allowAutoActive = nil
    if not self.firstLayout then self.firstLayout = layout end
    return layout
end

function manager:size()
    return graphic.getResolution(self.screen)
end

function manager:zoneSize()
    if self.current then
        return self.current.window.sizeX, self.current.window.sizeY
    else
        local x, y = graphic.getResolution(self.screen)
        return x, y - 1
    end
end

function uix.manager(screen)
    return setmetatable({screen = screen}, {__index = manager})
end

----------------------------------

uix.unloadable = true
return uix