local vmx = require("vmx")
local system = require("system")
local graphic = require("graphic")
local paths = require("paths")
local fs = require("filesystem")
local component = require("component")

local boxPath = system.getResourcePath("box")
local eepromPath = system.getResourcePath("eepromImage")
local openbox = {}

function openbox.run(screen, program)
    local gpuAddress = screen and graphic.findGpuAddress(screen)
    local vm = vmx.create(eepromPath, boxPath)
    fs.copy(program, paths.concat(boxPath, "autorun.lua"))
    
    if gpuAddress then
        component.invoke(gpuAddress, "setActiveBuffer", 0)
        graphic.gpuPrivateList[gpuAddress] = true
        vm.bindComponent(vmx.fromReal(gpuAddress))
    end
    if screen then
        vm.bindComponent(vmx.fromReal(screen))
    end
    
    local result = {vm.loop()}
    graphic.gpuPrivateList[gpuAddress] = nil
    graphic.findGpu(gpuAddress)
    return assert(table.unpack(result))
end

openbox.unloadable = true
return openbox