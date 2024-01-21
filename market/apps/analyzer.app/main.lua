local uix = require("uix")
local gobjs = require("gobjs")
local serialization = require("serialization")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

--------------------------------- layout 1

layout1 = ui:create("analyzer", uix.colors.black)
layout1:createText(2, ry - 3, uix.colors.white, "hold down the \"shift\" and hold the right mouse button on the object")
layout1:createText(2, ry - 2, uix.colors.white, "of study with the tablet in your hands until the beep sounds.")
layout1:createText(2, ry - 1, uix.colors.white, "if you hold down the mouse button too not long, the tablet will turn off")

layout1.clrButton = layout1:createButton(2, 2, 16, 1, uix.colors.white, uix.colors.red, "clear")
layout1.textzone = layout1:createCustom(2, 4, gobjs.scrolltext, rx - 2, ry - 8)

function layout1.clrButton:onClick()
    layout1.textzone:setText("")
    layout1.textzone:draw()
end

layout1:listen("tablet_use", function (_, data)
    if type(data) == "table" then
        data = serialization.serialize(data, 1024)
    else
        data = tostring(data or "error")
    end

    layout1.textzone:setText(data)
    layout1.textzone:draw()
end)

---------------------------------

ui:loop()