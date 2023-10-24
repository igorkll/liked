local unicode = require("unicode")
local format = {}

function format.smartConcat()
    local smart = {}
    smart.buff = {}
    smart.idx = 0

    function smart.add(x, text)
        local len = unicode.len(text)
        local last = x + (len - 1)
        local index = 1
        for i = x, last do
            smart.buff[i] = unicode.sub(text, index, index)
            index = index + 1
        end
        if last > smart.idx then
            smart.idx = last
        end
    end

    function smart.makeSize(size)
        smart.idx = size
    end

    function smart.get()
        for i = 1, smart.idx do
            if not smart.buff[i] then
                smart.buff[i] = " "
            end
        end
        return table.concat(smart.buff)
    end

    return smart
end

format.unloadable = true
return format