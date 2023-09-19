local programmData = [[
    --CCRedirection by : RamiLego4Game and Dan200--
    --Based on Redirection by Dan200: http://www.redirectiongame.com--
    --Clearing Screen--
    
    --Vars--
    local TermW,TermH = term.getSize()
    
    local sLevelTitle
    local tScreen
    local oScreen
    local SizeW,SizeH
    local aExits
    local fExit
    local nSpeed
    local Speed
    local fSpeed
    local fSpeedS
    local bPaused
    local Tick
    local Blocks
    local XOrgin,YOrgin
    local fLevel
    
    local function reset()
        sLevelTitle = ""
        tScreen = {}
        oScreen = {}
        SizeW,SizeH = TermW,TermH
        aExits = 0
        fExit = "nop"
        nSpeed = 0.6
        Speed = nSpeed
        fSpeed = 0.2
        fSpeedS = false
        bPaused = false
        Tick = os.startTimer(Speed)
        Blocks = 0
        XOrgin,YOrgin = 1,1
    
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
    end
    
    local InterFace = {}
    InterFace.cExit = colors.red
    InterFace.cSpeedD = colors.white
    InterFace.cSpeedA = colors.red
    InterFace.cTitle = colors.red
    
    local cG = colors.lightGray
    local cW = colors.gray
    local cS = colors.black
    local cR1 = colors.blue
    local cR2 = colors.red
    local cR3 = colors.green
    local cR4 = colors.yellow
    
    local tArgs = { ... }
    
    --Functions--
    local function printCentred( yc, stg )
        local xc = math.floor((TermW - string.len(stg)) / 2) + 1
        term.setCursorPos(xc,yc)
        term.write( stg )
    end
    
    local function centerOrgin()
        XOrgin = math.floor((TermW/2)-(SizeW/2))
        YOrgin = math.floor((TermH/2)-(SizeH/2))
    end
    
    local function reMap()
        tScreen = nil
        tScreen = {}
        for x=1,SizeW do
            tScreen[x] = {}
            for y=1,SizeH do
                tScreen[x][y] = { space = true, wall = false, ground = false, robot = "zz", start = "zz", exit = "zz" }
            end
        end
    end
    
    local function tablecopy(t)
      local t2 = {}
      for k,v in pairs(t) do
        t2[k] = v
      end
      return t2
    end
    
    local function buMap()
        oScreen = nil
        oScreen = {}
        for x=1,SizeW do
            oScreen[x] = {}
            for y=1,SizeH do
                oScreen[x][y] = tablecopy(tScreen[x][y])
            end
        end
    end
    
    local function addRobot(x,y,side,color)
        local obj = tScreen[x][y]
        local data = side..color
        if obj.wall == nil and obj.robot == nil then
            tScreen[x][y].robot = data
        else
            obj.wall = nil
            obj.robot = "zz"
            tScreen[x][y].robot = data
        end
    end
    
    local function addStart(x,y,side,color)
        local obj = tScreen[x][y]
        local data = side..color
        if obj.wall == nil and obj.space == nil then
            tScreen[x][y].start = data
        else
            obj.wall = nil
            obj.space = nil
            tScreen[x][y].start = data
        end
        aExits = aExits+1
    end
    
    local function addGround(x,y)
        local obj = tScreen[x][y]
        if obj.space == nil and obj.exit == nil and obj.wall == nil and obj.robot == nil and obj.start == nil then
            tScreen[x][y].ground = true
        else
            obj.space = nil
            obj.exit = "zz"
            obj.wall = nil
            obj.robot = "zz"
            obj.start = "zz"
            tScreen[x][y].ground = true
        end
    end
    
    local function addExit(x,y,cl)
        local obj = tScreen[x][y]
        if obj.space == nil and obj.ground == nil and obj.wall == nil and obj.robot == nil and obj.start == nil then
            tScreen[x][y].exit = cl
        else
            obj.space = nil
            obj.ground = nil
            obj.wall = nil
            obj.robot = "zz"
            obj.start = "zz"
            tScreen[x][y].exit = cl
        end
    end
    
    local function addWall(x,y)
        local obj = tScreen[x][y]
        if obj == nil then
            return error("Here X"..x.." Y"..y)
        end
        if obj.space == nil and obj.exit == nil and obj.ground == nil and obj.robot == nil and obj.start == nil then
            tScreen[x][y].wall = true
        else
            obj.space = nil
            obj.exit = nil
            obj.ground = nil
            obj.robot = nil
            obj.start = nil
            tScreen[x][y].wall = true
        end
    end
    
    local function loadLevel(nNum)
        sLevelTitle = "Level "..nNum
        if nNum == nil then return error("nNum == nil") end
        local sDir = fs.getDir( shell.getRunningProgram() )
        local sLevelD = sDir .. "/levels/" .. tostring(nNum)..".dat"
        if not ( fs.exists(sLevelD) or fs.isDir(sLevelD) ) then return error("Level Not Exists : "..sLevelD) end
        fLevel = fs.open(sLevelD,"r")
        local Line = 0
        local wl = true
        Blocks = tonumber(string.sub(fLevel.readLine(),1,1))
        local xSize = string.len(fLevel.readLine())+2
        local Lines = 3
        while wl do
            local wLine = fLevel.readLine()
            if wLine == nil then
                fLevel.close()
                wl = false
            else
                xSize = math.max(string.len(wLine)+2,xSize)
                Lines = Lines + 1
            end
        end
        SizeW,SizeH = xSize,Lines
        reMap()
        fLevel = fs.open(sLevelD,"r")
        fLevel.readLine()
        for Line=2,Lines-1 do
            local sLine = fLevel.readLine()
            local chars = string.len(sLine)
            for char = 1, chars do
                local el = string.sub(sLine,char,char)
                if el == "8" then
                    addGround(char+1,Line)
                elseif el == "0" then
                    addStart(char+1,Line,"a","a")
                elseif el == "1" then
                    addStart(char+1,Line,"b","a")
                elseif el == "2" then
                    addStart(char+1,Line,"c","a")
                elseif el == "3" then
                    addStart(char+1,Line,"d","a")
                elseif el == "4" then
                    addStart(char+1,Line,"a","b")
                elseif el == "5" then
                    addStart(char+1,Line,"b","b")
                elseif el == "6" then
                    addStart(char+1,Line,"c","b")
                elseif el == "9" then
                    addStart(char+1,Line,"d","b")
                elseif el == "b" then
                    addExit(char+1,Line,"a")
                elseif el == "e" then
                    addExit(char+1,Line,"b")
                elseif el == "7" then
                    addWall(char+1,Line)
                end
            end
        end
        fLevel.close()
    end
    
    local function drawStars()
        --CCR Background By : RamiLego--
        local cStar,cStarG,crStar,crStarB = colors.lightGray,colors.gray,".","*"
        local DStar,BStar,nStar,gStar = 14,10,16,3
        local TermW,TermH = term.getSize()
    
        term.clear()
        term.setCursorPos(1,1)
        for x=1,TermW do
            for y=1,TermH do
                local StarT = math.random(1,30)
                if StarT == DStar then
                    term.setCursorPos(x,y)
                    term.setTextColor(cStar)
                    write(crStar)
                elseif StarT == BStar then
                    term.setCursorPos(x,y)
                    term.setTextColor(cStar)
                    write(crStarB)
                elseif StarT == nStar then
                    term.setCursorPos(x,y)
                    term.setTextColor(cStarG)
                    write(crStar)
                elseif StarT == gStar then
                    term.setCursorPos(x,y)
                    term.setTextColor(cStarG)
                    write(crStarB)
                end
            end
        end
    end
    
    local function drawMap()
        for x=1,SizeW do
            for y=1,SizeH do
              
                local obj = tScreen[x][y]
                if obj.ground == true then
                    paintutils.drawPixel(XOrgin+x,YOrgin+y+1,cG)
                end
                if obj.wall == true then
                    paintutils.drawPixel(XOrgin+x,YOrgin+y+1,cW)
                end
             
             local ex = tostring(tScreen[x][y].exit)
                if not(ex == "zz" or ex == "nil") then
                    if ex == "a" then
                        ex = cR1
                    elseif ex == "b" then
                        ex = cR2
                    elseif ex == "c" then
                        ex = cR3
                    elseif ex == "d" then
                        ex = cR4
                    else
                        return error("Exit Color Out")
                    end
                    term.setBackgroundColor(cG)
                    term.setTextColor(ex)
                    term.setCursorPos(XOrgin+x,YOrgin+y+1)
                    print("X")
                end
             
             local st = tostring(tScreen[x][y].start)
                if not(st == "zz" or st == "nil") then
                    local Cr = string.sub(st,2,2)
                    if Cr == "a" then
                        Cr = cR1
                    elseif Cr == "b" then
                        Cr = cR2
                    elseif Cr == "c" then
                        Cr = cR3
                    elseif Cr == "d" then
                        Cr = cR4
                    else
                        return error("Start Color Out")
                    end
                
                    term.setTextColor(Cr)
                term.setBackgroundColor(cG)
                    term.setCursorPos(XOrgin+x,YOrgin+y+1)
                
                    local sSide = string.sub(st,1,1)
                    if sSide == "a" then
                        print("^")
                    elseif sSide == "b" then
                        print(">")
                    elseif sSide == "c" then
                        print("v")
                    elseif sSide == "d" then
                        print("<")
                    else
                        print("@")
                    end
                end
                
                if obj.space == true then
                    paintutils.drawPixel(XOrgin+x,YOrgin+y+1,cS)
                end
                
                local rb = tostring(tScreen[x][y].robot)
                if not(rb == "zz" or rb == "nil") then
                    local Cr = string.sub(rb,2,2)
                    if Cr == "a" then
                        Cr = cR1
                    elseif Cr == "b" then
                        Cr = cR2
                    elseif Cr == "c" then
                        Cr = cR3
                    elseif Cr == "d" then
                        Cr = cR4
                    else
                        Cr = colors.white
                    end
                    term.setBackgroundColor(Cr)
                    term.setTextColor(colors.white)
                    term.setCursorPos(XOrgin+x,YOrgin+y+1)
                    local sSide = string.sub(rb,1,1)
                    if sSide == "a" then
                        print("^")
                    elseif sSide == "b" then
                        print(">")
                    elseif sSide == "c" then
                        print("v")
                    elseif sSide == "d" then
                        print("<")
                    else
                        print("@")
                    end
                end
            end
        end
    end
    
    local function isBrick(x,y)
        local brb = tostring(tScreen[x][y].robot)
        local bobj = oScreen[x][y]
        if (brb == "zz" or brb == "nil") and not bobj.wall == true then
            return false
        else
            return true
        end
    end
    
    local function gRender(sContext)
        if sContext == "start" then
            for x=1,SizeW do
                for y=1,SizeH do
                    local st = tostring(tScreen[x][y].start)
                    if not(st == "zz" or st == "nil") then
                        local Cr = string.sub(st,2,2)
                        local sSide = string.sub(st,1,1)
                        addRobot(x,y,sSide,Cr)
                    end
                end
            end
        elseif sContext == "tick" then
            buMap()
            for x=1,SizeW do
                for y=1,SizeH do
                    local rb = tostring(oScreen[x][y].robot)
                    if not(rb == "zz" or rb == "nil") then
                        local Cr = string.sub(rb,2,2)
                        local sSide = string.sub(rb,1,1)
                        local sobj = oScreen[x][y]
                        if sobj.space == true then
                            tScreen[x][y].robot = "zz"
                            if not sSide == "g" then
                                addRobot(x,y,"g",Cr)
                            end
                        elseif sobj.exit == Cr then
                            if sSide == "a" or sSide == "b" or sSide == "c" or sSide == "d" then
                            tScreen[x][y].robot = "zz"
                            addRobot(x,y,"g",Cr)
                            aExits = aExits-1
                            end
                        elseif sSide == "a" then
                            local obj = isBrick(x,y-1)
                            tScreen[x][y].robot = "zz"
                            if not obj == true then
                                addRobot(x,y-1,sSide,Cr)
                            else
                                local obj2 = isBrick(x-1,y)
                                local obj3 = isBrick(x+1,y)
                                if not obj2 == true and not obj3 == true then
                                    if Cr == "a" then
                                        addRobot(x,y,"d",Cr)
                                    elseif Cr == "b" then
                                        addRobot(x,y,"b",Cr)
                                    end
                                elseif obj == true and obj2 == true and obj3 == true then
                                    addRobot(x,y,"c",Cr)
                                else
                                    if obj3 == true then
                                        addRobot(x,y,"d",Cr)
                                    elseif obj2 == true then
                                        addRobot(x,y,"b",Cr)
                                    end
                                end
                            end
                        elseif sSide == "b" then
                            local obj = isBrick(x+1,y)
                            tScreen[x][y].robot = "zz"
                            if not obj == true then
                                addRobot(x+1,y,sSide,Cr)
                            else
                                local obj2 = isBrick(x,y-1)
                                local obj3 = isBrick(x,y+1)
                                if not obj2 == true and not obj3 == true then
                                    if Cr == "a" then
                                        addRobot(x,y,"a",Cr)
                                    elseif Cr == "b" then
                                        addRobot(x,y,"c",Cr)
                                    end
                                elseif obj == true and obj2 == true and obj3 == true then
                                    addRobot(x,y,"d",Cr)
                                else
                                    if obj3 == true then
                                        addRobot(x,y,"a",Cr)
                                    elseif obj2 == true then
                                        addRobot(x,y,"c",Cr)
                                    end
                                end
                            end
                        elseif sSide == "c" then
                            local obj = isBrick(x,y+1)
                            tScreen[x][y].robot = "zz"
                            if not obj == true then
                                addRobot(x,y+1,sSide,Cr)
                            else
                                local obj2 = isBrick(x-1,y)
                                local obj3 = isBrick(x+1,y)
                                if not obj2 == true and not obj3 == true then
                                    if Cr == "a" then
                                        addRobot(x,y,"b",Cr)
                                    elseif Cr == "b" then
                                        addRobot(x,y,"d",Cr)
                                    end
                                elseif obj == true and obj2 == true and obj3 == true then
                                    addRobot(x,y,"a",Cr)
                                else
                                    if obj3 == true then
                                        addRobot(x,y,"d",Cr)
                                    elseif obj2 == true then
                                        addRobot(x,y,"b",Cr)
                                    end
                                end
                            end
                        elseif sSide == "d" then
                            local obj = isBrick(x-1,y)
                            tScreen[x][y].robot = "zz"
                            if not obj == true then
                                addRobot(x-1,y,sSide,Cr)
                            else
                                local obj2 = isBrick(x,y-1)
                                local obj3 = isBrick(x,y+1)
                                if not obj2 == true and not obj3 == true then
                                    if Cr == "a" then
                                        addRobot(x,y,"c",Cr)
                                    elseif Cr == "b" then
                                        addRobot(x,y,"a",Cr)
                                    end
                                elseif obj == true and obj2 == true and obj3 == true then
                                    addRobot(x,y,"b",Cr)
                                else
                                    if obj3 == true then
                                        addRobot(x,y,"a",Cr)
                                    elseif obj2 == true then
                                        addRobot(x,y,"c",Cr)
                                    end
                                end
                            end
                        else
                            addRobot(x,y,sSide,"g")
                        end
                    end
                end
            end
        end
    end
    
    function InterFace.drawBar()
        term.setBackgroundColor( colors.black )
        term.setTextColor( InterFace.cTitle )
        printCentred( 1, "  "..sLevelTitle.."  " )
        
        term.setCursorPos(1,1)
        term.setBackgroundColor( cW )
        write( " " )
        term.setBackgroundColor( colors.black )
        write( " x "..tostring(Blocks).." " )
        
        term.setCursorPos( TermW-8,TermH )
        term.setBackgroundColor( colors.black )
        term.setTextColour(InterFace.cSpeedD)
        write(" <<" )
        if bPaused then
            term.setTextColour(InterFace.cSpeedA)
        else
            term.setTextColour(InterFace.cSpeedD)
        end
        write(" ||")
        if fSpeedS then
            term.setTextColour(InterFace.cSpeedA)
        else
            term.setTextColour(InterFace.cSpeedD)
        end
        write(" >>")
    
        term.setCursorPos( TermW-1, 1 )
        term.setBackgroundColor( colors.black )
        term.setTextColour( InterFace.cExit )
        write(" X")
        term.setBackgroundColor(colors.black)
    end
    
    function InterFace.render()
        local id,p1,p2,p3 = os.pullEvent()
        if id == "mouse_click" then
            if p3 == 1 and p2 == TermW then
                return "end"
            elseif p3 == TermH and p2 >= TermW-7 and p2 <= TermW-6 then
                return "retry"
            elseif p3 == TermH and p2 >= TermW-4 and p2 <= TermW-3 then
                bPaused = not bPaused
                fSpeedS = false
                Speed = (bPaused and 0) or nSpeed
                if Speed > 0 then
                    Tick = os.startTimer(Speed)
                else
                    Tick = nil
                end
                InterFace.drawBar()
            elseif p3 == TermH and p2 >= TermW-1 then
                bPaused = false
                fSpeedS = not fSpeedS
                Speed = (fSpeedS and fSpeed) or nSpeed
                Tick = os.startTimer(Speed)
                InterFace.drawBar()
            elseif p3-1 < YOrgin+SizeH+1 and p3-1 > YOrgin and
                   p2 < XOrgin+SizeW+1 and p2 > XOrgin then
                local eobj = tScreen[p2-XOrgin][p3-YOrgin-1]
                local erobj = tostring(tScreen[p2-XOrgin][p3-YOrgin-1].robot)
                if (erobj == "zz" or erobj == "nil") and not eobj.wall == true and not eobj.space == true and Blocks > 0 then
                    addWall(p2-XOrgin,p3-YOrgin-1)
                    Blocks = Blocks-1
                    InterFace.drawBar()
                    drawMap()
                end
            end
        elseif id == "timer" and p1 == Tick then
            gRender("tick")
            drawMap()
            if Speed > 0 then
                Tick = os.startTimer(Speed)
            else
                Tick = nil
            end
        end
    end
    
    local function startG(LevelN)
        drawStars()
        loadLevel(LevelN)
        centerOrgin()
        local create = true
        drawMap()
        InterFace.drawBar()
        gRender("start")
        drawMap()
        
        local NExit = true
        if aExits == 0 then
            NExit = false
        end
        
        while true do
            local isExit = InterFace.render()
            if isExit == "end" then
                return nil
            elseif isExit == "retry" then
                return LevelN
            elseif fExit == "yes" then
                if fs.exists( fs.getDir( shell.getRunningProgram() ) .. "/levels/" .. tostring(LevelN + 1) .. ".dat" ) then
                    return LevelN + 1
                else
                    return nil
                end
            end
            if aExits == 0 and NExit == true then
                fExit = "yes"
            end
        end
    end
    
    local ok, err = true, nil
    
    --Menu--
    if ok then
        ok, err = pcall( function()
            term.setTextColor(colors.white)
            term.setBackgroundColor( colors.black )
            term.clear()
            drawStars()
            term.setTextColor( colors.red )
            printCentred( TermH/2 - 1, "  REDIRECTION  " )
            printCentred( TermH/2 - 0, "  ComputerCraft Edition  " )
            term.setTextColor( colors.yellow )
            printCentred( TermH/2 + 2, "  Click to Begin  " )
            os.pullEvent( "mouse_click" )
        end )
    end
    
    --Game--
    if ok then
        ok,err = pcall( function()
            local nLevel
            if sStartLevel then
                nLevel = tonumber( sStartLevel )
            else
                nLevel = 1
            end
            while nLevel do
                reset()
                nLevel = startG(nLevel)
            end
        end )
    end
    
    --Upsell screen--
    if ok then
        ok, err = pcall( function()
            term.setTextColor(colors.white)
            term.setBackgroundColor( colors.black )
            term.clear()
            drawStars()
            term.setTextColor( colors.red )
            if TermW >= 40 then
                printCentred( TermH/2 - 1, "  Thank you for playing Redirection  " )
                printCentred( TermH/2 - 0, "  ComputerCraft Edition  " )
                printCentred( TermH/2 + 2, "  Check out the full game:  " )
                term.setTextColor( colors.yellow )
                printCentred( TermH/2 + 3, "  http://www.redirectiongame.com  " )
            else
                printCentred( TermH/2 - 2, "  Thank you for  " )
                printCentred( TermH/2 - 1, "  playing Redirection  " )
                printCentred( TermH/2 - 0, "  ComputerCraft Edition  " )
                printCentred( TermH/2 + 2, "  Check out the full game:  " )
                term.setTextColor( colors.yellow )
                printCentred( TermH/2 + 3, "  www.redirectiongame.com  " )
            end

            os.pullEvent( "mouse_click" )
        end )
    end
    
    --Clear and exit--
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()
    if not ok then
        if err == "Terminated" then
            print( "Check out the full version of Redirection:" )
            print( "http://www.redirectiongame.com" )
        else
            error( err )
        end
    end
    
]]
--[[
local colorPic = require("colorPic")
local bit32 = require("bit32")
local shell = require("shell")
local su = require("superUtiles")
local fs = require("filesystem")
local unicode = require("unicode")
local component = require("component")
local term = require("term")
local computer = require("computer")
local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
]]

