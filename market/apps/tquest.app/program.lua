-- ╭━━━╮╱╱╱╭╮╱╱╭╮╱╱╱╱╭━━┳━━━━╮
-- ┃╭━╮┃╱╱╱┃┃╱╱┃┃╱╱╱╱┃╭╮┃╭╮╭╮┃
-- ┃┃╱╰╋╮╭┳┫┃╭━╯┃╱╱╱╱┃╰╯╰┫┃┃╰╋━┳╮╭╮
-- ┃┃╭━┫┃┃┣┫┃┃╭╮┃╭━━╮┃╭━╮┃┃┃╱┃╭┫┃┃┃
-- ┃╰┻━┃╰╯┃┃╰┫╰╯┃╰━━╯┃╰━╯┃┃┃╭┫┃┃╰╯┃
-- ╰━━━┻━━┻┻━┻━━╯╱╱╱╱╰━━━╯╰╯╰┻╯╰━━╯
-- Создано на проекте ГБТ игроком MineCR
-- если нужен найдите меня на сервере Квантум guild-bt.ru
local gpu = require("component").gpu
local event = require("event")
-- local image = require("image")
-- local ecs = require("ECSAPI")
local term = require("term")

local function intro()
    term.clear()
    term.setCursor(1, 3)
    print("     █████   █    ██ ▓█████   ██████ ▄▄▄█████▓")
    print("   ▒██▓  ██▒ ██  ▓██▒▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒")
    print("   ▒██▒  ██░▓██  ▒██░▒███   ░ ▓██▄   ▒ ▓██░ ▒░")
    print("   ░██  █▀ ░▓▓█  ░██░▒▓█  ▄   ▒   ██▒░ ▓██▓ ░ ")
    print("   ░▒███▒█▄ ▒▒█████▓ ░▒████▒▒██████▒▒  ▒██▒ ░ ")
    print("   ░░ ▒▒░ ▒ ░▒▓▒ ▒ ▒ ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ")
    print("    ░ ▒░  ░ ░░▒░ ░ ░  ░ ░  ░░ ░▒  ░ ░    ░    ")
    print("      ░   ░  ░░░ ░ ░    ░   ░  ░  ░    ░      ")
    print("       ░       ░        ░  ░      ░           ")
    print("                                              ")
    print("   -= " .. inttmp .. " =-")
    os.sleep(0.2)
    event.pull()

end

-- инфа чтоб не забыть 
-- 1-3 номер зап или предмет дефлт "0", 4-9 описание лок, 10-12 опис места
-- 13-17 выходы, 18 кол-во выходов от1до5, 19 кол-во мест от1до3 

local komnzap = {1, 3, 5, 6, 8, 13}

