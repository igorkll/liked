local component = require("component")
local gui = require("gui")
local graphic = require("graphic")
local computer = require("computer")
local glasses = {}

function glasses.ramCheck()
    if computer.freeMemory() < (16 * 1024) then
        os.sleep(0)
    end
end

--------------------------------------- objects methods

function glasses:destroy(object)
    if self.type == 1 then
        object.delete()
    end
end

function glasses:setColor(object, color)
    if self.type == 1 then
        object.setColor(color)
    end
end

--------------------------------------- ui settings methods

function glasses:setScale(value)
    self.scale = value
end

--------------------------------------- glasses draw methods

function glasses:clear()
    if self.type == 1 then
        self.proxy.clear()
    end
end

function glasses:drawText(x, y, text, color)
    x = (x - 1) * 8 * self.scale
    y = (y - 1) * 8 * self.scale

    if self.type == 1 then
        local object = self.proxy.addText(x, y, text)
        object.setColor(color)
        object.setScale(self.scale)
        return object
    end
end

function glasses:flush()
    if self.type == 1 then
        self.proxy.sync()
    end
end

--------------------------------------- advanced methods

function glasses:screenCapture(screen)
    return function ()
        self:clear()
        local gpu = graphic.findGpu(screen)
        local rx, ry = gpu.getResolution()
        for ix = 1, rx do
            for iy = 1, ry do
                local char, fore, back = gpu.get(ix, iy)
                self:drawText(ix, iy, "█", back)
                self:drawText(ix, iy, char, fore)
                glasses.ramCheck()
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
    obj.scale = 0.5

    return obj
end

glasses.unloadable = true
return glasses