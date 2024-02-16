local registry = require("registry")
local gui = require("gui")

local screen, nickname = ...

if registry.disableCustomMarketUrls then
    gui.warn(screen, nil, nil, "custom mediastore urls is not available on your liked edition")
else
    assert(require("apps").execute("edit", screen, nickname, "/data/media_urls.txt"))
end