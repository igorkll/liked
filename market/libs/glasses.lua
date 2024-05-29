local component = require("component")
local gui = require("gui")
local graphic = require("graphic")
local computer = require("computer")
local unicode = require("unicode")
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
    x = (x - 1) * 6 * self.scale
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
        local gpu = graphic.findGpu(screen)
        local rx, ry = gpu.getResolution()

        self:clear()
        --[[
        local _, oldFore, oldBack = gpu.get(1, 1)
        local oldX, oldY = 1, 1
        local buff = ""

        for cy = 1, ry do
            for cx = 1, rx do
                local char, fore, back = gpu.get(cx, cy)

                if fore ~= oldFore or back ~= oldBack or oldY ~= cy or unicode.len(buff) > 4 then
                    self:drawText(oldX, oldY, ("█"):rep(unicode.len(buff)), oldBack)
                    self:drawText(oldX, oldY, buff, oldFore)
                    glasses.ramCheck()

                    oldFore = fore
                    oldBack = back
                    oldX = cx
                    oldY = cy
                    buff = char
                else
                    buff = buff .. char
                end
            end
        end

        if oldFore then
            self:drawText(oldX, oldY, ("█"):rep(unicode.len(buff)), oldBack)
            self:drawText(oldX, oldY, buff, oldFore)
            glasses.ramCheck()
        end
        ]]

        for cy = 1, ry do
            for cx = 1, rx do
                local char, fore, back = gpu.get(cx, cy)
                self:drawText(cx, cy, "█", back)
                self:drawText(cx, cy, char, fore)
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
    obj.scale = 0.7

    return obj
end

glasses.unloadable = true
return glasses