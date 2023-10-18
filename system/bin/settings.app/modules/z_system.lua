local graphic = require("graphic")
local gui_container = require("gui_container")
local computer = require("computer")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")
local serialization = require("serialization")
local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local uix = require("uix")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))
local layout = uix.create(window, colors.black)

local currentVersion = liked.version()
local lastVersion, lastVersionErr

------------------------------------

layout:createButton(2, 6, 16, 1, nil, nil, "WIPE USER DATA", true).onClick = function ()
    if gui_checkPassword(screen) and gui.pleaseType(screen, "WIPE") then
        if liked.assert(screen, fs.remove("/data")) then
            computer.shutdown("fast")
        end
    end
    layout:draw()
end

layout:createButton(20, 6, 16, 1, nil, nil, "UPDATE SYSTEM", true).onClick = function ()
    if not lastVersion then
        gui_warn(screen, nil, nil, "connection problems\ntry again later")
    elseif gui.pleaseCharge(screen, 80, "update") and gui.pleaseSpace(screen, 512, "update") and gui_checkPassword(screen) and gui_yesno(screen, nil, nil, currentVersion ~= lastVersion and "start updating now?" or "you have the latest version installed. do you still want to start updating?") then
        --assert(fs.copy(paths.concat(system.getSelfScriptPath(), "../update_init.lua"), "/init.lua"))

        local installdata = {branch = registry.branch}
        local updateinitPath = paths.concat(system.getSelfScriptPath(), "../update_init.lua")
        assert(fs.writeFile("/init.lua", "local installdata = " .. serialization.serialize(installdata) .. "\n" .. assert(fs.readFile(updateinitPath))))
        computer.shutdown("fast")
    end
    layout:draw()
end

layout:createText(2, 4, colors.white, "current branch : " .. registry.branch)

layout:createText(2, 2, colors.white, "current version: " .. currentVersion)
local lastVersionText = layout:createText(2, 3, colors.white, "last    version: loading...")
layout:draw()
graphic.forceUpdate()

lastVersion, lastVersionErr = liked.lastVersion()
if lastVersion then
    lastVersionText.text = "last    version: " .. lastVersion
else
    lastVersionText.text = "last    version: " .. lastVersionErr
end

layout:draw()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end