local thread = require("thread")











local keyboard = {pressedChars = {}, pressedCodes = {}}


keyboard.keys = {
  c               = 0x2E,
  d               = 0x20,
  q               = 0x10,
  w               = 0x11,
  back            = 0x0E, -- backspace
  delete          = 0xD3,
  down            = 0xD0,
  enter           = 0x1C,
  home            = 0xC7,
  lcontrol        = 0x1D,
  left            = 0xCB,
  lmenu           = 0x38, -- left Alt
  lshift          = 0x2A,
  pageDown        = 0xD1,
  rcontrol        = 0x9D,
  right           = 0xCD,
  rmenu           = 0xB8, -- right Alt
  rshift          = 0x36,
  space           = 0x39,
  tab             = 0x0F,
  up              = 0xC8,
  ["end"]         = 0xCF,
  enter           = 0x1C,
  tab             = 0x0F,
  numpadenter     = 0x9C,
}

-------------------------------------------------------------------------------

function keyboard.isAltDown()
  return keyboard.pressedCodes[keyboard.keys.lmenu] or keyboard.pressedCodes[keyboard.keys.rmenu]
end

function keyboard.isControl(char)
  return type(char) == "number" and (char < 0x20 or (char >= 0x7F and char <= 0x9F))
end

function keyboard.isControlDown()
  return keyboard.pressedCodes[keyboard.keys.lcontrol] or keyboard.pressedCodes[keyboard.keys.rcontrol]
