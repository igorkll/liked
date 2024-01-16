local component = require("component")
local gui = require("gui")
local graphic = require("graphic")
local glasses = {}

--------------------------------------- objects methods

function glasses:destroy(object)
    if self.type == 1 then
        object.delete()
    end
end

function glasses:set(object)
    if self.type == 1 then
        object.delete()
    end
end

--------------------------------------- glasses methods

function glasses:clear()
    if self.type == 1 then
        self.proxy:clear()
    end
end

function glasses:drawText(x, y, text, color)
    if self.type == 1 then
        return self.proxy:addText(x, y, text, color)
    end
end

function glasses:flush()
    if self.type == 1 then
        self.proxy:sync()
    end
end

--------------------------------------- advanced methods

function glasses:screenCapture(screen)
    local oldRx, oldRy
    local currentImageC = {}
    local currentImageF = {}
    local currentImageB = {}
    local objects = {}

    return function ()
        local gpu = graphic.findGpu(screen)
        local rx, ry = gpu.getResolution()
        if rx ~= oldRx or ry ~= oldRy then
            self:clear()
            oldRx, oldRy = rx, ry
            currentImageC = {}
            currentImageF = {}
            currentImageB = {}
        end
        for i = 0, (rx * ry) - 1 do
            local x, y = (i % rx) + 1, (i // ry) + 1
            local char, fore, back = gpu.get(x, y)
            if char ~= currentImageC[i] or fore ~= currentImageF[i] or back ~= currentImageB[i] then
                if objects[i] then
                    self:destroy(objects[i])
                end

                currentImageC[i] = char
                currentImageF[i] = fore
                currentImageB[i] = back
            end
        end

        self:flush()
    end
end

---------------------------------------

local glassesTypes = {"openperipheral_bridge"}

function glasses.get(screen)
    local address = gui.selectcomponent(screen, nil, nil, glassesTypes, true)
    if not address then
        return
    end

    return glasses.create(address)
end

function glasses.create(address)
    local proxy = component.proxy(address)

    local obj = setmetatable({}, {__index = glasses})
    obj.proxy = proxy
    obj.type = select(2, table.exists(glassesTypes, proxy.type))
    return obj
end

glasses.unloadable = true
return glasses