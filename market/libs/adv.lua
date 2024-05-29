local adv = {}

function adv.dist2(x, y, x2, y2)
    return math.sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2))
end

function adv.dist3(x, y, z, x2, y2, z2)
    return math.sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2) + ((z - z2) ^ 2))
end

adv.unloadable = true
return adv