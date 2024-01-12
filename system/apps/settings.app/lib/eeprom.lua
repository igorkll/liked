local fs = require("filesystem")
local paths = require("paths")
local component = require("component")
local gui = require("gui")
local apps = require("apps")
local eeprom = {}
eeprom.paths = {"/data/firmware", "/vendor/firmware", "/system/firmware"}

function eeprom.list(screen)
    local labels, list = {}, {}
    for _, path in ipairs(eeprom.paths) do
        for _, file in ipairs(fs.list(path)) do
            local fullpath = paths.concat(path, file)

            local label = paths.hideExtension(file):gsub("_", " ")
            local data = ""
            local code = file

            if fs.isDirectory(fullpath) then
                label = fs.readFile(paths.concat(fullpath, "label.txt")) or label
                data = fs.readFile(paths.concat(fullpath, "data.txt")) or data
                code = paths.concat(fullpath, "code.lua")
            end

            table.insert(labels, label)
            table.insert(list, {label = label, data = data, code = code, makeData = function ()
                local datamakePath = paths.concat(fullpath, "data.lua")
                if fs.exists(datamakePath) then
                    local result = {apps.executeWithWarn(datamakePath, screen)}
                    if result[1] then
                        return tostring(result[2] or "")
                    end
                end
            end})
        end
    end
    return labels, list
end

function eeprom.menu(screen)
    local labels, list = eeprom.list(screen)
    local clear = gui.saveBigZone(screen)
    local num = gui.select(screen, nil, nil, "select firmware", labels)
    clear()
    if num and gui.pleaseType(screen, "FLASH", "flash eeprom") then
        eeprom.flash(screen, list[num])
    end
end

function eeprom.flash(screen, firmware)
    local eeprom = component.eeprom
    local data = firmware.makeData() or firmware.data or ""

    gui.status(screen, nil, nil, "flashing...")
    eeprom.set(assert(fs.readFile(firmware.code)))
    eeprom.setData(data)
    eeprom.setLabel(firmware.label or "UNKNOWN")
end

eeprom.unloadable = true
return eeprom