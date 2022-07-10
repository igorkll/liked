local gui_container = require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local thread = require("thread")
local calls = require("calls")
local event = require("event")

------------------------------------

local desktop = assert(programs.load("desktop"))

for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.maxDepth() ~= 1 then
        calls.call("gui_initScreen", address)
        local t = thread.create(desktop, address)
        t:resume()
    end
end

while #thread.threads > 0 do
    event.sleep(0.1)
end