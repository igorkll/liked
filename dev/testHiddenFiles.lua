local paths = require("paths")
local fs = require("filesystem")

for i = 1, 128 do
    local path = paths.concat("/data/userdata/htest", tostring(i) .. ".txt")
    fs.writeFile(path, "")
    if math.random(0, 1) == 0 then
        fs.setAttribute(path, "hidden", true)
    end
end