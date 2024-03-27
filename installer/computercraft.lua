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

term.setBackgroundColor(colors.blue)
print("do you really want to install liked (likeOS based system)?")
print("type 'YES' to start installation")

if io.read() == "YES" then
    print("start of installation")
    os.reboot()
else
    clear(colors.black)
    print("the installation was canceled")
end