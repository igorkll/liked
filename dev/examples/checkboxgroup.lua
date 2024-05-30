local uix = require("uix")
local gobjs = require("gobjs")
local sound = require("sound")

local ui = uix.manager(...)
local rx, ry = ui:zoneSize()
local layout = ui:create("checkboxgroup test", uix.colors.black)

local obj = layout:createCustom(2, 2, gobjs.checkboxgroup, rx - 2, ry - 2)

for i = 100, 2000 do
    table.insert(obj.list, {"freq " .. i, false})
end

obj:attachCallback(function (i, title, state)
    sound.beep(tonumber(title:sub(6, #title)) + (state and 0 or -50))
end)

ui:loop()