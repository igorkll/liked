local gui_container = require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local thread = require("thread")
local calls = require("calls")
local event = require("event")

------------------------------------

local desktop = assert(programs.load("desktop"))

local threads = {}
for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.maxDepth() ~= 1 then
        calls.call("gui_initScreen", address)
        local t = thread.create(desktop, address)
        t:resume()
        table.insert(threads, t)
    end
end

while true do
    for i, v in ipairs(threads) do
        if v:status() == "dead" then
            error("crash thread " .. tostring(i) .. " " .. (v.out[2] or "unknown error") .. " traceback " .. (v.out[3] or "not found"))
        end
    end
    event.sleep(1)
end