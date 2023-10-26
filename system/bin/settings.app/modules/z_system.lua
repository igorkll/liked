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

layout:createButton(2, 7, 16, 1, nil, nil, "WIPE USER DATA", true).onClick = function ()
    if gui_checkPassword(screen) and gui.pleaseType(screen, "WIPE") then
        if liked.assert(screen, fs.remove("/data")) then
            computer.shutdown("fast")
        end
    end
    layout:draw()
end

layout:createButton(20, 7, 16, 1, nil, nil, "UPDATE SYSTEM", true).onClick = function ()
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


layout:createText(9, 9, colors.white, "disable system recovery menu")
layout:createText(9, 11, colors.white, "disable startup logo")
layout:createText(9, 13, colors.white, "disable auto-reboot on system error")
local disableRecoverySwitch = layout:createSwitch(2, 9, registry.disableRecovery)
local disableLogoSwitch = layout:createSwitch(2, 11, registry.disableLogo)
local disableAutoReboot = layout:createSwitch(2, 13, registry.disableAutoReboot)

function disableRecoverySwitch:onSwitch()
    registry.disableRecovery = self.state
end

function disableLogoSwitch:onSwitch()
    registry.disableLogo = self.state
end

function disableAutoReboot:onSwitch()
    registry.disableAutoReboot = self.state
end


local function systemWeight()
    local _, initOnDisk = fs.size("/init.lua")
    local _, sysOnDisk = fs.size("/system")
    return math.round((initOnDisk + sysOnDisk) / 1024)
end

layout:createText(2, 2, colors.white, "current version: " .. currentVersion)
layout:createText(2, 4, colors.white, "current branch : " .. registry.branch)

local lastVersionText = layout:createText(2, 3, colors.white, "last    version: loading...")
local systemWeightLabel = layout:createText(2, 5, colors.white, "system  weight : calculation...")
layout:draw()
graphic.forceUpdate()
systemWeightLabel.text = "system  weight : " .. tostring(systemWeight()) .. "KB"
layout:draw()
graphic.forceUpdate()

lastVersion, lastVersionErr = liked.lastVersion()
if lastVersion then
    lastVersionText.text = "last    version: " .. lastVersion
else
    lastVersionText.text = "last    version: " .. lastVersionErr
end

layout:draw()
graphic.forceUpdate()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end