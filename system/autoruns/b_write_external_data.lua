local fs = require("filesystem")
local paths = require("paths")
local calls = require("calls")
local computer = require("computer")

------------------------------------

fs.makeDirectory("/external-data")

local function write(key, value)
    local file = fs.open(paths.concat("/external-data", key .. ".dat"), "wb")
    if file then
        file.write(value)
        file.close()
    end
end

------------------------------------

if not vendor.doNotWriteExternalData then
    write("devivetype", calls.call("getDeviceType"))
    write("deviveaddress", computer.address())
end