local uix = require("uix")
local sound = require("sound")
local gobjs = require("gobjs")
local fs = require("filesystem")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

---------------------------------

local function cleanList()
    local list, actions = {}, {}

    if not fs.exists("/vendor/apps/openOS.app.app") and fs.exists("/lib") then
        table.insert(list, "residual OpenOS files")
        table.insert(actions, function ()
            fs.remove("/dev") --я знаю что это "виртуальные" директории, но они тоже могут создасться
            fs.remove("/mnt")

            fs.remove("/usr")
            fs.remove("/home")
            fs.remove("/etc")
            fs.remove("/boot")
            fs.remove("/lib")
            fs.remove("/bin")
            
            fs.remove("/autorun.lua")
            fs.remove("/.autorun.lua")
            fs.remove("/openOS.lua")
        end)
    end

    if not fs.exists("/vendor/apps/mineOS.app") and fs.exists("/OS.lua") then
        table.insert(list, "residual MineOS files")
        table.insert(actions, function ()
            fs.remove("/Mounts") --я знаю что это "виртуальные" директории, но они тоже могут создасться

            fs.remove("/MineOS")
            fs.remove("/Applications")
            fs.remove("/Extensions")
            fs.remove("/Icons")
            fs.remove("/Libraries")
            fs.remove("/Localizations")
            fs.remove("/Pictures")
            fs.remove("/Screensavers")
            fs.remove("/Temporary")
            fs.remove("/Users")
            fs.remove("/Versions.cfg")
            fs.remove("/OS.lua")

            fs.remove("/Autosave.proj")
            fs.remove("/mineOS.lua")
        end)
    end

    return list, actions
end

---------------------------------

local list, actions = cleanList()

layout = ui:create("Cleaner", uix.colors.gray)
layout.actionList = layout:createCustom(2, 2, gobjs.scrolltext, rx - 2, ry - 2)
layout.actionList:setText(table.concat(list, "\n"))
layout.cleanButton = layout:createButton(2, 2, 16, 1, uix.colors.white, uix.colors.red, "clean", true)
function layout.cleanButton:onClick()
    for i, v in ipairs(actions) do
        v()
    end
end

ui:loop()