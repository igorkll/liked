local vmx = require("vmx")
local system = require("system")
local graphic = require("graphic")

local boxPath = system.getResourcePath("box")
local eepromPath = system.getResourcePath("eepromImage")

local openbox = {}

function openbox.create(screen)
    local vm = vmx.create(eepromPath)
    vm.bindComponent()
    vm.loop()
end

openbox.unloadable = true
return openbox