end

function keyboard.isKeyDown(charOrCode)
  checkArg(1, charOrCode, "string", "number")
  if type(charOrCode) == "string" then
    return keyboard.pressedChars[utf8 and utf8.codepoint(charOrCode) or charOrCode:byte()]
  elseif type(charOrCode) == "number" then
    return keyboard.pressedCodes[charOrCode]
  end
end

function keyboard.isShiftDown()
  return keyboard.pressedCodes[keyboard.keys.lshift] or keyboard.pressedCodes[keyboard.keys.rshift]
end

-------------------------------------------------------------------------------


keyboard.keys["1"]           = 0x02
keyboard.keys["2"]           = 0x03
keyboard.keys["3"]           = 0x04
keyboard.keys["4"]           = 0x05
keyboard.keys["5"]           = 0x06
keyboard.keys["6"]           = 0x07
keyboard.keys["7"]           = 0x08
keyboard.keys["8"]           = 0x09
keyboard.keys["9"]           = 0x0A
keyboard.keys["0"]           = 0x0B
keyboard.keys.a               = 0x1E
keyboard.keys.b               = 0x30
keyboard.keys.c               = 0x2E
keyboard.keys.d               = 0x20
keyboard.keys.e               = 0x12
keyboard.keys.f               = 0x21
keyboard.keys.g               = 0x22
keyboard.keys.h               = 0x23
keyboard.keys.i               = 0x17
keyboard.keys.j               = 0x24
keyboard.keys.k               = 0x25
keyboard.keys.l               = 0x26
keyboard.keys.m               = 0x32
keyboard.keys.n               = 0x31
keyboard.keys.o               = 0x18
keyboard.keys.p               = 0x19
keyboard.keys.q               = 0x10
keyboard.keys.r               = 0x13
keyboard.keys.s               = 0x1F
keyboard.keys.t               = 0x14
keyboard.keys.u               = 0x16
keyboard.keys.v               = 0x2F
keyboard.keys.w               = 0x11
keyboard.keys.x               = 0x2D
keyboard.keys.y               = 0x15
keyboard.keys.z               = 0x2C

