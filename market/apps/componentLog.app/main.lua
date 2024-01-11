local component = require("component")
local gui = require("gui")
local fs = require("filesystem")
local paths = require("paths")
local logs = require("logs")
local hook = require("hook")
local event = require("event")

_G.componentLog = _G.componentLog or {}

local screen = ...
local address = gui.selectcomponent(screen)
if not address then
    return
end

local obj = _G.componentLog[address]
if obj then
    event.cancel(obj[2])
    hook.delComponentHook(address, obj[1])
    gui.done(screen, nil, nil, "the logger is disabled")

    _G.componentLog[address] = nil
else
    local logPath = paths.concat("/data/userdata/componentLogs", address .. ".txt")
    local logsStrs = {}
    local function hookfunc(address, method, args)
        local strs = {}
        for i, str in ipairs(args) do
            if type(str) == "string" then
                strs[i] = "\"" .. str .. "\""
            else
                strs[i] = tostring(str)
            end
        end

        table.insert(logsStrs, method .. "(" .. table.concat(strs, ", ") .. ")")
        return address, method, args
    end
    
    hook.addComponentHook(address, hookfunc)
    gui.done(screen, nil, nil, "the logger is enabled")
    
    _G.componentLog[address] = {hookfunc, event.timer(1, function ()
        if #logsStrs > 0 then
            hook.delComponentHook(address, hookfunc)
            logs.logs(logsStrs, "component-log", logPath)
            hook.addComponentHook(address, hookfunc)
            logsStrs = {}
        end
    end, math.huge)}
end