local vec = {}

------------------------------------- meta

vec.meta3 = {
    __add = function (a, b)
        if type(a) == "number" then a = vec.vec3(a, a, a) end
        if type(b) == "number" then b = vec.vec3(b, b, b) end
        return vec.vec3(a.x + b.x, a.y + b.y, a.z + b.z)
    end,
    __sub = function (a, b)
        if type(a) == "number" then a = vec.vec3(a, a, a) end
        if type(b) == "number" then b = vec.vec3(b, b, b) end
        return vec.vec3(a.x - b.x, a.y - b.y, a.z - b.z)
    end,
    __mul = function (a, b)
        if type(a) == "number" then a = vec.vec3(a, a, a) end
        if type(b) == "number" then b = vec.vec3(b, b, b) end
        return vec.vec3(a.x * b.x, a.y * b.y, a.z * b.z)
    end,
    __div = function (a, b)
        if type(a) == "number" then a = vec.vec3(a, a, a) end
        if type(b) == "number" then b = vec.vec3(b, b, b) end
        return vec.vec3(a.x / b.x, a.y / b.y, a.z / b.z)
    end,
    __eq = function (a, b)
        return a.x == b.x and a.y == b.y and a.z == b.z
    end,
    __lt = function (a, b)
        local alen = type(a) == "number" and a or a:len()
        local blen = type(b) == "number" and b or b:len()
        return alen < blen
    end,
    __le = function (a, b)
        local alen = type(a) == "number" and a or a:len()
        local blen = type(b) == "number" and b or b:len()
        return alen <= blen
    end,
    __len = function (self)
        return self:len()
    end,
    __call = function (self)
        return vec.vec3(self.x, self.y, self.z)
    end,
    __tostring = function(self)
        return self:tostring()
    end
}

vec.meta2 = {
    __add = function (a, b)
        if type(a) == "number" then a = vec.vec2(a, a) end
        if type(b) == "number" then b = vec.vec2(b, b) end
        return vec.vec2(a.x + b.x, a.y + b.y)
    end,
    __sub = function (a, b)
        if type(a) == "number" then a = vec.vec2(a, a) end
        if type(b) == "number" then b = vec.vec2(b, b) end
        return vec.vec2(a.x - b.x, a.y - b.y)
    end,
    __mul = function (a, b)
        if type(a) == "number" then a = vec.vec2(a, a) end
        if type(b) == "number" then b = vec.vec2(b, b) end
        return vec.vec2(a.x * b.x, a.y * b.y)
    end,
    __div = function (a, b)
        if type(a) == "number" then a = vec.vec2(a, a) end
        if type(b) == "number" then b = vec.vec2(b, b) end
        return vec.vec2(a.x / b.x, a.y / b.y)
    end,
    __eq = function (a, b)
        return a.x == b.x and a.y == b.y
    end,
    __lt = function (a, b)
        local alen = type(a) == "number" and a or a:len()
        local blen = type(b) == "number" and b or b:len()
        return alen < blen
    end,
    __le = function (a, b)
        local alen = type(a) == "number" and a or a:len()
        local blen = type(b) == "number" and b or b:len()
        return alen <= blen
    end,
    __len = function (self)
        return self:len()
    end,
    __call = function (self)
        return vec.vec2(self.x, self.y)
    end,
    __tostring = function(self)
        return self:tostring()
    end
}

vec.meta = {
    __add = function (a, b)
        if type(a) == "number" then a = setmetatable({}, {__index = function() return a end}) end
        if type(b) == "number" then b = setmetatable({}, {__index = function() return b end}) end
        local ret = vec.vec()
        for i, v in ipairs(a) do
            ret[i] = a[i] + b[i]
        end
        return ret
    end,
    __sub = function (a, b)
        if type(a) == "number" then a = setmetatable({}, {__index = function() return a end}) end
        if type(b) == "number" then b = setmetatable({}, {__index = function() return b end}) end
        local ret = vec.vec()
        for i, v in ipairs(a) do
            ret[i] = a[i] - b[i]
        end
        return ret
    end,
    __mul = function (a, b)
        if type(a) == "number" then a = setmetatable({}, {__index = function() return a end}) end
        if type(b) == "number" then b = setmetatable({}, {__index = function() return b end}) end
        local ret = vec.vec()
        for i, v in ipairs(a) do
            ret[i] = a[i] * b[i]
        end
        return ret
    end,
    __div = function (a, b)
        if type(a) == "number" then a = setmetatable({}, {__index = function() return a end}) end
        if type(b) == "number" then b = setmetatable({}, {__index = function() return b end}) end
        local ret = vec.vec()
        for i, v in ipairs(a) do
            ret[i] = a[i] / b[i]
        end
        return ret
    end,
    __eq = function (a, b)
        for i, v in ipairs(a) do
            if b[i] ~= v then
                return false
            end
        end
        return true
    end,
    __lt = function (a, b)
        local alen = type(a) == "number" and a or a:len()
        local blen = type(b) == "number" and b or b:len()
        return alen < blen
    end,
    __le = function (a, b)
        local alen = type(a) == "number" and a or a:len()
        local blen = type(b) == "number" and b or b:len()
        return alen <= blen
    end,
    __len = function (self)
        return self:len()
    end,
    __call = function (self)
        return vec.vec(table.unpack(self))
    end,
    __tostring = function(self)
        return self:tostring()
    end
}

setmetatable(vec.meta3, {__index = vec})
setmetatable(vec.meta2, {__index = vec})
setmetatable(vec.meta, {__index = vec})

------------------------------------- methods

function vec:len()
    if self.z then
        return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
    elseif self.y then
        return math.sqrt(self.x ^ 2 + self.y ^ 2)
    else
        local sum = 0
        for i, v in ipairs(self) do
            sum = sum + (v ^ 2)
        end
        return math.sqrt(sum)
    end
end

function vec:normalize()
    return self / #self
end

function vec:tostring()
    local str = "vec<"
    if self.z then
        str = str .. "x: " .. self.x .. ", y: " .. self.y .. ", z: " .. self.z
    elseif self.y then
        str = str .. "x: " .. self.x .. ", y: " .. self.y
    else
        local flag = false
        for _, v in ipairs(self) do
            str = str .. (flag and ", " or "") .. v
            flag = true
        end
    end
    return str .. ">"
end

-------------------------------------

function vec.vec3(x, y, z)
    return setmetatable({x = x, y = y, z = z}, vec.meta3)
end

function vec.vec2(x, y)
    return setmetatable({x = x, y = y}, vec.meta2)
end

function vec.vec(...)
    return setmetatable({...}, vec.meta)
end

vec.unloadable = true
return vec