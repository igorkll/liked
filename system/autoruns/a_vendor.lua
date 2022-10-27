local fs = require("filesystem")
local programs = require("programs")

if fs.exists("/vendor/bin") then
    table.insert(programs.paths, "/vendor/bin")
end

local standart = {}

if fs.exists("/vendor/config.cfg") then
    _G.vendor = unserialization(getFile("/vendor/config.cfg"))
    for k, v in pairs(standart) do
        if not vendor[k] then
            vendor[k] = v
        end
    end
else
    _G.vendor = standart
end