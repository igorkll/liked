local fs = require("filesystem")
local screen, posX, posY, vfs = ...

local clear = screenshot(screen, posX, posY, 23, 4)
local str2, num2 = gui_context(screen, posX, posY, {
    "  likeOS installer",
    "  liked",
    "  likeOS (core only)  "
}, {true, true, true})
clear()

if not str2 then
    return "cancel"
end

str2 = str2:sub(3, #str2)
local label = str2
if num2 == 3 then
    label = "likeOS"
end

local clear2 = saveZone(screen)
if gui_yesno(screen, nil, nil, "install \"" .. label .. "\"?") then
    gui_status(screen, nil, nil, "installing \"" .. label .. "\"...")

    fs.umount("/tmp/tmpmount")
    do
        local success, err = fs.mount(vfs, "/tmp/tmpmount")
        if not success then return nil, err end
    end

    local function selfclone(liked)
        local success, err = fs.copy("/init.lua", "/tmp/tmpmount/init.lua")
        if not success then return nil, err end
    
        local success, err = fs.copy("/system/core", "/tmp/tmpmount/system/core")
        if not success then return nil, err end
    
        if liked then
            local success, err = fs.copy("/system", "/tmp/tmpmount/system")
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
    end

    if not success and not err then
        err = "unknown error"
    end

    if success then
        pcall(vfs.setLabel, label) --label может быть readonly(состояния label readonly полностью независимо от readonly на диске)
        --у loot дискет можно менять label хотя они readonly, а tmpfs не readonly но label менять нельзя
        --единсвенный кастыльный способ проверить являеться ли label readonly - это попытаться изменить его на точно такой же
        --в данном случаи если получиться изменить label то хорошо, а если не получиться то пофиг
    end

    return success, err
else
    clear2()
    return "cancel"
end