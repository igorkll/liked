# uix - library
## пример простой gui программы
```lua
local uix = require("uix")
local sound = require("sound")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

--------------------------------- layout 1

layout1 = ui:create("layout 1", uix.colors.black) --не глобальная переменная, она создаеться в _ENV в а likeOS _ENV это личная таблица для ващей программы, а глобалы находяться в _G

layout1.button1 = layout1:createButton(2, 2, 16, 1, uix.colors.white, uix.colors.red, "BEEP")
function layout1.button1:onClick()
    sound.beep(2000)
end
function layout1.button1:onDrop()
    sound.beep(1000)
end

layout1.button2 = layout1:createButton(2, 4, 16, 1, uix.colors.white, uix.colors.red, "layout 2", true)
function layout1.button2:onClick()
    ui:select(layout2)
end

--------------------------------- layout 2

layout2 = ui:create("layout 2", uix.colors.lightGray)
layout2:setReturnLayout(layout1)
layout2:createText(2, ry - 1, uix.colors.white, "LOLZ")

---------------------------------

ui:loop()
```