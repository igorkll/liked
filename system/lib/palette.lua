local fs = require("filesystem")
local graphic = require("graphic")
local serialization = require("serialization")
local sysinit = require("sysinit")
local palette = {}

function palette.save(screen)
    return graphic.getPalette(screen, true)
end

function palette.set(screen, pal)
    graphic.setPalette(screen, pal, true)
end

function palette.fromFile(screen, path, noReg)
    if noReg then
        local pal = assert(serialization.load(path))
        graphic.setPalette(screen, pal)
    else
        pcall(sysinit.applyPalette, path, screen)
    end
end

function palette.system(screen, noReg)
    palette.fromFile(screen, sysinit.initPalPath, noReg)
end

function palette.blackWhite(screen, noReg)
    palette.fromFile(screen, "/system/t3default.plt", noReg)
end

function palette.setSystemPalette(path, regOnly)
    if pcall(sysinit.applyPalette, path) then
        pcall(fs.copy, path, sysinit.initPalPath)
    else
        pcall(fs.copy, sysinit.defaultPalettePath, sysinit.initPalPath)
        sysinit.applyPalette(sysinit.defaultPalettePath, regOnly)
    end
end

palette.unloadable = true
return palette