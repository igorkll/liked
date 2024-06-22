local modem
for address in component.list("modem", true) do
    if component.invoke(address, "isWireless") then
        if component.invoke(address, "setStrength", math.huge) >= 400 then
            modem = address
            break
        end
    end
end
if not modem then
    modem = component.list("modem", true)()
    if not modem then
        error("the modem was not found", 0)
    end
end
modem = component.proxy(modem)

local port = 38710
modem.close()
modem.open(port)