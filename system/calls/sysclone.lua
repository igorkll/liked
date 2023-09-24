local fs = require("filesystem")
local registry = require("registry")
local gui = require("gui")
local screen, posX, posY, vfs, name = ...

local strs = {
    "  likeOS installer",
    "  liked",
    "  likeOS (core only)",
    "  full cloning of the system  "
}
local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
local clear = screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
local str2, num2 = gui.context(screen, posX, posY, strs, {true, true, true, not registry.banSystemCloning})
clear()

if not str2 then
    return "cancel"
end

str2 = str2:sub(3, #str2)
local label = str2
if num2 == 3 then
    label = "likeOS"
elseif num2 == 4 then
    label = "self-system"
end

local clear2 = saveZone(screen)
if gui_yesno(screen, nil, nil, "install \"" .. label .. "\" to \"" .. name .. "\"?") then
    gui_status(screen, nil, nil, "installing \"" .. label .. "\" to \"" .. name .. "\"...")

    local rootfs = fs.get("/")
    do
        fs.umount("/tmp/tmpmount")
        local success, err = fs.mount(vfs, "/tmp/tmpmount")
        if not success then return nil, err end
    end

    local function selfclone(liked)
        local success, err = fs.copy("/init.lua", "/tmp/tmpmount/init.lua")
        if not success then return nil, err end
    
        if liked then --да сначала установиться liked, но и что, они всеравно не заменяют файлы друг-друга
            fs.remove("/tmp/tmpmount/system") --удаляет старую систему чтобы не было канфликтов версий и не оставалось лишних файлов
            local success, err = fs.copy("/system", "/tmp/tmpmount/system")
            if not success then return nil, err end
        else
            fs.remove("/tmp/tmpmount/system/core") --удаляет старое ядра чтобы не было канфликтов версий и не оставалось лишних файлов
            local success, err = fs.copy("/system/core", "/tmp/tmpmount/system/core")
            if not success then return nil, err end
        end
    
        return true
    end

    local success, err
    if num2 == 1 then
        success, err = selfclone()
        if success then
            success, err = fs.copy("/system/installer", "/tmp/tmpmount/system")
        end
    elseif num2 == 2 then
        success, err = selfclone(true)
    elseif num2 == 3 then
        success, err = selfclone()
    elseif num2 == 4 then
        fs.remove("/tmp/tmpmount/system") --удаляет старую систему чтобы не было канфликтов версий и не оставалось лишних файлов

        success, err = fs.copy("/", "/tmp/tmpmount", function (from)
            if from == "/external-data" then return false end
            return fs.get(from).address == rootfs.address
        end)
    end

    if not success and not err then
        err = "unknown error"
    end

    if success then
        if num2 == 4 then
            label = rootfs.getLabel() or "liked"
        end
        pcall(vfs.setLabel, label) --label может быть readonly(состояния label readonly полностью независимо от readonly на диске)
        --у loot дискет можно менять label хотя они readonly, а tmpfs не readonly но label менять нельзя(окозалось багом ocelot ну да ладно)
        --единсвенный кастыльный способ проверить являеться ли label readonly - это попытаться изменить его на точно такой же
        --в данном случаи если получиться изменить label то хорошо, а если не получиться то пофиг
    end

    return success, err
else
    clear2()
    return "cancel"
end