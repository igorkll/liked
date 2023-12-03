local fs = require("filesystem")
local graphic = require("graphic")
local serialization = require("serialization")
local sysinit = require("sysinit")
local palette = {}

function palette.save(screen)
    local pal = {}
    for i = 0, 15 do
        pal[i] = graphic.getPaletteColor(screen, i)
    end
    return pal
end

function palette.set(screen, pal)
    for i = 0, 15 do
        if graphic.getPaletteColor(screen, i) ~= pal[i] then
            graphic.setPaletteColor(screen, i, pal[i])
        end
    end
end

function palette.fromFile(screen, path, noReg)
    if noReg then
        local pal = assert(serialization.load(path))
        for i = 0, 15 do
            if graphic.getPaletteColor(screen, i) ~= pal[i + 1] then
                graphic.setPaletteColor(screen, i, pal[i + 1])
            end
        end
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

function palette.setSystemPalette(path)
    if pcall(sysinit.applyPalette, path) then
        pcall(fs.copy, path, sysinit.initPalPath)
    else
        pcall(fs.copy, "/system/themes/classic.plt", sysinit.initPalPath)
        sysinit.applyPalette("/system/themes/classic.plt")
    end
end

palette.unloadable = true
return palette