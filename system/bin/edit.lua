local fs = require("filesystem")
local unicode = require("unicode")
local calls = require("calls")

local screen, path = ...

------------------------------------

local lines = {}

local function saveFile()
    local file = fs.open(path, "w")
    for i, v in ipairs(lines) do
        file.write(v .. "\n")
    end
    file.close()
end

local function loadFile()
    local file = fs.open(path, "r")
    local data = file.readAll()
    file.close()
    lines = calls.call("split", data, "\n")
end

------------------------------------

