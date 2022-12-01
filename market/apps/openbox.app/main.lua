local computer = require("computer")
local component = require("component")
local graphic = require("graphic")
local fs = require("filesystem")
local paths = require("paths")

--------------------------------

local screen = ...
local programmPath = gui_selectfile(screen, nil, nil, 1, {"lua"}, "programm", {"lua code"})
if not programmPath then return end

local programmdir = paths.path(programmPath)
local env = createClearEnv()
env.os = {
    getWorkingDirectory = function()
        return programmdir
    end,
    setWorkingDirectory = function(path)
        checkArg(1, path, "string")
        programmdir = path
    end,
    exit = function()
        error("exit", 0)
    end
}

local components = {}
for ctype, address in component.list() do
    components[ctype] = component.proxy(components)
end
local componentLib = setmetatable(deepclone(component), {__index = components})
env.require = function(name)
    if name == "component" then
        return componentLib
    end
    return require(name)
end