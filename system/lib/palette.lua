local graphic = require("graphic")
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

palette.unloadable = true
return palette