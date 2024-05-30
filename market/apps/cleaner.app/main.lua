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
    "/MineOS",
    "/Applications",
    "/Extensions",
    "/Icons",
    "/Libraries",
    "/Localizations",
    "/Pictures",
    "/Screensavers",
    "/Temporary",
    "/Wallpapers",
    "/Users",
    "/Versions.cfg",
    "/OS.lua",
    "/Autosave.proj",
    "/mineOS.lua"
}

local normalRootFiles = {
    "/init.lua",
    "/vendor",
    "/system",
    "/data",
    "/bootmanager"
}

local trashRootFiles = {
    "/dev",
    "/mnt",
    "/Mounts"
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

    local isOpenOS = fs.exists("/vendor/apps/openOS.app")
    local isMineOS = fs.exists("/vendor/apps/mineOS.app")

    if not isOpenOS and exists(openOSfiles) then
        table.insert(list, "residual OpenOS files")
        table.insert(actions, function ()
            rmAll(openOSfiles)
        end)
    end

    if not isMineOS and exists(mineOSfiles) then
        table.insert(list, "residual MineOS files")
        table.insert(actions, function ()
            rmAll(mineOSfiles)
        end)
    end

    local ltrash = table.clone(trashRootFiles)
    local lnorm = table.clone(normalRootFiles)
    table.add(lnorm, openOSfiles)
    table.add(lnorm, mineOSfiles)
    for _, name in ipairs(fs.list("/mnt/root")) do
        local path = paths.concat("/", name)
        if not table.exists(lnorm, path) then
            table.insert(ltrash, path)
        end
    end
    if exists(ltrash) then
        table.insert(list, "junk files of the root directory")
        table.insert(actions, function ()
            rmAll(ltrash)
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

local notEnables = {
    "system cache"
}

local states = {}
local list, actions
local function updateList()
    list, actions = cleanList()
    layout.actionList.list = {}
    if #list > 0 then
        layout.actionList.list = {}
        for i, title in ipairs(list) do
            if states[title] == nil then
                states[title] = not table.exists(notEnables, title)
            end
            layout.actionList.list[i] = {title, states[title]}
        end
    end
end

layout = ui:create("Cleaner", uix.colors.black)
layout.actionList = layout:createCustom(2, 2, gobjs.checkboxgroup, rx - 2, ry - 4)
layout.cleanButton = layout:createButton(2, ry - 1, 16, 1, uix.colors.white, uix.colors.red, "clean", true)

function layout.actionList:onSwitch(_, title, state)
    states[title] = state
end

function layout.cleanButton:onClick()
    if #actions > 0 then
        if gui.yesno(screen, nil, nil, "are you sure you want to start cleaning the system?") then
            local clear = gui.saveZone(screen)
            gui.status(screen, nil, nil, "cleaning the system...")
            local used = fs.spaceUsed("/")
            for i, v in ipairs(actions) do
                if layout.actionList.list[i][2] then
                    v()
                end
            end
            clear()
            updateList()
            layout.actionList:draw()
            gui.done(screen, nil, nil, "cleaned: " .. tostring(math.roundTo((used - fs.spaceUsed("/")) / 1024)) .. "KB")
        end
    else
        gui.warn(screen, nil, nil, "cleaning of the system is not required")
    end
    ui:draw()
end

updateList()
ui:loop()