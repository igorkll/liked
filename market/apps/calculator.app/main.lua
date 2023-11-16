local uix = require("uix")
local ui = uix.manager(...)

local backgroundColor = uix.colors.white
local numTextColor = uix.colors.black
local buttonBackgroundColor = uix.colors.lightGray
local buttonTextColor = uix.colors.white

local rx, ry = ui:size()
local layout = ui:create("Calculator", backgroundColor, uix.styles[2])
local mathLabel = layout:createLabel(2, 2, rx - 2, 1, backgroundColor, numTextColor)
local resultLabel = layout:createLabel(2, 3, rx - 2, 1, backgroundColor, numTextColor)

local current = ""

local function doCurrent()
    mathLabel.text = current
    mathLabel.alignment = "right"
    mathLabel:draw()

    local code = load("return (" .. current .. ")", "=math", "t", {})
    if code then
        local result = {pcall(code)}
        if result[1] then
            resultLabel.text = tostring(result[2])
        else
            resultLabel.text = "ERR"
        end
    else
        resultLabel.text = "0"
    end
    resultLabel.alignment = "right"
    resultLabel:draw()
end

local function addButton(x, y, color, textcolor, char, func)
    local button = layout:createButton(x * 16, (y * 5) + 5, 16, 5, color, textcolor, char)

    if color == buttonBackgroundColor then
        button.back = uix.colors.gray
    else
        button.back = uix.colors.black
    end

    if func then
        button.onClick = func
    else
        function button:onClick()
            current = current .. char
            doCurrent()
        end
    end
    return button
end

addButton(0, 0, buttonBackgroundColor, buttonTextColor, "7")
addButton(1, 0, buttonBackgroundColor, buttonTextColor, "8")
addButton(2, 0, buttonBackgroundColor, buttonTextColor, "9")

addButton(0, 1, buttonBackgroundColor, buttonTextColor, "4")
addButton(1, 1, buttonBackgroundColor, buttonTextColor, "5")
addButton(2, 1, buttonBackgroundColor, buttonTextColor, "6")

addButton(0, 2, buttonBackgroundColor, buttonTextColor, "1")
addButton(1, 2, buttonBackgroundColor, buttonTextColor, "2")
addButton(2, 2, buttonBackgroundColor, buttonTextColor, "3")

addButton(0, 3, uix.colors.gray, buttonTextColor, "0")
addButton(1, 3, uix.colors.gray, buttonTextColor, ".")
addButton(2, 3, uix.colors.gray, buttonTextColor, "")

addButton(3, 0, uix.colors.orange, buttonTextColor, "+")
addButton(3, 0, uix.colors.orange, buttonTextColor, "-")
addButton(3, 0, uix.colors.orange, buttonTextColor, "*")
addButton(3, 0, uix.colors.orange, buttonTextColor, "/")

ui:loop()