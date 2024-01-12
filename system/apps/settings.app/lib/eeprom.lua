local fs = require("filesystem")
local paths = require("paths")
local component = require("component")
local gui = require("gui")
local eeprom = {}
eeprom.paths = {"/data/firmware", "/vendor/firmware", "/system/firmware"}

function eeprom.list()
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
            table.insert(list, {label = label, data = data, code = code})
        end
    end
    return labels, list
end

function eeprom.menu(screen)
    local labels, list = eeprom.list()
    local num = gui.select(screen, nil, nil, "select firmware", labels)
    if num and gui.pleaseType(screen, "FLASH", "flash eeprom") then
        gui.status(screen, nil, nil, "flashing...")
        eeprom.flash(list[num])
    end
end

function eeprom.flash(firmware)
    local eeprom = component.eeprom
    eeprom.set(assert(fs.readFile(firmware.code)))
    eeprom.setData(firmware.data or "")
    eeprom.setLabel(firmware.label or "UNKNOWN")
end

eeprom.unloadable = true
return eeprom