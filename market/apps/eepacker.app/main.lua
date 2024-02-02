local iowindows = require("iowindows")
local gui = require("gui")
local fs = require("filesystem")

local screen = ...

-------------------------------- functions

local function err(str)
    gui.warn(screen, nil, nil, str)
    os.exit()
end

-------------------------------- convert

local path = iowindows.selectfile(screen, "lua")
if not path then return end
local content = assert(fs.readFile(path))
local chars = {}
local usedChars = {}

for i = 1, #content do
    local char = content:sub(i, i)
    if not usedChars[char] then
        table.insert(chars, char)
        usedChars[char] = true
    end
end

if #chars > 64 then
    err("your file uses more than 64 different characters (" .. #chars .. ")")
end