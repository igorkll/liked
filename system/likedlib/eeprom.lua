local fs = require("filesystem")
local paths = require("paths")
local component = require("component")
local gui = require("gui")
local apps = require("apps")
local eeprom = {}
eeprom.paths = {"/data/firmware", "/vendor/firmware", "/system/firmware"}

function eeprom.list(screen)
	local labels, list = {}, {}
	local pathsList = table.clone(eeprom.paths)
	for _, app in pairs(apps.list()) do
		if app.extern and app.extern.firmwares then
			table.insert(pathsList, paths.concat(app.path, "firmware"))
		end
	end
	for _, path in ipairs(pathsList) do
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
			table.insert(list, {label = label, data = data, code = code, makeData = function (hidden)
				local datamakePath = paths.concat(fullpath, "data.lua")
				if fs.exists(datamakePath) then
					local result = {apps.executeWithWarn(datamakePath, screen, nil, hidden)}
					if result[1] then
						return table.unpack(result, 2)
					end
				end
			end})
		end
	end
	return labels, list
end

function eeprom.find(label, screen)
	local _, list = eeprom.list(screen)
	for i, v in ipairs(list) do
		if v.label == label then
			return v
		end
	end
end

function eeprom.menu(screen)
	local labels, list = eeprom.list(screen)
	local clear = gui.saveBigZone(screen)
	local num = gui.select(screen, nil, nil, "select firmware", labels)
	clear()
	if num then
		eeprom.flash(screen, list[num])
	end
end

function eeprom.makeData(firmware, hidden)
	if firmware.makeData then
		return firmware.makeData(hidden)
	elseif firmware.data then
		return firmware.data
	end
	return ""
end

function eeprom.flash(screen, firmware, force)
	local data, appendData = eeprom.makeData(firmware)
	if data ~= true and (force or gui.pleaseType(screen, "FLASH", "flash eeprom")) then
		gui.status(screen, nil, nil, "flashing...")
		return eeprom.hiddenFlash(firmware, data, appendData)
	end
end

function eeprom.isFirmware(firmware)
	local componentEeprom = component.eeprom
	if componentEeprom.getLabel() == (firmware.label or "UNKNOWN") then
		local _, appendData = eeprom.makeData(firmware, true)
		local targetCode = (appendData or "") .. (firmware.rawCode or assert(fs.readFile(firmware.code)))
		return componentEeprom.get() == targetCode
	end
	return false
end

function eeprom.hiddenFlash(firmware, data, appendData)
	local afterFlash
	if not data or not appendData then
		local l1, l2, _afterFlash = eeprom.makeData(firmware, true)
		data = l1 or data
		appendData = l2 or appendData
		afterFlash = _afterFlash
	end
	local componentEeprom = component.eeprom
	local _, err = componentEeprom.set((appendData or "") .. (firmware.rawCode or assert(fs.readFile(firmware.code))))
	if err then
		return nil, err
	end
	componentEeprom.setData(data or "")
	componentEeprom.setLabel(firmware.label or "UNKNOWN")
	if afterFlash then
		afterFlash()
	end
	return true
end

eeprom.unloadable = true
return eeprom