keyboard.keys.apostrophe      = 0x28
keyboard.keys.at              = 0x91
keyboard.keys.back            = 0x0E -- backspace
keyboard.keys.backslash       = 0x2B
keyboard.keys.capital         = 0x3A -- capslock
keyboard.keys.colon           = 0x92
keyboard.keys.comma           = 0x33
keyboard.keys.enter           = 0x1C
keyboard.keys.equals          = 0x0D
keyboard.keys.grave           = 0x29 -- accent grave
keyboard.keys.lbracket        = 0x1A
keyboard.keys.lcontrol        = 0x1D
keyboard.keys.lmenu           = 0x38 -- left Alt
keyboard.keys.lshift          = 0x2A
keyboard.keys.minus           = 0x0C
keyboard.keys.numlock         = 0x45
keyboard.keys.pause           = 0xC5
keyboard.keys.period          = 0x34
keyboard.keys.rbracket        = 0x1B
keyboard.keys.rcontrol        = 0x9D
keyboard.keys.rmenu           = 0xB8 -- right Alt
keyboard.keys.rshift          = 0x36
keyboard.keys.scroll          = 0x46 -- Scroll Lock
keyboard.keys.semicolon       = 0x27
keyboard.keys.slash           = 0x35 -- / on main keyboard
keyboard.keys.space           = 0x39
keyboard.keys.stop            = 0x95
keyboard.keys.tab             = 0x0F
keyboard.keys.underline       = 0x93

