local fs = require("filesystem")
local calls = require("calls")
local unicode = require("unicode")
local paths = require("paths")
local gui_container = {}

--------------------------------------------

gui_container.colors = {}
gui_container.indexsColors = {}

_G.gui_container = gui_container
if fs.exists("/data/theme.plt") then
    calls.call("system_applyTheme", "/data/theme.plt")
else
    calls.call("system_setTheme", "/system/themes/classic.plt")
end
_G.gui_container = nil

--------------------------------------------

gui_container.defaultUserRoot = "/data/userdata/"

gui_container.userRoot = {} --{screen = path, ...}
gui_container.viewFileExps = {} --если адрес экрана сдесь равен true то разширения имен файлов не будут скрыты
gui_container.devModeStates = {} --легаси, и почти негде не используеться, dev-mode был удален из системы

gui_container.chars = {
    threeDots = "…",
    splitLine = "⎯"
}

gui_container.screenSaverPath = "/data/screenSaver.scrsv"

---------------------------- можете изменять из своего софта для конфигурирования поведения desktop

gui_container.noScreenSaver = {} --на этих экранах не сможет быть защумен screensaver пока ключ с uuid экрана имет значения true
gui_container.isScreenSaver = {} --значения для ващего экрана сдесь true когда на нем запущен screenSaver(true весит даже на окне ввода пароля после screenSaver)
gui_container.noBlockOnScreenSaver = {} --если вы сами перестаете ресовать во время screenSaver но при этом хотите не блокировать основной поток ващей программы то поставьте сделесь true для ващего монитора(не забудьте вернуть все наместо после заверщения работы программы)
gui_container.noInterrupt = {} --если вы не хотите чтобы комбинация ctrl+alt+c работала в ващей программе то поставьте сдесь true для ващего монитора(не забудьте вернуть все на место)

---------------------------- необходимо сканфигурировать это все, в своей програме для поддержки свого формата

gui_container.newCreate = { --структура {name, exp, allowCheck(), create(path)}
    {
        "system-dump",
        "afpx",
        function ()
            return true
        end,
        function (path)
            return require("archiver").pack("/", path)
        end
    }
}

gui_container.filesExps = { --дополнительные действия к файлам

}

gui_container.openVia = {

}

gui_container.typecolors = {
    ["app"] = gui_container.colors.red,
    ["lua"] = gui_container.colors.lime
}

gui_container.typenames = {
    ["t2p"] = "image",
    ["txt"] = "text",
    ["scrsv"] = "screensaver"
}

gui_container.knownExps = { --данные файлы не будет предложинно открыть в текстовом редакторе
    ["scrsv"] = true,   
    ["lua"] = true,
    ["app"] = true,
    ["t2p"] = true,
    ["plt"] = true,
    ["dat"] = true,
    ["cfg"] = true,
    ["log"] = true,
    ["txt"] = true --текстовому документу не нужно отдельная кнопка, он по умалчанию открываеться через редактор
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

function gui_container.shortPath(path, max)
    max = max - 1 --поправка на символ троиточия перед путом
    if #path > max then
        return gui_container.chars.threeDots .. path:sub((#path - max) + 1, #path)
    end
    return path
end

function gui_container.toUserPath(screen, path) --конвертирует рутовый путь в путь пользователя
    return paths.canonical(unicode.sub(path, unicode.len(gui_container.getUserRoot(screen)), unicode.len(path)))
end

function gui_container.checkPath(screen, path) --проверяет не вышел ли пользователь из своий папки
    local disk, diskPath = fs.get(path)
    local mountPoint = fs.mounts()[disk.address][2]
    local userPath = gui_container.getUserRoot(screen)
    local isUserPathRoot = paths.equals(userPath, "/")
    local diskUserDataPath = paths.concat(mountPoint, "data/userdata")

    if disk.address ~= fs.get("/").address and not isUserPathRoot and fs.exists(diskUserDataPath) and fs.isDirectory(diskUserDataPath) then
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

return gui_container