local gui_container = require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local thread = require("thread")
local calls = require("calls")

------------------------------------

for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.getDepth() ~= 1 then
        calls.call("gui_initScreen", address)
        local programm = programs.load("desktop")
        thread.create(programm, address)
    end
end