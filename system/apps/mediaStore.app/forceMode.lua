local paths = require("paths")
local system = require("system")
local registry = require("registry")
local gui = require("gui")
local apps = require("apps")

local screen, nickname = ...

if registry.disableMarketForceMode then
    gui.warn(screen, nil, nil, "market force-mode is not available on your liked edition")
else
    apps.execute("market", screen, nickname, nil, true, true)
end