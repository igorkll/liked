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

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local currentVersion = liked.version()
local lastVersion

------------------------------------

local function updateSystem()
    if not lastVersion then
        gui_warn(screen, nil, nil, "connection problems\ntry again later")
    elseif gui_checkPassword(screen) and gui_yesno(screen, nil, nil, currentVersion ~= lastVersion and "start updating now?" or "you have the latest version installed. do you still want to start updating?") then
        --assert(fs.copy(paths.concat(system.getSelfScriptPath(), "../update_init.lua"), "/init.lua"))

        local installdata = {branch = registry.branch}
        local updateinitPath = paths.concat(system.getSelfScriptPath(), "../update_init.lua")
        assert(fs.writeFile("/init.lua", "local installdata = " .. serialization.serialization(installdata) .. "\n" .. assert(fs.readFile(updateinitPath))))
        computer.shutdown("fast")
    end
    redraw()
end

local function wipeUserData()
    if gui_checkPassword(screen) then
        if gui.pleaseType(screen, "WIPE") then
            if liked.assert(screen, fs.remove("/data")) then
                computer.shutdown("fast")
            end
        end
    end
    redraw()
end

------------------------------------

function redraw()
    window:clear(colors.black)
    window:set(2, 2, colors.lightGray, colors.black, "  WIPE USER DATA  ")
    window:set(2, 4, colors.lightGray, colors.black, "  UPDATE SYSTEM   ")

    window:set(21, 2, colors.black, colors.white, "current version: " .. currentVersion)
    window:set(21, 3, colors.black, colors.white, "last    version: loading...")
    graphic.forceUpdate()

    local function getLast()
        local lv, err = liked.lastVersion()
        if not lv then
            lv = err
        else
            lastVersion = lv
        end
        return lv
    end
    
    local str = "last    version: " .. (lastVersion or getLast() or "unknown")
    window:set(21, 3, colors.black, colors.white, "last    version:                     ")
    window:set(21, 3, colors.black, colors.white, str)
    graphic.forceUpdate()
end
redraw()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] >= 2 and windowEventData[3] <= 19 then
            if windowEventData[4] == 2 then
                wipeUserData()
            elseif windowEventData[4] == 4 then
                updateSystem()
            end
        end
    end
end