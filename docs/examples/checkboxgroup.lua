local uix = require("uix")
local gobjs = require("gobjs")
local sound = require("sound")

local ui = uix.manager(...)
local rx, ry = ui:zoneSize()
local layout = ui:create("checkboxgroup test", uix.colors.black)

local checkboxgroup = layout:createCustom(2, 2, gobjs.checkboxgroup, rx - 2, ry - 2)
checkboxgroup.bg = uix.colors.white
checkboxgroup.fg = uix.colors.black

for i = 100, 2000, 100 do
    table.insert(checkboxgroup.list, {"freq " .. i, false})
end

checkboxgroup:attachCallback(function (i, title, state)
    sound.beep(tonumber(title:sub(6, #title)) + (state and 0 or -50))
end)

ui:loop()