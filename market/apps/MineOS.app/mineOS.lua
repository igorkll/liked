local function getFile(fs, path)
    local file, err = fs.open(path, "rb")
    if not file then return nil, err end

    local buffer = ""
    repeat
        local data = fs.read(file, math.huge)
        buffer = buffer .. (data or "")
    until not data
    fs.close(file)

    return buffer
end

local invoke = component.invoke
local eeprom = component.list("eeprom")()
local bootaddress = computer.getBootAddress()

--mineOS получает адрес загрузочного диска из eeprom.getData
--если у пользователя установлен eeprom в data которого находиться не только адрес загрузочного диска, все бы пошло по бараде
--данный код делает так, чтобы mineOS получала фейковый eeprom-data в котором будет только адрес загрузочного диска
--что обеспечит совместимость с всеми прошивками eeprom
function component.invoke(address, method, ...)
    if address == eeprom then
        if method == "getData" then
            return bootaddress
        else
            error("access denied", 2) --у mineOS не будет доступа к eeprom, чтобы исключить воздействия вирусов(кой таких в mineOS пално)
        end
    end

    local result = {pcall(invoke, address, method, ...)}
    if not result[1] then --для правильной обработки ошибок
        error(result[2], 2)
    else
        return table.unpack(result, 2)
    end
end

assert(load(assert(getFile(component.proxy(bootaddress), "/OS.lua")), "=init", nil, _ENV))()