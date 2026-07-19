local adv = {}

function adv.dist2(x, y, x2, y2)
	return math.sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2))
end

function adv.dist3(x, y, z, x2, y2, z2)
	return math.sqrt(((x - x2) ^ 2) + ((y - y2) ^ 2) + ((z - z2) ^ 2))
end

function adv.dist(pos1, pos2)
	local sum = 0
	for k, v in pairs(pos1) do
		if type(v) == "number" then
			sum = sum + ((v - pos2[k]) ^ 2)
		end
	end
	return math.sqrt(sum)
end

adv.unloadable = true
return adv