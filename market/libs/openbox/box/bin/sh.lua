local shell = require("shell")
local tty = require("tty")
local text = require("text")
local sh = require("sh")
local fs = require("filesystem")
local process = require("process")
local computer = require("computer")

local args = shell.parse(...)

shell.prime()

if #args == 0 then
  local has_profile
  local input_handler = {hint = sh.hintHandler}
  while true do
    if io.stdin.tty and io.stdout.tty then
      if not has_profile then -- first time run AND interactive
        has_profile = true

        if tty.isAvailable() then
          if io.stdout.tty then
            io.write("\27[40m\27[37m")
            tty.clear()
          end
        end

        shell.setAlias("dir", "ls")
        shell.setAlias("move", "mv")
        shell.setAlias("rename", "mv")
        shell.setAlias("copy", "cp")
        shell.setAlias("del", "rm")
        shell.setAlias("md", "mkdir")
        shell.setAlias("cls", "clear")
        shell.setAlias("rs", "redstone")
        shell.setAlias("view", "edit -r")
        shell.setAlias("help", "man")
        shell.setAlias("l", "ls -lhp")
        shell.setAlias("..", "cd ..")
        shell.setAlias("df", "df -h")
        shell.setAlias("grep", "grep --color")
        shell.setAlias("more", "less --noback")
        shell.setAlias("reset", "resolution `cat /dev/components/by-type/gpu/0/maxResolution`")

        os.setenv("EDITOR", "/bin/edit")
        os.setenv("HISTSIZE", "10")
        os.setenv("HOME", "/home")
        os.setenv("IFS", " ")
        os.setenv("MANPATH", "/usr/man:.")
        os.setenv("PAGER", "less")
        os.setenv("PS1", "\27[40m\27[31m$HOSTNAME$HOSTNAME_SEPARATOR$PWD # \27[37m")
        os.setenv("LS_COLORS", "di=0;36:fi=0:ln=0;33:*.lua=0;32")

        shell.setWorkingDirectory("/")
      end
      if tty.getCursor() > 1 then
        io.write("\n")
      end
      io.write(sh.expand(os.getenv("PS1") or "$ "))
    end
    fs.mount(os.progfs, "/home")
    local co = process.load(os.program, _ENV, nil, nil, function (err)
      os.progerror = err
      computer.shutdown()
    end)
    while true do
      coroutine.resume(co)
    end
  end
else
  -- execute command.
  return sh.execute(...)
end
