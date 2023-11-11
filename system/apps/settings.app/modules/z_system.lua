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
local sysdata = require("sysdata")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))
local layout = uix.create(window, colors.black)

local currentVersion = liked.version()
local lastVersion, lastVersionErr

------------------------------------

layout:createButton(2, 8, 16, 1, nil, nil, "WIPE USER DATA", true).onClick = function ()
    if gui_checkPassword(screen) and gui.pleaseType(screen, "WIPE") then
        if liked.assert(screen, fs.remove("/data")) then
            computer.shutdown("fast")
        end
    end
    layout:draw()
end

local branch = sysdata.get("branch")
local currentMode = sysdata.get("mode")
local altBranch = branch == "main" and "dev" or "main"

local function update(newBranch)
    if not lastVersion then
        gui_warn(screen, nil, nil, "connection problems\ntry again later")
    elseif gui.pleaseCharge(screen, 80, "update") and gui.pleaseSpace(screen, 512, "update") and gui_checkPassword(screen) and gui_yesno(screen, nil, nil, newBranch and "ATTENTION, changing the branch can break the system! are you sure?" or (currentVersion ~= lastVersion and "start updating now?" or "you have the latest version installed. do you still want to start updating?")) then
        --assert(fs.copy(paths.concat(system.getSelfScriptPath(), "../update_init.lua"), "/init.lua"))

        local installdata = {branch = newBranch or branch, mode = currentMode}
        local updateinitPath = paths.concat(system.getSelfScriptPath(), "../update_init.lua")
        assert(fs.writeFile("/init.lua", "local installdata = " .. serialization.serialize(installdata) .. "\n" .. assert(fs.readFile(updateinitPath))))
        computer.shutdown("fast")
    end
    layout:draw()
end

layout:createButton(20, 8, 16, 1, nil, nil, "UPDATE SYSTEM", true).onClick = function ()
    update()
end

layout:createButton(25, 4, 16, 1, nil, nil, "UPDATE TO " .. altBranch:upper(), true).onClick = function ()
    update(altBranch)
end

layout:createText(9, 10, colors.white, "disable system recovery menu")
layout:createText(9, 12, colors.white, "disable startup logo")
layout:createText(9, 14, colors.white, "disable auto-reboot on system error")
local disableRecoverySwitch = layout:createSwitch(2, 10, registry.disableRecovery)
local disableLogoSwitch = layout:createSwitch(2, 12, registry.disableLogo)
local disableAutoReboot = layout:createSwitch(2, 14, registry.disableAutoReboot)

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
layout:createText(2, 4, colors.white, "current branch : " .. branch)
layout:createText(2, 5, colors.white, "current   mode : " .. currentMode)

local lastVersionText = layout:createText(2, 3, colors.white, "last    version: loading...")
local systemWeightLabel = layout:createText(2, 6, colors.white, "system  weight : calculation...")
layout:draw()
graphic.forceUpdate(screen)
systemWeightLabel.text = "system  weight : " .. tostring(systemWeight()) .. "KB"
layout:draw()
graphic.forceUpdate(screen)

lastVersion, lastVersionErr = liked.lastVersion()
if lastVersion then
    lastVersionText.text = "last    version: " .. lastVersion
else
    lastVersionText.text = "last    version: " .. lastVersionErr
end

layout:draw()
graphic.forceUpdate(screen)

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end