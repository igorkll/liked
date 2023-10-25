local parser = require("parser")
local graphic = require("graphic")
local fs = require("filesystem")
local unicode = require("unicode")
local rendUtils = {}

function rendUtils.drawEula(screen, px, py, sy, bg, path)
    local content = assert(fs.readFile(path))
    local gpu = graphic.findGpu(screen)

    if bg then
        gpu.setBackground(bg)
    end

    local function set(x, y, text)
        gpu.set(x + (px - 1), y + (py - 1), text)
    end

    local lines = {}
    for _, raw_line in ipairs(parser.toLinesLn(content, sy)) do
        local line = {size = 0}
        local isColor = false
        for _, part in ipairs(parser.split(unicode, line, "|")) do
            if isColor then
                table.insert(line, tonumber(part))
            else
                table.insert(line, part)
                line.size = line.size + unicode.len(part)
            end
            isColor = not isColor
        end
        table.insert(lines, line)
    end

    local color = 0xffffff
    gpu.setForeground(color)
    for y, line in ipairs(lines) do
        local cursorX = 1
        for _, part in ipairs(line) do
            if type(part) == "number" then
                gpu.setForeground(part)
            else
                set(cursorX - math.round(line.size / 2), y, part)
                cursorX = cursorX + unicode.len(part)
            end
        end
    end
end

rendUtils.unloadable = true
return rendUtils