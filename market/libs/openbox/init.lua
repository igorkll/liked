local vmx = require("vmx")
local system = require("system")
local graphic = require("graphic")
local paths = require("paths")
local fs = require("filesystem")

local boxPath = system.getResourcePath("box")
local eepromPath = system.getResourcePath("eepromImage")
local openbox = {}

function openbox.run(screen, program)
    local vm = vmx.create(eepromPath)
    local gpuAddress = graphic.findGpuAddress(screen)
    fs.copy(program, paths.concat(boxPath, "autorun.lua"))
    graphic.gpuPrivateList[gpuAddress] = true
    vm.bindComponent(vmx.fromReal(gpuAddress))
    vm.bindComponent(vmx.fromReal(screen))
    local result = {vm.loop()}
    graphic.gpuPrivateList[gpuAddress] = nil
    return assert(table.unpack(result))
end

openbox.unloadable = true
return openbox