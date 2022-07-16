local internet = component.proxy(component.list("internet")() or error("no internet card found", 0))
local proxy = component.proxy(computer.getBootAddress())

local function getInternetFile(url)
    local handle, data, result, reason = internet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge) 
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "unvalid address"
    end
end

local function split(str, sep)
    local parts, count, i = {}, 1, 1
    while 1 do
        if i > #str then break end
        local char = str:sub(i, #sep + (i - 1))
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + #sep
        else
            parts[count] = parts[count] .. str:sub(i, i)
            i = i + 1
        end
    end
    if str:sub(#str - (#sep - 1), #str) == sep then table.insert(parts, "") end
    return parts
end

local function segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

local function canonical(path)
    local result = table.concat(segments(path), "/")
    if unicode.sub(path, 1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

local function fs_path(path)
    local parts = segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return canonical("/" .. result)
    else
        return canonical(result)
    end
end

local function installUrl(url)
    local filelist = split(assert(getInternetFile(url .. "/filelist.txt")), "\n")
    for i, v in ipairs(filelist) do
        local filedata = assert(getInternetFile(url .. v))

        proxy.makeDirectory(fs_path(v))
        local file = proxy.open(v, "wb")
        proxy.write(file, filedata)
        proxy.close(file)
    end
end

proxy.remove("/system")
installUrl("https://raw.githubusercontent.com/igorkll/likeOS/main/installer")
installUrl("https://raw.githubusercontent.com/igorkll/liked/main/installer")