local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local unicode = require("unicode")
local vkeyboard = {}

local function postDraw(self)
    local bg = self.state and self.back2 or self.back
    self.gui.window:fill(self.x, self.y, self.sx, 1, uix.colors.lightGray, bg, "⣤")
    self.gui.window:fill(self.x, self.y + (self.sy - 1), self.sx, 1, bg, uix.colors.lightGray, "⣤")
end

function vkeyboard.input(screen, splash)
    local rx, ry = graphic.getResolution(screen)
    local window = graphic.createWindow(screen, 5, ry - 18, rx - 8, 18)
    local layout = uix.create(window, uix.colors.lightGray, "square")

    local currentInput, returnVal = ""
    local inputLabel = layout:createLabel(2, 2, window.sizeX - 2, 1, uix.colors.gray, uix.colors.white)
    inputLabel.alignment = "left"
    local function doInput()
        inputLabel.text = (splash or "") .. "> " .. currentInput .. "|"
        inputLabel:draw()
    end
    doInput()

    local esc = layout:createButton(2, 4, 5, 3, uix.colors.red, uix.colors.white, "ESC", true)
    esc.postDraw = postDraw
    function esc:onClick()
        returnVal = true
    end

    local back = layout:createButton(window.sizeX - 5, 4, 5, 3, uix.colors.red, uix.colors.white, "<")
    back.postDraw = postDraw
    function back:onClick()
        currentInput = unicode.sub(currentInput, 1, unicode.len(currentInput) - 1)
        doInput()
    end

    local enter = layout:createButton(window.sizeX - 16, 4, 10, 3, uix.colors.red, uix.colors.white, "enter", true)
    enter.postDraw = postDraw
    function enter:onClick()
        returnVal = currentInput
    end

    local space = layout:createButton(3, window.sizeY - 1, window.sizeX / 2, 1, uix.colors.blue, uix.colors.white, "⣇" .. ("⣀"):rep(4) .. "⣸")
    function space:onClick()
        currentInput = currentInput .. " "
        doInput()
    end

    local upperCase = layout:createCheckbox(40, window.sizeY - 1)
    layout:createText(43, window.sizeY - 1, nil, "Upper Case")

    local function addButton(index, y, char)
        local button = layout:createButton(8 + ((index - 1) * 4), 4 + (y * 3), 3, 3, uix.colors.blue, uix.colors.white, char)
        button.postDraw = postDraw
        function button:onClick()
            if upperCase.state then
                currentInput = currentInput .. char:upper()
            else
                currentInput = currentInput .. char
            end
            doInput()
        end
    end

    for i = 1, 10 do
        local char = i
        if i == 10 then
            char = 0
        end
        char = tostring(char)
        
        addButton(i, 0, char)
    end

    addButton(10, 0, "-")
    addButton(11, 0, "+")
    addButton(12, 0, "~")

    addButton(0, 1, "q")
    addButton(1, 1, "w")
    addButton(2, 1, "e")
    addButton(3, 1, "r")
    addButton(4, 1, "t")
    addButton(5, 1, "y")
    addButton(6, 1, "u")
    addButton(7, 1, "i")
    addButton(8, 1, "o")
    addButton(9, 1, "p")
    addButton(10, 1, "[")
    addButton(11, 1, "]")
    addButton(12, 1, "{")
    addButton(13, 1, "}")
    addButton(14, 1, "(")
    addButton(15, 1, ")")
    addButton(16, 1, "`")

    addButton(0, 2, "a")
    addButton(1, 2, "s")
    addButton(2, 2, "d")
    addButton(3, 2, "f")
    addButton(4, 2, "g")
    addButton(5, 2, "h")
    addButton(6, 2, "j")
    addButton(7, 2, "k")
    addButton(8, 2, "l")
    addButton(9, 2, ";")
    addButton(10, 2, "'")
    addButton(11, 2, ":")
    addButton(12, 2, "\"")
    addButton(13, 2, "\\")
    addButton(14, 2, "|")
    addButton(15, 2, "/")
    addButton(16, 2, "!")

    addButton(0, 3, "z")
    addButton(1, 3, "x")
    addButton(2, 3, "c")
    addButton(3, 3, "v")
    addButton(4, 3, "b")
    addButton(5, 3, "n")
    addButton(6, 3, "m")
    addButton(7, 3, "<")
    addButton(8, 3, ">")
    addButton(9, 3, "?")
    addButton(10, 3, "@")
    addButton(11, 3, "#")
    addButton(12, 3, "$")
    addButton(13, 3, "%")
    addButton(14, 3, "^")
    addButton(15, 3, "&")
    addButton(16, 3, "*")

    layout:draw()

    while true do
        local eventData = {event.pull()}
        local windowEventData = window:uploadEvent(eventData)
        layout:uploadEvent(windowEventData)

        if returnVal then
            if returnVal == true then
                return
            else
                return returnVal
            end
        end
    end
end

vkeyboard.unloadable = true
return vkeyboard