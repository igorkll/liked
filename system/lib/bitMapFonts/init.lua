local fs = require("filesystem")
local system = require("system")
local unicode = require("unicode")
local graphic = require("graphic")
local event = require("event")
local serialization = require("serialization")

local bitMapFonts = {}
bitMapFonts.defaultFontPath = system.getResourcePath("font.bin")
bitMapFonts.defaultFontTablePath = system.getResourcePath("font.tbl")
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

function fontObj:draw(callback, x, y, text, scale, color) --callback(x, y, scale, color)
    color = color or 0xffffff
    scale = scale or 1

    if type(callback) == "string" then
        local gpu = graphic.findGpu(callback)

        gpu.setBackground(color)
        callback = function(x, y, scale)
            gpu.fill(x, y, scale, scale, " ")
        end
    elseif type(callback) == "table" then
        local gpu = callback

        gpu.setBackground(color)
        callback = function(x, y, scale)
            gpu.fill(x, y, scale, scale, " ")
        end
    end

    local ceilScale = math.ceil(scale)
    for i = 1, unicode.len(text) do
        local char = self:char(unicode.sub(text, i, i))
        local pos = x + ((i - 1) * (self.sx + 1) * scale)
        for ypos = 1, self.sy do
            for xpos = 1, self.sx do
                if char[ypos]:sub(xpos, xpos) == "1" then
                    callback(pos + ((xpos - 1) * scale), y + ((ypos - 1) * scale), ceilScale, color)
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

function bitMapFonts.load(path, tblPath)
    path = path or bitMapFonts.defaultFontPath
    if bitMapFonts.loaded[path] then
        return bitMapFonts.loaded[path]
    end

    local obj = {}
    obj.list = assert(serialization.load(tblPath or bitMapFonts.defaultFontTablePath))
    obj.sx = obj.list.width
    obj.sy = obj.list.height
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