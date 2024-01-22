local fs = require("filesystem")
local system = require("system")
local unicode = require("unicode")
local graphic = require("graphic")
local event = require("event")

local bitMapFonts = {}
bitMapFonts.defaultFontPath = system.getResourcePath("font.bin")
bitMapFonts.loaded = setmetatable({}, {__mode = "v"})
bitMapFonts.handlers = {}

----------------------------

local fontObj = {}

function fontObj:char(char)
	local index = self.list[char]
	if not index then
        return self.error
    end

    local charBinarySize = ((self.sx * self.sy) // 8)
    local charData = self.cache[char]
    if not charData then
        self.file.seek("set", index * charBinarySize)
        charData = self.file.read(charBinarySize)
        self.cache[char] = charData
    end
	
	local chartable = {""}
	for i = 1, charBinarySize do
		local byte = charData:byte(i)
		for i = 0, 7 do
			local bit = byte % 2 == 1
			byte = byte // 2
			chartable[#chartable] = chartable[#chartable] .. (bit and "1" or ".")
			if #chartable[#chartable] >= self.sx then
				table.insert(chartable, "")
			end
		end
	end
	return chartable
end

function fontObj:draw(gpu, x, y, color, text, scale)
    if type(gpu) == "string" then
        gpu = graphic.findGpu(gpu)
    end

    color = color or 0xffffff
    scale = scale or 1
    local ceilScale = math.ceil(scale)

    gpu.setBackground(color)
    for i = 1, unicode.len(text) do
        local char = self:char(unicode.sub(text, i, i))
        local pos = x + ((i - 1) * (self.sx + 1) * scale)
        for ypos = 1, self.sy do
            for xpos = 1, self.sx do
                if char[ypos]:sub(xpos, xpos) == "1" then
                    gpu.fill(pos + ((xpos - 1) * scale), y + ((ypos - 1) * scale), ceilScale, ceilScale, " ")
                end
            end
        end
    end
end

function fontObj:size()
    return self.sx, self.sy
end

function fontObj:destroy()
    bitMapFonts.loaded[self.path] = nil
    bitMapFonts.handlers[self.path] = nil
    self.list = {}
    self.file:close()
end

----------------------------

function bitMapFonts.load(path)
    path = path or bitMapFonts.defaultFontPath
    if bitMapFonts.loaded[path] then
        return bitMapFonts.loaded[path]
    end

    local obj = {}
    obj.sx = 4
    obj.sy = 6
    obj.list = {["9"] = 0, ["8"] = 1, [";"] = 2, [":"] = 3, ["="] = 4, ["<"] = 5, ["?"] = 6, [">"] = 7, ["A"] = 8, ["@"] = 9, ["C"] = 10, ["B"] = 11, ["E"] = 12, ["D"] = 13, ["G"] = 14, ["F"] = 15, ["I"] = 16, ["H"] = 17, ["K"] = 18, ["J"] = 19, ["M"] = 20, ["L"] = 21, ["O"] = 22, ["N"] = 23, ["Q"] = 24, ["P"] = 25, ["S"] = 26, ["R"] = 27, ["U"] = 28, ["T"] = 29, ["W"] = 30, ["V"] = 31, ["!"] = 32, [" "] = 33, ["#"] = 34, ["\""] = 35, ["%"] = 36, ["$"] = 37, ["'"] = 38, ["&"] = 39, [")"] = 40, ["("] = 41, ["+"] = 42, ["*"] = 43, ["-"] = 44, [","] = 45, ["/"] = 46, ["."] = 47, ["1"] = 48, ["0"] = 49, ["3"] = 50, ["2"] = 51, ["5"] = 52, ["4"] = 53, ["7"] = 54, ["6"] = 55, ["y"] = 56, ["x"] = 57, ["{"] = 58, ["z"] = 59, ["}"] = 60, ["~"] = 61, ["№"] = 62, ["Y"] = 63, ["X"] = 64, ["["] = 65, ["Z"] = 66, ["]"] = 67, ["\\"] = 68, ["_"] = 69, ["^"] = 70, ["a"] = 71, ["`"] = 72, ["c"] = 73, ["b"] = 74, ["e"] = 75, ["d"] = 76, ["g"] = 77, ["f"] = 78, ["i"] = 79, ["h"] = 80, ["k"] = 81, ["j"] = 82, ["m"] = 83, ["l"] = 84, ["o"] = 85, ["n"] = 86, ["q"] = 87, ["p"] = 88, ["s"] = 89, ["r"] = 90, ["u"] = 91, ["t"] = 92, ["w"] = 93, ["v"] = 94}
    obj.path = path
    obj.file = fs.open(obj.path, "rb")
    obj.cache = {}
    obj.error = {
        "1111",
        "1..1",
        "1..1",
        "1..1",
        "1111"
    }

    local font = setmetatable(obj, {__index = fontObj})
    bitMapFonts.loaded[font.path] = font
    bitMapFonts.handlers[font.path] = font.file
    return font
end

event.timer(4, function ()
    for path, handler in pairs(bitMapFonts.handlers) do
        if not bitMapFonts.loaded[path] then
            handler.close()
            bitMapFonts.handlers[path] = nil
        end
    end
end, math.huge)

return bitMapFonts