-- Keypad (and numpad with numlock off)
keyboard.keys.up              = 0xC8
keyboard.keys.down            = 0xD0
keyboard.keys.left            = 0xCB
keyboard.keys.right           = 0xCD
keyboard.keys.home            = 0xC7
keyboard.keys["end"]         = 0xCF
keyboard.keys.pageUp          = 0xC9
keyboard.keys.pageDown        = 0xD1
keyboard.keys.insert          = 0xD2
keyboard.keys.delete          = 0xD3

-- Function keys
keyboard.keys.f1              = 0x3B
keyboard.keys.f2              = 0x3C
keyboard.keys.f3              = 0x3D
keyboard.keys.f4              = 0x3E
keyboard.keys.f5              = 0x3F
keyboard.keys.f6              = 0x40
keyboard.keys.f7              = 0x41
keyboard.keys.f8              = 0x42
keyboard.keys.f9              = 0x43
keyboard.keys.f10             = 0x44
keyboard.keys.f11             = 0x57
keyboard.keys.f12             = 0x58
keyboard.keys.f13             = 0x64
keyboard.keys.f14             = 0x65
keyboard.keys.f15             = 0x66
keyboard.keys.f16             = 0x67
keyboard.keys.f17             = 0x68
keyboard.keys.f18             = 0x69
keyboard.keys.f19             = 0x71

