local fs = require("filesystem")
local registry = require("registry")
local gui = require("gui")
local paths = require("paths")
local liked = require("liked")
local graphic = require("graphic")
local screen, posX, posY, vfs, name = ...

local strs = {
    "  likeOS installer",
    "  liked",
    "  likedbox",
    "  likeOS (core only)",
    "  full cloning of the system  "
}
local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
local clear = graphic.screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
local str2, num2 = gui.context(screen, posX, posY, strs, {true, true, true, true, not registry.banSystemCloning})
clear()

if not str2 then
    return "cancel"
end

str2 = str2:sub(3, #str2)
local label = str2
if num2 == 4 then
    label = "likeOS"
elseif num2 == 5 then
    label = "self-system"
end

local clear2 = saveZone(screen)
if gui_yesno(screen, nil, nil, "install \"" .. label .. "\" to \"" .. name .. "\"?") then
    gui_status(screen, nil, nil, "installing \"" .. label .. "\" to \"" .. name .. "\"...")

    local target = "/mnt/tmpmount"
    local selfsys = "/mnt/selfsys"

    local rootfs = fs.get("/")

    ---------------------------------------------

    fs.umount(target)
    fs.umount(selfsys)

    local success, err = fs.mount(vfs, target)
    if not success then return nil, err end

    local success, err = fs.mount(rootfs, selfsys)
    if not success then return nil, err end

    ---------------------------------------------

    local function install_core()
        local success, err = fs.copy(paths.concat(selfsys, "init.lua"), paths.concat(target, "init.lua"))
        if not success then return nil, err end

        fs.remove(paths.concat(target, "system/core")) --удаляет старое ядра чтобы не было канфликтов версий и не оставалось лишних файлов
        return fs.copy(paths.concat(selfsys, "system/core"), paths.concat(target, "system/core"))
    end

    local function install_liked(box)
        local success, err = fs.copy(paths.concat(selfsys, "init.lua"), paths.concat(target, "init.lua"))
        if not success then return nil, err end

        fs.remove(paths.concat(target, "system")) --удаляет старую систему чтобы не было канфликтов версий и не оставалось лишних файлов
        if box then
            local systemFolder = paths.concat(selfsys, "system")
            local bl = {
                "installer",
                "likedbox",
                "screenSavers",
                "themes",
                "wallpapers",
                "icons",
                "bin",
                "autoruns",
                "recoveryScript.lua",
                "registry.dat",
                "market_urls_dev.txt",
                "market_urls_main.txt",
                "logo.lua"
            }
            
            local success, err =  fs.copy(systemFolder, paths.concat(target, "system"), function (from)
                for _, lpath in ipairs(bl) do
                    if paths.equals(paths.concat(systemFolder, lpath), from) then
                        return false
                    end
                end
                
                return true
            end)
            if not success then return nil, err end

            return fs.copy(paths.concat(systemFolder, "likedbox"), paths.concat(target, "system"))
        else
            return fs.copy(paths.concat(selfsys, "system"), paths.concat(target, "system"))
        end
    end

    local function install_installer()
        fs.remove(paths.concat(target, "system")) --удаляет старую систему чтобы не было канфликтов версий и не оставалось лишних файлов
        local success, err = install_core()
        if not success then return nil, err end
        return fs.copy(paths.concat(selfsys, "system/installer"), paths.concat(target, "system"))
    end

    ---------------------------------------------

    liked.umountAll()
    
    local success, err
    if num2 == 1 then
        success, err = install_installer()
    elseif num2 == 2 then
        success, err = install_liked()
    elseif num2 == 3 then
        success, err = install_liked(true)
    elseif num2 == 4 then
        success, err = install_core()
    elseif num2 == 5 then
        fs.remove(paths.concat(target, "system")) --удаляет старую систему чтобы не было канфликтов версий и не оставалось лишних файлов
        success, err = fs.copy(selfsys, target)
        label = rootfs.getLabel() or "liked"
    end
    

    if not success and not err then
        err = "unknown error"
    end

    if success then
        pcall(vfs.setLabel, label) --label может быть readonly(состояния label readonly полностью независимо от readonly на диске)
        --у loot дискет можно менять label хотя они readonly, а tmpfs не readonly но label менять нельзя(окозалось багом ocelot ну да ладно)
        --единсвенный кастыльный способ проверить являеться ли label readonly - это попытаться изменить его на точно такой же
        --в данном случаи если получиться изменить label то хорошо, а если не получиться то пофиг
    end

    liked.mountAll()

    ---------------------------------------------

    fs.umount(target)
    fs.umount(selfsys)
    return success, err
else
    clear2()
    return "cancel"
end