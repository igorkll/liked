local uix = require("uix")
local sound = require("sound")
local gobjs = require("gobjs")
local gui = require("gui")
local paths = require("paths")
local fs = require("filesystem")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

---------------------------------

local openOSfiles = {
    "/dev",
    "/mnt",
    "/usr",
    "/home",
    "/etc",
    "/boot",
    "/lib",
    "/bin",
    "/autorun.lua",
    "/.autorun.lua",
    "/openOS.lua"
}

local mineOSfiles = {
    "/Mounts",
    "/MineOS",
    "/Applications",
    "/Extensions",
    "/Icons",
    "/Libraries",
    "/Localizations",
    "/Pictures",
    "/Screensavers",
    "/Temporary",
    "/Users",
    "/Versions.cfg",
    "/OS.lua",
    "/Autosave.proj",
    "/mineOS.lua"
}

local function rePath(path)
    return paths.concat("/mnt/root", path)
end

local function exists(lst)
    for i, v in ipairs(lst) do
        if fs.exists(rePath(v)) then
            return true
        end
    end
end

local function rmAll(lst)
    for i, v in ipairs(lst) do
        fs.remove(rePath(v))
    end
end


local function cleanList()
    local list, actions = {}, {}

    if not fs.exists("/vendor/apps/openOS.app.app") and exists(openOSfiles) then
        table.insert(list, "residual OpenOS files")
        table.insert(actions, function ()
            rmAll(openOSfiles)
        end)
    end

    if not fs.exists("/vendor/apps/mineOS.app") and exists(mineOSfiles) then
        table.insert(list, "residual MineOS files")
        table.insert(actions, function ()
            rmAll(mineOSfiles)
        end)
    end

    if fs.exists("/data/errorlog.log") then
        table.insert(list, "error log")
        table.insert(actions, function ()
            fs.remove("/data/errorlog.log")
        end)
    end

    if fs.exists("/data/cache") then
        table.insert(list, "system cache")
        table.insert(actions, function ()
            fs.remove("/data/cache")
        end)
    end

    return list, actions
end

---------------------------------

local list, actions
local function updateList()
    list, actions = cleanList()
    if #list > 0 then
        layout.actionList:setText(table.concat(list, "\n"))
    else
        layout.actionList:setText("cleaning of the system is not required")
    end
end

layout = ui:create("Cleaner", uix.colors.black)
layout.actionList = layout:createCustom(2, 4, gobjs.scrolltext, rx - 2, ry - 4)
layout.cleanButton = layout:createButton(2, 2, 16, 1, uix.colors.white, uix.colors.red, "clean", true)
function layout.cleanButton:onClick()
    if #actions > 0 then
        if gui.yesno(screen, nil, nil, "are you sure you want to start cleaning the system?") then
            local clear = gui.saveZone(screen)
            gui.status(screen, nil, nil, "cleaning the system...")
            local used = fs.spaceUsed("/")
            for i, v in ipairs(actions) do
                v()
            end
            clear()
            gui.done(screen, nil, nil, "It was cleaned up: " .. tostring(math.roundTo((used - fs.spaceUsed("/")) / 1024)) .. "KB")
            updateList()
        end
    else
        gui.warn(screen, nil, nil, "cleaning of the system is not required")
    end
    ui:draw()
end

updateList()
ui:loop()