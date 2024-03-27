local function clear(col)
    term.setBackgroundColor(col)
    term.setCursorPos(1, 1)
    term.clear()
end
clear(colors.blue)

---------------------------------------

local logo = {
    [[]],
    [[  G       G  G   G   GGGGGG   WWWWWWWWW  WWWWWWWWW]],
    [[  G          G  G    G        W       W  W        ]],
    [[  G       G  G G     G        W       W  W        ]],
    [[  G       G  GG      G        W       W  W        ]],
    [[  G       G  GG      GGGGGG   W       W  WWWWWWWWW]],
    [[  G       G  G G     G        W       W          W]],
    [[  G       G  G  G    G        W       W          W]],
    [[  GGGGGG  G  G   G   GGGGGG   WWWWWWWWW  WWWWWWWWW]],
    [[]]
}

for _, str in ipairs(logo) do
    for i = 1, #str do
        local char = str:sub(i, i)
        if char == "G" then
            term.setBackgroundColor(colors.lightGray)
        elseif char == "W" then
            term.setBackgroundColor(colors.white)
        else
            term.setBackgroundColor(colors.blue)
        end
        io.write(" ")
    end
    io.write("\n")
end

---------------------------------------

local baseUrl = "https://raw.githubusercontent.com/igorkll/liked/"
local branch = "main"

local function printResult(title, ...)
    local ok, err = ...
    if ok then
        print(title, ">", "successfully")
    else
        print(title, ">", "error: ", tostring(err or "unknown error"))
    end
    return ...
end

local function wget(url)
    local ok, err = printResult("http.checkURL", http.checkURL(url))
    if not ok then
        return nil, tostring(err or "unknown error")
    end

    local response, err = printResult("http.get", http.get(url))
    if not response then
        return nil, tostring(err or "unknown error")
    end

    local data = response.readAll()
    response.close()
    return data
end

local function download(path, cc)
    local url
    if cc then
        url = baseUrl .. branch .. "/computercraft" .. path
    else
        url = baseUrl .. branch .. path
    end

    local str, err = printResult("wget", wget(url))
    if not str then
        return nil, tostring(err or "unknown error")
    end

    fs.makeDir("/" .. fs.getDir(path))
    local file = fs.open(path, "wb")
    file.write(str)
    file.close()

    return true
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

local function processList(data)
    local tbl = split(data, "\n")
    for i = #tbl, 1, -1 do
        if tbl[i] == "" then
            table.remove(tbl, i)
        end
    end
    return tbl
end

local function downloadList(listUrl, cc)
    print("start downloading from list: ", listUrl)
    local lst = processList(printResult("wget", wget(listUrl)))
    for i, path in ipairs(lst) do
        print("downloading: ", path)
        printResult("download", download(path, cc))
    end
end

---------------------------------------

term.setBackgroundColor(colors.blue)
print("do you really want to install liked (likeOS based system)?")
print("type 'YES' to start installation")

if io.read() == "YES" then
    print("start of installation")
    downloadList(baseUrl .. branch .. "/installer/cc_filelist.txt", true)
    downloadList(baseUrl .. branch .. "/installer/filelist.txt")
    os.reboot()
else
    clear(colors.black)
    print("the installation was canceled")
end