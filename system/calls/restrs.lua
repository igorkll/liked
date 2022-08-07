local calls = require("calls")

local str, max = ...
local strs = calls.call("split", str, "\n")
local newstrs = {}
for i, v in ipairs(strs) do
    local lnewstrs = calls.call("toPartsUnicode", v, max)
    for i, v in ipairs(lnewstrs) do
        table.insert(newstrs, v)
    end
end
return newstrs