local event = require("event")

function gcd(a,b)
	if b ~= 0 then
		return gcd(b, a % b)
	else
		return math.abs(a)
	end
end

function int(f)
    return math.floor(tonumber(f))
end

function ext_euclid(a,b)
    if b == 0 then
        return a,1,0
    end
    
    local d,s,t = ext_euclid(b, a % b)
    local t_ = s - int(a / b) * t
    
    return d,t,t_
end

function find_coprime(eul)
    local r
    repeat
        r = math.random(5, eul)
    until gcd(eul,r) == 1
    return r
end

function rsa(p,q)
    local N = p * q
    local eul = (p - 1) * (q - 1)
    local e = find_coprime(eul)
    local d_,s,t = ext_euclid(eul,e)
    local check = eul * s + e * t
    local d = t % eul
    local check2 = (e * d) % eul
    
    --[[
    print("check: "..check)
    print("check2: "..check2)
    
    print("-------------------------")
    print("private key: "..e.."#"..N)
    print("public key: "..d.."#"..N)
    ]]
    
    return e,d,N
end

function pow_mod(x,p,n)
    local temp = x
    for i=2,p do
        temp = temp * x % n
    end
    return temp
end

function rsa_encr(msg, e, N)
    local ret = ""
    for i = 1, #msg do
        local c = msg:sub(i,i)
        local ac = string.byte(c)
        local ec = pow_mod(ac,e,N)
        ret = ret .. ec .. "#"
        event.yield()
        
        --print(c.."("..ac..") -> "..ec)
    end
    return ret
end

local function localsplit(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function rsa_decr(msg, d, N)
    local ret = ""
    for i,v in ipairs(localsplit(msg:sub(1,-2),"#")) do
        local vn = tonumber(v)
        local dc = pow_mod(vn,d,N)
        local ac = string.char(dc)
        ret = ret .. ac
        event.yield()
        
        --print(vn.." -> "..dc.."("..ac..")")
    end
    return ret
end

--[[
local privateKey,publicKey,N = rsa(3539, 2729)
print("-------------------------")

local myString = "Marvin ist dumm!"
local encrypted = rsa_encr(myString, privateKey, N)
print("Encrypted '"..myString.."' -> "..encrypted)


local decrypted = rsa_decr(encrypted, publicKey, N)
print("Decrypted -> '"..decrypted.."'")
]]











--[[
require("rsa")
privateKey,publicKey,N = rsa.env.rsa(3539, 2729)
print("-------------------------")

myString = "Marvin ist dumm!"
encrypted = rsa.env.rsa_encr(myString, privateKey, N)
print("Encrypted '"..myString.."' -> "..encrypted)


decrypted = rsa.env.rsa_decr(encrypted, publicKey, N)
print("Decrypted -> '"..decrypted.."'")
]]

--[[
require("rsa")
encryptionKey, decryptionKey = rsa.new(233, 107)
lolz = rsa.encrypt("123", encryptionKey)
print(rsa.decrypt(lolz, decryptionKey))
]]

function parseKey(key)
    local parser = require("parser")
    local key, N = table.unpack(parser.split(string, key, {"#"}))
    return tonumber(key), tonumber(N)
end

functions = { --это всеравно не будет доступно за пределами библиотеки из за специфики ОС
    new = function (p, q)
        local encryptionKey, decryptionKey, N = rsa(p, q)
        return tostring(math.round(encryptionKey)) .. "#" .. tostring(math.round(N)), tostring(math.round(decryptionKey)) .. "#" .. tostring(math.round(N))
    end,
    decrypt = function (data, decryptionKey)
        local key, N = parseKey(decryptionKey)
        return rsa_decr(data, key, N)
    end,
    encrypt = function (data, encryptionKey)
        local key, N = parseKey(encryptionKey)
        return rsa_encr(data, key, N)
    end
}

lib = {env = _ENV, unloadable = true}

for name, func in pairs(functions) do --любое исключения в этих функциях - ненужная дрянь
    lib[name] = function (...)
        local result = {pcall(func, ...)}
        if result[1] then
            return table.unpack(result, 2)
        else
            return nil, "invalid input data"
        end
    end
end

return lib