local room = {{"0", "0", "e", "Вы находитесь в коридоре.",
               "Позади находится дверь на улицу,",
               "слева кухня, справа спальня, перед",
               "Вами дверь в кабинет и лестница.",
               "У стены стоит тумба с телефоном,",
               "На полу грязный коврик.", "тумбочка с телефоном", "коврик",
               "входная дверь", 4, 2, 3, 5, 0, 4, 2},
              {"0", "0", "z", "Вы находитесь в кабинете.",
               "У окна находится стол с креслом,",
               "в углу кабинета стоит массивный", "сейф с кодовым замком.",
               "Вдоль стены стоит книжный шкаф",
               "уставленный множеством книг.", "книжный шкаф", "стол",
               "сейф", 1, 0, 0, 0, 0, 1, 2}, {"0", "0", "0", "Вы находитесь в спальне.",
                                                  "Посреди комнаты стоит кровать,",
                                                  "у стены находится шкаф-купе.",
                                                  "Также вы видите возле кровати",
                                                  "красивый торшер, наполняющий",
                                                  "комнату мягким светом.", "кровать",
                                                  "торшер", "шкаф-купе", 1, 0, 0, 0, 0, 1, 3},
              {"0", "0", "0", "Вы находитесь на кухне.",
               "Тут находится нехитрое кухонное",
               "убранство: стол со стульями,",
               "рукомойник и кухонный шкаф с",
               "различными тарелками, стаканами",
               "и банками с крупой. На полу люк", "стол", "кухонный шкаф",
               "рукомойник", 1, 6, 0, 0, 0, 2, 3},
              {"0", "0", "0", "Вы находитесь на чердаке.",
               "Окно на крышу выбито.", "В углу валяются коробки,",
               "к потолку подвешен старый", "велосипед, на полу лежат",
               "потрепанные валенки.", "старый велосипед", "коробки",
               "потрепанные валенки", 1, 8, 0, 0, 0, 2, 3},
              {"0", "0", "0", "Вы находитесь в подвале.",
               "Тут довольно сыро и темно,", "но вы разглядели ржавую",
               "стиральную машинку, кучу", "тряпья в корзине, а еще",
               "какой - то разлом в стене.", "стиралка", "куча шмоток", "", 4, 9,
               0, 0, 0, 2, 2},
              {"0", "0", "0", "Поздравляю Вы вышли из дома.",
               "На этом квест закончен.", "При следующем прохождении",
               "код от сейфа будет другим ))", "Спасибо за игру.",
               "..Нажмите любую клавишу..", "", "", "", 1, 0, 0, 0, 0, 1, 1},
              {"0", "0", "0", "Вы находитесь на крыше.", "Осторожно не упадите!",
               "В центре возвышается", "кирпичная труба камина.",
               "А у самого края свили", "гнездо какие-то птицы.",
               "труба камина", "гнездо", "", 5, 0, 0, 0, 0, 1, 2},
              {"0", "0", "0", "Позади остался подвал.",
               "Вы находитесь в разломе.", "Тут очень тесно и почти",
               "ничего не видно.", "Но впереди проход достаточно",
               "расширяется и видно развилку.", "", "", "", 6, 10, 0, 0, 0, 2, 0},
              {"0", "0", "0", "Пещера резко расширилась.",
               "Тут намного свободнее.", "Перед вами развилка, из",
               "правой пещеры слышатся шорохи.",
               "Левая же уходит резко вниз", "и где-то внизу виден свет.", "",
               "", "", 9, 11, 12, 0, 0, 3, 0},
              {"0", "0", "0", "Спуск вниз достаточно крутой,",
               "но торчащие корни дерева", "помогают Вам не сорваться.",
               "Впереди уже заметно светлее и",
               "можно разглядеть просторный",
               "грот, развилка осталась позади", "", "", "", 10, 13, 0, 0, 0, 2, 0},
              {"0", "0", "0", "В темноте Вы нащупали стену",
               "и какое-то углубление в ней.",
               "В этой нише оказалась шкатулка",
               "В углу слышны похрипывания.",
               "Ногой Вы случайно толкнули",
               "на тусклый свет старый череп", "шкатулка", "старый череп",
               "", 10, 0, 0, 0, 0, 1, 2}, {"0", "0", "0", "Посреди грота горит костер.",
                                           "Возле него, на большом камне",
                                           "лежит рюкзак и термос.",
                                           "В термосе еще теплый кофе.",
                                           "В дальнем углу свалена куча",
                                           "разного мусора и хлама.", "рюкзак", "хлам", "",
                                           11, 0, 0, 0, 0, 1, 2}}

local cmnd = {}
local num = 1
local numc = 1
invent = {"[инвентарь:]"}
intab = 1
exkey = 0

x = 1
oldxscr, oldyscr = gpu.getResolution()
gpu.setResolution(50, 16)

local function disps()
    term.clear()
    for str = 1, 50 do
        term.setCursor(str, 1)
        print("═")
        term.setCursor(str, 8)
        print("═")
    end
    for str = 2, 15 do
        term.setCursor(35, str)
        print("║")
    end
    term.setCursor(20, 1)
    print("[ TQueST ]")
    term.setCursor(35, 1)
    print("╦")
    term.setCursor(35, 8)
    print("╬")
end

local function setroom()
    itmp = room[x][rtmp]
    if itmp == 1 then
        ptmp = "коридор"
    elseif itmp == 2 then
        ptmp = "кабинет"
    elseif itmp == 3 then
        ptmp = "спальня"
    elseif itmp == 4 then
        ptmp = "кухня"
    elseif itmp == 5 then
        ptmp = "чердак"
    elseif itmp == 6 then
        ptmp = "подвал"
    elseif itmp == 8 then
        ptmp = "крыша"
    elseif itmp == 9 then
        ptmp = "разлом"
    elseif itmp == 10 then
        ptmp = "развилка"
    elseif itmp == 11 then
        ptmp = "спуск вниз"
    elseif itmp == 12 then
        ptmp = "пещера"
    elseif itmp == 13 then
        ptmp = "грот"

    end
end

local function dispt()
    cmnd = {}
    num = 1
    numc = 1
    for str = 1, 3 do
        -- cmnd[num] = room[x][str]
        num = num + 1
        term.setCursor(3, 8 + str)
        print("осмотреть: " .. room[x][9 + str])
    end
    for str = 4, 9 do
        term.setCursor(1, str - 2)
        print(room[x][str])
    end
    for str = 1, room[x][18] do
        cmnd[numc] = room[x][12 + str]
        numc = numc + 1
        num = num + 1
        rtmp = 12 + str
        term.setCursor(3, 11 + str)
        setroom()
        print("идти: " .. ptmp)
    end
    for str = 1, intab do
        term.setCursor(37, 7 + str)
        print(invent[str])
    end
