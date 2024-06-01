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

local notEnablesByDefault = {
    "system cache"
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
    local list, removeLists = {}, {}

    local isOpenOS = fs.exists("/vendor/apps/openOS.app")
    local isMineOS = fs.exists("/vendor/apps/mineOS.app")

    if not isOpenOS and exists(openOSfiles) then
        table.insert(list, "residual OpenOS files")
        table.insert(removeLists, openOSfiles)
    end

    if not isMineOS and exists(mineOSfiles) then
        table.insert(list, "residual MineOS files")
        table.insert(removeLists, mineOSfiles)
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
        table.insert(removeLists, ltrash)
    end

    if fs.exists("/data/errorlog.log") then
        table.insert(list, "error log")
        table.insert(removeLists, {"/data/errorlog.log"})
    end

    if fs.exists("/data/cache") then
        table.insert(list, "system cache")
        table.insert(removeLists, {"/data/cache"})
    end

    return list, removeLists
end

local function formatSize(size)
    return tostring(math.roundTo(size / 1024, 1)) .. "KB"
end

local layout = ui:create("Cleaner", uix.colors.black)
layout.actionList = layout:createCustom(2, 2, gobjs.checkboxgroup, rx - 2, ry - 4)
layout.cleanButton = layout:createButton(2, ry - 1, 16, 1, uix.colors.white, uix.colors.red, "clean", true)

local states = {}
local list, removeLists
local function updateList()
    list, removeLists = cleanList()
    layout.actionList.list = {}
    if #list > 0 then
        layout.actionList.list = {}
        for i, title in ipairs(list) do
            if states[title] == nil then
                states[title] = not table.exists(notEnablesByDefault, title)
            end
            local size = 0
            for _, removePath in ipairs(removeLists[i]) do
                if fs.exists(removePath) then
                    size = size + select(2, fs.size(removePath))
                end
            end
            local num = formatSize(size)
            layout.actionList.list[i] = {title .. string.rep(" ", layout.actionList.sizeX - #title - 2 - #num) .. num, states[title], title}
        end
    end
end

function layout.actionList:onSwitch(i, _, state)
    states[layout.actionList.list[i][3]] = state
end

function layout.cleanButton:onClick()
    if #removeLists > 0 then
        if gui.yesno(screen, nil, nil, "are you sure you want to start cleaning the system?") then
            local clear = gui.saveZone(screen)
            gui.status(screen, nil, nil, "cleaning the system...")
            local used = fs.spaceUsed("/")
            for i, removeList in ipairs(removeLists) do
                if layout.actionList.list[i][2] then
                    for _, removePath in ipairs(removeList) do
                        fs.remove(removePath)
                    end
                end
            end
            clear()
            updateList()
            layout.actionList:draw()
            gui.done(screen, nil, nil, "cleaned: " .. formatSize(used - fs.spaceUsed("/")))
        end
    else
        gui.warn(screen, nil, nil, "cleaning of the system is not required")
    end
    ui:draw()
end

updateList()
ui:loop()