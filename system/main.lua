local gui_container = require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local thread = require("thread")
local calls = require("calls")
local event = require("event")

------------------------------------

local threads = {}
for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.maxDepth() ~= 1 then
        calls.call("gui_initScreen", address)
        local desktop = assert(programs.load("desktop")) --один раз загрузить не выйдит, потому что тогда у них будут один _ENV что приведет к путанице глобалов, которые должны оставаться личьными
        local t = thread.create(desktop, address)
        t:resume()
        t.screen = address
        table.insert(threads, t)
    end
end

while true do
    --[[
    for i, v in ipairs(threads) do
        if v:status() == "dead" then
            error("crash thread is monitor " .. v.screen:sub(1, 4) .. " " .. (v.out[2] or "unknown error") .. " " .. (v.out[3] or "not found"))
        end
    end
    ]]
    event.sleep(1)
end