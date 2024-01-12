local uix = require("uix")
local unicode = require("unicode")
local ui = uix.manager((...))

local backgroundColor = uix.colors.white
local numTextColor = uix.colors.black
local buttonBackgroundColor = uix.colors.lightGray
local buttonTextColor = uix.colors.white

local rx, ry = ui:size()
local layout = ui:create("Calculator", backgroundColor, uix.styles[2])
layout:createPlane(1, 5, rx, ry - 4, uix.colors.black)
local mathLabel = layout:createLabel(2, 2, rx - 2, 1, backgroundColor, numTextColor)
local resultLabel = layout:createLabel(2, 3, rx - 2, 1, backgroundColor, numTextColor)

local current = ""

local history = {}
local function saveToHistory()
    if history[#history] ~= current then
        table.insert(history, current)
    end
end

local function doCurrent()
    if unicode.len(current) == 0 then
        mathLabel.text = "0"
    else
        mathLabel.text = current
    end
    mathLabel.alignment = "right"
    mathLabel:draw()

    local code = load("return (" .. current .. ")", "=math", "t", {PI = math.pi, round = math.round})
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

doCurrent()

local function addButton(x, y, color, textcolor, char, func, xoffset)
    local button = layout:createButton((x * 16) + (xoffset or 0), (y * 5) + 5, 16, 5, color, textcolor, char)

    if color == buttonBackgroundColor then
        button.back2 = uix.colors.gray
    elseif color == uix.colors.orange then
        button.back2 = uix.colors.brown
    elseif color == uix.colors.red then
        button.back2 = uix.colors.brown
    elseif color == uix.colors.cyan then
        button.back2 = uix.colors.blue
    else
        button.back2 = uix.colors.black
    end

    if func then
        button.onClick = func
    else
        function button:onClick()
            saveToHistory()
            if tonumber(char) or char == "." then
                current = current .. char
            else
                current = current .. " " .. char .. " "
            end
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

addButton(0, 3, buttonBackgroundColor, buttonTextColor, "0")
addButton(1, 3, uix.colors.gray, buttonTextColor, ".")
addButton(2, 3, uix.colors.gray, buttonTextColor, "=", function ()
    saveToHistory()
    current = resultLabel.text
    doCurrent()
end)

addButton(3, 0, uix.colors.orange, buttonTextColor, "+", nil, 1)
addButton(3, 1, uix.colors.orange, buttonTextColor, "-", nil, 1)
addButton(3, 2, uix.colors.orange, buttonTextColor, "*", nil, 1)
addButton(3, 3, uix.colors.orange, buttonTextColor, "/", nil, 1)

addButton(4, 0, uix.colors.red, buttonTextColor, "AC", function ()
    saveToHistory()
    current = ""
    doCurrent()
end, 1)
addButton(4, 1, uix.colors.red, buttonTextColor, "<", function ()
    local finded
    for i = 1, #history do
        finded = table.remove(history)
        if finded ~= current then
            break
        end
    end
    if finded then
        current = finded
        doCurrent(true)
    end
end, 1)

addButton(4, 2, uix.colors.cyan, buttonTextColor, "()", function ()
    saveToHistory()
    current = "(" .. current .. ")"
    doCurrent()
end, 1)
addButton(4, 3, uix.colors.cyan, buttonTextColor, "round", function ()
    saveToHistory()
    current = "round(" .. current .. ")"
    doCurrent()
end, 1)

ui:loop()