end

local function setrnd()
    komnzap[1] = math.random(1, 2)
    komnzap[2] = math.random(3, 4)
    komnzap[6] = math.random(12, 13)

    kods = ""
    for kk = 1, 6 do
        tmp1 = komnzap[kk]
        tmp2 = math.random(1, room[tmp1][19])
        room[tmp1][tmp2] = tostring(math.ceil(math.random(1, 9)))
        kods = kods .. room[tmp1][tmp2]
        room[tmp1][tmp2] = kk .. "=" .. room[tmp1][tmp2]
    end
    -- intab = intab + 1
    -- invent[intab] = kods
    -- print (kods)
    -- os.sleep(2)
end

local function osmotr()
    term.setCursor(36, 2)
    print(osp1)
    term.setCursor(36, 3)
    print(osp2)
    os.sleep(1.5)
end

local function fsafe()
    term.setCursor(31, 2)
    print("╔══════════════════")
    term.setCursor(31, 3)
    print("║  ВВЕДИТЕ ПАРОЛЬ  ")
    term.setCursor(31, 4)
    print("║          ")
    term.setCursor(31, 5)
    print("╚══════════════════")
    term.setCursor(37, 4)
    -- os.sleep(0.2)
    -- pass2 = ""
    -- expass = 1
    -- str = 1
    -- while expass == 1 or str < 7 do
    -- local ev = {event.pull()}
    -- if ev[1] == "key_down" then
    --  if ev[4] == 28 then
    -- expass = 0
    --  end
    -- else
    --  term.setCursor(16+str,7)
    --  print(string.char(ev[4]))
    --  str = str + 1
    --  pass2 = pass2..tostring(string.char(ev[4]))
    -- end
    -- end
    pass2 = tostring(io.read())
    disps()
    if pass2 == kods then
        exkey = 1
        intab = intab + 1
        invent[intab] = "ключ"
        room[x][3] = "0"
    end
end

local function scancom()
    if setcur <= 3 then
        if room[x][setcur] == "0" then
            osp1 = "Вы ничего"
            osp2 = "не нашли"
        elseif room[x][setcur] == "z" then
            fsafe()
            if exkey == 1 then
                osp1 = "Ну вот"
                osp2 = "и открыл"
            else
                osp1 = "Сложная"
                osp2 = "задачка"
            end
        elseif room[x][setcur] == "e" then
            if exkey == 1 then
                x = 7
                room[1][3] = "0"
                osp1 = "Ура"
                osp2 = "Вы вышли"
            else
                osp1 = "Вам нужен"
                osp2 = "ключ!!"
            end
        else
            intab = intab + 1
            invent[intab] = "Записка: " .. room[x][setcur]
            room[x][setcur] = "0"
            osp1 = "Вы нашли"
            osp2 = invent[intab]
        end
        osmotr()
    else
        -- print (cmnd[setcur-3])
        x = cmnd[setcur - 3]
        setcur = 1
    end
end

setrnd()
inttmp = "для старта игры нажмите любую клавишу"
intro()
disps()
dispt()
os.sleep(0.2)
setcur = 1

function redisp()
    disps()
    dispt()
    os.sleep(0.2)
    term.setCursor(1, setcur + 8)
    print(">>")
end

function recurs()
    for icur = 1, 7 do
        term.setCursor(1, 8 + icur)
        print("  ")
        term.setCursor(1, setcur + 8)
        print(">>")
    end
end

recurs()
while room[1][3] == "e" do
    local e = {event.pull()}
    if e[1] == "key_down" then
        if e[4] == 208 then
            setcur = setcur + 1
            if setcur > num - 1 then
                setcur = 1
            end

        end
        if e[4] == 200 then
            setcur = setcur - 1
            if setcur < 1 then
                setcur = num - 1
            end

        end
    end
    if e[4] == 28 then
        scancom()
        redisp()

    end
    if e[4] == 16 or e[4] == 211 then
        goto quit
    end
    recurs()
    for str = 1, numc do
        -- print(cmnd[str])
    end
    os.sleep(0.1)
    -- event.pull()
    -- room[1][3] = "w"
end

x = 7
disps()
dispt()
os.sleep(2)
event.pull()
inttmp = "  Вы выиграли, нажмите любую клавишу  "
intro()
::quit::
term.clear()
print("Приходите еще..")
gpu.setResolution(oldxscr, oldyscr)