-- Japanese keyboards
keyboard.keys.kana            = 0x70
keyboard.keys.kanji           = 0x94
keyboard.keys.convert         = 0x79
keyboard.keys.noconvert       = 0x7B
keyboard.keys.yen             = 0x7D
keyboard.keys.circumflex      = 0x90
keyboard.keys.ax              = 0x96

-- Numpad
keyboard.keys.numpad0         = 0x52
keyboard.keys.numpad1         = 0x4F
keyboard.keys.numpad2         = 0x50
keyboard.keys.numpad3         = 0x51
keyboard.keys.numpad4         = 0x4B
keyboard.keys.numpad5         = 0x4C
keyboard.keys.numpad6         = 0x4D
keyboard.keys.numpad7         = 0x47
keyboard.keys.numpad8         = 0x48
keyboard.keys.numpad9         = 0x49
keyboard.keys.numpadmul       = 0x37
keyboard.keys.numpaddiv       = 0xB5
keyboard.keys.numpadsub       = 0x4A
keyboard.keys.numpadadd       = 0x4E
keyboard.keys.numpaddecimal   = 0x53
keyboard.keys.numpadcomma     = 0xB3
keyboard.keys.numpadenter     = 0x9C
keyboard.keys.numpadequals    = 0x8D

-- Create inverse mapping for name lookup.
setmetatable(keyboard.keys,
{
  __index = function(tbl, k)
    if type(k) ~= "number" then return end
    for name,value in pairs(tbl) do
      if value == k then
        return name
      end
    end
  end
})


















