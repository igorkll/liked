local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local unicode = require("unicode")
local vkeyboard = {}

function vkeyboard.input(screen, splash)
    local rx, ry = graphic.getResolution(screen)
    local window = graphic.createWindow(screen, 5, ry - 20, rx - 8, 20)
    local layout = uix.create(window, uix.colors.lightGray, "square")

    local currentInput, returnVal = ""
    local inputLabel = layout:createLabel(2, 2, window.sizeX - 2, 1, uix.colors.gray, uix.colors.white)
    inputLabel.alignment = "left"
    local function doInput()
        inputLabel.text = (splash or "") .. "> " .. currentInput
        inputLabel:draw()
    end
    doInput()

    local esc = layout:createButton(2, 4, 5, 3, uix.colors.red, uix.colors.white, "ESC", true)
    function esc:onClick()
        returnVal = true
    end

    local back = layout:createButton(window.sizeX - 5, 4, 5, 3, uix.colors.red, uix.colors.white, "<")
    function back:onClick()
        currentInput = unicode.sub(currentInput, 1, unicode.len(currentInput) - 1)
        doInput()
    end

    local enter = layout:createButton(window.sizeX - 16, 4, 10, 3, uix.colors.red, uix.colors.white, "enter", true)
    function enter:onClick()
        returnVal = currentInput
    end

    local space = layout:createButton(3, window.sizeY - 4, window.sizeX - 3, 3, uix.colors.blue, uix.colors.white, "⣇" .. ("⣀"):rep(4) .. "⣸")
    function space:onClick()
        currentInput = currentInput .. " "
        doInput()
    end

    for i = 1, 10 do
        local char = i
        if i == 10 then
            i = 0
        end
        char = tostring(char)
        
        local num = layout:createButton(8 + ((i - 1) * 5), 4, window.sizeX - 3, 3, uix.colors.blue, uix.colors.white, char)
        function num:onClick()
            currentInput = currentInput .. char
            doInput()
        end
    end


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