local unicode = require("unicode")
local braille = {}

local function tnum(val)
    local bool = toboolean(val)
    return bool and 1 or 0
end

function braille.make(tbl)
    local a, b, c, d, e, f, g, h = tnum(tbl[1][1]), tnum(tbl[2][1]), tnum(tbl[3][1]), tnum(tbl[4][1]), tnum(tbl[1][2]), tnum(tbl[2][2]), tnum(tbl[3][2]), tnum(tbl[4][2])
    return unicode.char(10240 + 128*h + 64*d + 32*g + 16*f + 8*e + 4*c + 2*b + a)
end

function braille.parse(char)
    
end

braille.unloadable = true
return braille