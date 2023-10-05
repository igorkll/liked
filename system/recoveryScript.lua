if bootloader and bootloader.runlevel ~= "init" then
    error("to start, the kernel does not need to be initialized, please restart the device", 0)
end

local internet = component.proxy(component.list("internet")() or "")
if not internet then
    error("to start the installation, you need an Internet card", 0)
end

local function getInternetFile(url)
    local handle, data, result, reason = internet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge) 
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "unvalid address"
    end
end

computer.getBootAddress = computer.tmpAddress --временный костыль шоб утихамирить кривой установшик
assert(load(assert(getInternetFile("https://raw.githubusercontent.com/igorkll/likeOS/main/installer/maininstaller.lua"))))()