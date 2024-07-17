local vec = {}

------------------------------------- meta

vec.meta3 = {
    __index = vec,
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
    __index = vec,
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

local vecMathAdd = function(v1, v2) return v1 + v2 end
local vecMathSub = function(v1, v2) return v1 - v2 end
local vecMathMul = function(v1, v2) return v1 * v2 end
local vecMathDiv = function(v1, v2) return v1 / v2 end
local function vecMath(a, b, func)
    local aNum = type(a) == "number"
    if aNum then
        local v = a
        a = setmetatable({}, {__index = function() return v end})
    end
    if type(b) == "number" then
        local v = b
        b = setmetatable({}, {__index = function() return v end})
    end
    local ret = vec.vec()
    if aNum then
        for i, v in ipairs(b) do
            ret[i] = func(a[i], b[i])
        end
    else
        for i, v in ipairs(a) do
            ret[i] = func(a[i], b[i])
        end
    end
    return ret
end

vec.meta = {
    __index = vec,
    __add = function (a, b)
        return vecMath(a, b, vecMathAdd)
    end,
    __sub = function (a, b)
        return vecMath(a, b, vecMathSub)
    end,
    __mul = function (a, b)
        return vecMath(a, b, vecMathMul)
    end,
    __div = function (a, b)
        return vecMath(a, b, vecMathDiv)
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
        return vec.vec(table.unpack(self, 1, self.n))
    end,
    __tostring = function(self)
        return self:tostring()
    end
}

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
    return setmetatable(table.pack(...), vec.meta)
end

vec.unloadable = true
return vec