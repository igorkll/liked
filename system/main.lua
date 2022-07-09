local gui_container = require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local thread = require("thread")
local calls = require("calls")
local event = require("event")

------------------------------------

for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.getDepth() ~= 1 then
        calls.call("gui_initScreen", address)
        local desktop = programs.load("desktop")
        local t = thread.create(desktop, address)
        t:resume()
    end
end

while true do
    event.sleep(2)
end