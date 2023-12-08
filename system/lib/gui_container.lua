local gui_container = {}
gui_container.minRamForDBuff = 768
gui_container.criticalChargeLevel = 20

gui_container.colors = {}
gui_container.indexsColors = {}

--------------------------------------------

local fs = require("filesystem")
local unicode = require("unicode")
local paths = require("paths")

--------------------------------------------

gui_container.defaultUserRoot = "/data/userdata/"

gui_container.userRoot = {} --{screen = path, ...}
gui_container.viewFileExps = {} --если адрес экрана сдесь равен true то разширения имен файлов не будут скрыты
gui_container.devModeStates = {} --легаси, и почти негде не используеться, dev-mode был удален из системы
gui_container.unlockedDisks = {}

gui_container.chars = {
    threeDots = "…",
    splitLine = "⎯",
    wideSplitLine = "⠶",
    dot = "●"
}

gui_container.screenSaverPath = "/data/screenSaver.scrsv"

---------------------------- необходимо сканфигурировать это все, в своей програме для поддержки свого формата

gui_container.newCreate = { --структура {name, exp, allowCheck(), create(path)}
    {
        "system-dump",
        "afpx",
        function (path)
            return not fs.isReadOnly(path)
        end,
        function (path)
            return require("archiver").pack("/mnt/root", path)
        end
    }
}

gui_container.filesExps = { --дополнительные действия к файлам

}

gui_container.openVia = {
    ["afpx"] = "unpackArchive",
    ["reg"] = "applyReg"
}

gui_container.typecolors = { --тут косяк, политра может быть изменена а тут не измениться, и могут быть сбои при присвоения цвета. нала переделать на индексы палитры
    ["app"] = gui_container.colors.red,
    ["afpx"] = gui_container.colors.orange,
    ["lua"] = gui_container.colors.lime
}

gui_container.typenames = {
    ["t2p"] = "image",
    ["txt"] = "text",
    ["afpx"] = "archive",
    ["scrsv"] = "screensaver"
}

gui_container.knownExps = { --данные файлы не будет предложинно открыть в текстовом редакторе(если поставить editable то будет предложенно)
    ["scrsv"] = true,   
    ["lua"] = true,
    ["app"] = true,
    ["t2p"] = true,
    ["plt"] = true,
    ["dat"] = true,
    ["cfg"] = true,
    ["log"] = true,
    ["afpx"] = true,
    ["txt"] = true, --текстовому документу не нужно отдельная кнопка, он по умалчанию открываеться через редактор
    ["reg"] = true
}

gui_container.editable = { --вместо "open is text editor" будет писаться "edit"
    ["lua"] = true,
    ["scrsv"] = true,
    ["plt"] = true,
    ["reg"] = true
}

----------------------------

function gui_container.getUserRoot(screen)
    local path = gui_container.userRoot[screen] or gui_container.defaultUserRoot
    fs.makeDirectory(path)
    if path:sub(#path, #path) ~= "/" then
        return path .. "/"
    end
    return path
end

function gui_container.short(str, max)
    local len = unicode.len(str)
    if len > max then
        return gui_container.chars.threeDots .. unicode.sub(str, (len - max) + 2, len)
    end
    return str
end

function gui_container.toUserPath(screen, path) --конвертирует рутовый путь в путь пользователя
    return paths.canonical(unicode.sub(path, unicode.len(gui_container.getUserRoot(screen)), unicode.len(path)))
end

function gui_container.checkPath(screen, path) --проверяет не вышел ли пользователь из своий папки
    local userPath = gui_container.getUserRoot(screen)
    if unicode.sub(path, 1, unicode.len(userPath)) ~= userPath then
        return userPath
    end
    return path
end

--[[
function gui_container.checkPath(screen, path) --проверяет не вышел ли пользователь из своий папки
    local disk, diskPath = fs.get(path)
    local mountPoint = fs.mounts()[disk.address][2]
    local userPath = gui_container.getUserRoot(screen)
    local isUserPathRoot = paths.equals(userPath, "/")
    local diskUserDataPath = paths.concat(mountPoint, "data/userdata")
    local extdatPath = paths.concat(mountPoint, "external-data")

    if false and disk.address ~= fs.get("/").address and not isUserPathRoot and --отправленно на дороботку
    fs.exists(diskUserDataPath) and fs.isDirectory(diskUserDataPath) and
    fs.exists(extdatPath) and fs.isDirectory(extdatPath) then
        if paths.equals(diskPath, "/") then
            return paths.concat(mountPoint, userPath)
        elseif paths.equals(diskPath, paths.path(userPath)) then
            return userPath
        end
    else
        if unicode.sub(path, 1, unicode.len(userPath)) ~= userPath then
            return userPath
        end
    end
    return path
end

function gui_container.isDiskLocked(address) --отправленно на дороботку
    do return false end

    local regData = require("liked").getRegistry(address)
    return not not (regData and regData.password)
end

function gui_container.isDiskAccess(address)
    if not gui_container.isDiskLocked(address) then return true end
    return not not gui_container.unlockedDisks[address]
end

function gui_container.getDiskAccess(screen, address)
    if gui_container.isDiskLocked(address) then
        if require("gui").checkPasswordLoop(screen, nil, nil, nil, address) then
            gui_container.unlockedDisks[address] = true
        end
    end
end
]]

function gui_container.refresh()
    local registry = require("registry")
    for str, tbl in pairs(registry.gui_container or {}) do
        for key, value in pairs(tbl) do
            gui_container[str][key] = value
        end
    end

    local cache = require("cache")
    cache.cache.findIcon = nil
    cache.cache.getIcon = nil
end

return gui_container