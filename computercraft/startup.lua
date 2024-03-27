-- ComputerCraft support (Alpha)

--------------------------------------- check script location

local function getSelfScriptPath()
    for runLevel = 0, math.huge do
        local info = debug.getinfo(runLevel)

        if info then
            if info.what == "main" then
                return info.source:sub(2, -1)
            end
        else
            error("Failed to get debug info for runlevel " .. runLevel)
        end
    end
end

local selfScriptPath = getSelfScriptPath()
if selfScriptPath ~= "/startup.lua" then
    print("liked cannot be launched from here: ", selfScriptPath)
    return
end

--------------------------------------- apply computer settings

settings.set("shell.allow_disk_startup", false)
settings.save()

--------------------------------------- try start OS

local env = {}

local code, err = loadfile("/liked/init.lua", nil, env)
if code then
    
else
    print("failed to load liked: ", err)
end