local computer = require("computer")
local component = require("component")
local unicode = require("unicode")
local graphic = require("graphic")
local event = require("event")
local fs = require("filesystem")

local screen = ...
local keyboard2 = component.invoke(screen, "getKeyboards")[1]
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local window = graphic.createWindow(screen, 1, 1, rx, ry)

--------------------------------------------

local colors = require("gui_container").colors
local cursorBlick = false

--------------------------------------------

local selfpath = require("system").getSelfScriptPath()
local paths = require("paths")

local ccqueue = {}

local env
env = {
    fs = {
        getDir = function (path)
            return paths.path(path)
        end,
        list = function(path)
            local files = {}
            for file in fs.list(path) do
                local text = fs.concat(file)
                if unicode.sub(text, unicode.len(text), unicode.len(text)) == "/" then
                    text = unicode.sub(text, unicode.len(text), unicode.len(text) - 1)
                end
                table.insert(files, text)
            end
            return files
        end,
        isDir = fs.isDirectory,
        exists = fs.exists,
        isReadOnly = function(path)
            return fs.get(path).isReadOnly()
        end,
        getName = function(path)
            return fs.get(path).getLabel()
        end,
        makeDir = fs.makeDirectory,
        move = fs.move,
        copy = fs.copy,
        delete = fs.remove,
        combine = fs.concat,
        open = function(path, mode)
            local file, err = fs.open(path, mode)
            if not file then return nil, err end

            local obj = {}

            function obj.readAll()
                return file.readAll()
            end

            function obj.close()
                return file.close()
            end

            function obj.write(str)
                if type(str) == "string" then
                    return file.write(str)
                else
                    return file.write(string.byte(str))
                end
            end

            function obj.writeLine(str)
                return file.write(str .. "\n")
            end

            function obj.read(bytes)
                if bytes then
                    return file.read(bytes)
                else
                    return string.char(file.read(1))
                end
            end
            
            function obj.readLine()
                local line = nil
                while true do
                    local char = file.read(1)
                    if not char or char == "\n" then break end
                    if not line then line = "" end
                    line = line .. char
                end
                return line
            end

            return obj
        end,
    },
    term = {
        getSize = function()
            local gpu = graphic.findGpu(screen)
            return gpu.getResolution()
        end,
        isColor = function()
            local gpu = graphic.findGpu(screen)
            return gpu.getDepth() ~= 1
        end,
        write = function(data)
            local gpu = graphic.findGpu(screen)
            window:write(data, gpu.getBackground(), gpu.getForeground())
        end,
        setCursorPos = function(x, y)
            window:setCursor(x, y)
        end,
        --getCursorPos = term.getCursor,
        clear = function(color)
            window:clear(color or colors.black)
        end,
        --clearLine = term.clearLine,
        --scroll = term.scroll,
        getTextColor = function(color)
            local gpu = graphic.findGpu(screen)
            return gpu.getForeground(color)
        end,
        getBackgroundColor = function(color)
            local gpu = graphic.findGpu(screen)
            return gpu.getBackground(color)
        end,
        setTextColor = function(color)
            local gpu = graphic.findGpu(screen)
            gpu.setForeground(color)
        end,
        setBackgroundColor = function(color)
            local gpu = graphic.findGpu(screen)
            gpu.setBackground(color)
        end,
        getCursorBlink = function()
            return cursorBlick
        end,
        setCursorBlink = function(state)
            cursorBlick = state
        end,

        blit = function(char, fore, back)
            local gpu = graphic.findGpu(screen)

            local oldFore = gpu.getForeground()
            local oldBack = gpu.getBackground()
            gpu.setForeground(tonumber(fore, 16))
            gpu.setBackground(tonumber(back, 16))
            gpu.set(char)
            gpu.setForeground(oldFore)
            gpu.setBackground(oldBack)
        end
    },
    os = {
        version = function()
            return "CraftOS 1.8"
        end,
        getComputerID = function()
            return 1
        end,
        --getComputerLabel = function()
        --    return fs.get("/").getLabel()
        --end,
        --setComputerLabel = function(label)
        --    fs.get("/").setLabel(label)
        --end,
        clock = os.clock,
        time = os.time,
        shutdown = function()
            computer.shutdown()
        end,
        reboot = function()
            computer.shutdown(true)
        end,
        pullEvent = function(name)
            while true do
                local newEventData

                if #ccqueue > 0 then
                    newEventData = table.remove(ccqueue)
                else
                    local eventData
                    if cursorBlick then
                        eventData = {event.pull(0.1)}
                    else
                        eventData = {event.pull(0.1)}
                    end

                    if eventData[1] == "touch" and eventData[2] == screen then
                        newEventData = {"mouse_click", math.floor(eventData[5] + 1), math.floor(eventData[3]), math.floor(eventData[4])}
                    elseif eventData[1] == "key_down" and eventData[2] == keyboard2 and eventData[3] == 3 and eventData[4] == 46 then
                        error("interrupted", 0)
                    elseif eventData[1] == "drop" and eventData[2] == screen then
                        newEventData = {"mouse_up", math.floor(eventData[5] + 1), math.floor(eventData[3]), math.floor(eventData[4])}
                    elseif eventData[1] == "drag" and eventData[2] == screen then
                        newEventData = {"mouse_drag", math.floor(eventData[5] + 1), math.floor(eventData[3]), math.floor(eventData[4])}
                    elseif eventData[1] == "scroll" and eventData[2] == screen then
                        newEventData = {"mouse_scroll", math.floor(-eventData[5]), math.floor(eventData[3]), math.floor(eventData[4])}
                    elseif eventData[1] == "key_down" and eventData[2] == keyboard2 then
                        newEventData = {"key", math.floor(eventData[4]), false}
                        if eventData[3] >= 32 and eventData[3] <= 126 then
                            table.insert(ccqueue, {"char", string.char(eventData[3])})
                        end
                    elseif eventData[1] == "key_up" and eventData[2] == keyboard2 then
                        newEventData = {"key_up", math.floor(eventData[4])}
                    elseif eventData[1] == "clipboard" and eventData[2] == keyboard2 then
                        newEventData = {"paste", eventData[3]}
                    end
                end

                if newEventData and (not name or newEventData[1] == name) then
                    return table.unpack(newEventData)
                end
            end
        end,
        startTimer = function(time)
            local id
            id = event.timer(time, function()
                table.insert(ccqueue, {"timer", id})
            end)
            return id
        end,
        queueEvent = function(name, ...)
            table.insert(ccqueue, {name, ...})
        end
    },
    parallel = {
        waitForAny = function(...)
            local threads = {}

            for k, v in pairs({...}) do
                table.insert(threads, thread.create(v))
            end

            while true do
                local isBreak
                for k, v in pairs(threads) do
                    if v:status() == "dead" then
                        isBreak = true
                        break
                    end
                end
                if isBreak then
                    break
                end
            end

            for k, v in pairs(threads) do
                v:kill()
            end
        end,
        waitForAll = function(...)
            local threads = {}

            for k, v in pairs({...}) do
                table.insert(threads, thread.create(v))
            end

            repeat
                local activeThread
                for k, v in pairs(threads) do
                    if v:status() ~= "dead" then
                        activeThread = true
                        break
                    end
                end
            until not activeThread

            for k, v in pairs(threads) do
                v:kill()
            end
        end
    },
    shell = {
        --resolve = shell.resolve,
        openTab = function(name, ...)
            --shell.execute(name, env, ...)
            return 0
        end,
        switchTab = function(num)
        end,
        getRunningProgram = function ()
            return selfpath
        end
    },
    peripheral = { --заглушка
        isPresent = function()
            return false
        end,
        getType = function()
            return nil
        end,
        getMethods = function()
            return nil
        end,
        call = function()
            return nil
        end,
        wrap = function()
            return nil
        end,
        find = function()
            return nil
        end,
        getNames = function()
            return {}
        end
    },
    settings = {
        set = function()
        end,
        get = function()
        end,
        unset = function()
        end,
        clear = function()
        end,
        getNames = function()
            return {}
        end,
        load = function()
            return false
        end,
        save = function()
            return false
        end
    },

    paintutils = {
        drawPixel = function (x, y, col)
            env.term.setBackgroundColor(col)
            env.term.setCursorPos(x, y)
            env.term.write(" ")
        end,
    },

    write = function (...)
        env.term.write(...)
    end,
    print = function (...)
        env.term.write(...)
    end,

    io = {

    },
    --io = io,

    sleep = event.sleep,
    colors = colors,
    keys = keyboard.keys,
    --exit = os.exit,
    
    math = math,
    bit = bit32,
    bit32 = bit32,
    type = type,
    string = string,
    table = table,
    tonumber = tonumber,
    tostring = tostring,
    ipairs = ipairs,
    pairs = pairs,
    pcall = pcall,
    xpcall = xpcall,
    error = error,
    debug = debug,
    load = load,
    loadfile = loadfile,
    dofile = dofile,
    assert = assert,
    checkArg = checkArg,
    utf8 = utf8,
    getmetatable = getmetatable,
    setmetatable = setmetatable,
    select = select,
    next = next,
}

env.keys.leftCtrl = env.keys.lcontrol
env.keys.rightCtrl = env.keys.rcontrol
env.keys.backspace = env.keys.back

env.os.pullEventRaw = env.os.pullEvent

env.colours = env.colors
env.term.isColour = env.term.isColor
env.term.setBackgroundColour = env.term.setBackgroundColor
env.term.setTextColour = env.term.setTextColor
env.term.getBackgroundColour = env.term.getBackgroundColor
env.term.getTextColour = env.term.getTextColor

env._G = env

--------------------------------------------

local func = assert(load(programmData, nil, nil, env))

local ok, err = pcall(func, ...)
if not ok then
    if err == "interrupted" then
        return
    else
        error(err, 0)
    end
end