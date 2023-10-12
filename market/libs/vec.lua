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
    __len = function (vec)
        return vec:len()
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
    __len = function (vec)
        return vec:len()
    end
}

------------------------------------- methods

function vec:len()
    if self.z then
        return math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2)
    else
        return math.sqrt(self.x ^ 2 + self.y ^ 2)
    end
end

function vec:normalize()
    return self / #self
end

-------------------------------------

function vec.vec3(x, y, z)
    local vec3 = setmetatable({__index = vec}, vec.meta3)
    vec3.x = x
    vec3.y = y
    vec3.z = z
    return vec3
end

function vec.vec2(x, y)
    local vec2 = setmetatable({__index = vec}, vec.meta2)
    vec2.x = x
    vec2.y = y
    return vec2
end

vec.unloadable = true
return vec