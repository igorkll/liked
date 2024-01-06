local registry = require("registry")
local cache = require("cache")

if registry.enableRecoveryAfterSetup then
    registry.enableRecoveryAfterSetup = nil
    registry.disableRecovery = false
end

_G.doSetup = nil