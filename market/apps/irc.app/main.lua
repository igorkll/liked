local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local graphic = require("graphic")
local colors = require("gui_container").colors
local event = require("event")

local screen, isInit = ...

if not component.list("internet")() then
  gui_warn(screen, nil, nil, "OpenIRC requires an Internet Card to run!\n")
  return
end

local event = require("event")
--local internet = require("internet")
--local shell = require("shell")
--local term = require("term")








local buffer = {}
local metatable = {
  __index = buffer,
  __metatable = "file"
}

function buffer.new(mode, stream)
  local result = {
    closed = false,
    tty = false,
    mode = {},
    stream = stream,
    bufferRead = "",
    bufferWrite = "",
    bufferSize = math.max(512, math.min(8 * 1024, computer.freeMemory() / 8)),
    bufferMode = "full",
    readTimeout = math.huge,
  }
  mode = mode or "r"
  for i = 1, unicode.len(mode) do
    result.mode[unicode.sub(mode, i, i)] = true
  end
  -- when stream closes, result should close first
  -- when result closes, stream should close after
  -- when stream closes, it is removed from the proc
  stream.close = setmetatable({close = stream.close,parent = result},{__call = buffer.close})
  return setmetatable(result, metatable)
end

function buffer:close()
  -- self is either the buffer, or the stream.close callable
  local meta = getmetatable(self)
  if meta == metatable.__metatable then
    return self.stream:close()
  end
  local parent = self.parent

  if parent.mode.w or parent.mode.a then
    parent:flush()
  end
  parent.closed = true
  return self.close(parent.stream)
end

function buffer:flush()
  if #self.bufferWrite > 0 then
    local tmp = self.bufferWrite
    self.bufferWrite = ""
    local result, reason = self.stream:write(tmp)
    if not result then
      return nil, reason or "bad file descriptor"
    end
  end

  return self
end

function buffer:lines(...)
  local args = table.pack(...)
  return function()
    local result = table.pack(self:read(table.unpack(args, 1, args.n)))
    if not result[1] and result[2] then
      error(result[2])
    end
    return table.unpack(result, 1, result.n)
  end
end

local function readChunk(self)
  if computer.uptime() > self.timeout then
    error("timeout")
  end
  local result, reason = self.stream:read(math.max(1,self.bufferSize))
  if result then
    self.bufferRead = self.bufferRead .. result
    return self
  else -- error or eof
    return result, reason
  end
end

function buffer:readLine(chop, timeout)
  self.timeout = timeout or (computer.uptime() + self.readTimeout)
  local start = 1
  while true do
    local buf = self.bufferRead
    local i = buf:find("[\r\n]", start)
    local c = i and buf:sub(i,i)
    local is_cr = c == "\r"
    if i and (not is_cr or i < #buf) then
      local n = buf:sub(i+1,i+1)
      if is_cr and n == "\n" then
        c = c .. n
      end
      local result = buf:sub(1, i - 1) .. (chop and "" or c)
      self.bufferRead = buf:sub(i + #c)
      return result
    else
      start = #self.bufferRead - (is_cr and 1 or 0)
      local result, reason = readChunk(self)
      if not result then
        if reason then
          return result, reason
        else -- eof
          result = #self.bufferRead > 0 and self.bufferRead or nil
          self.bufferRead = ""
          return result
        end
      end
    end
  end
end

function buffer:read(...)
  if not self.mode.r then
    return nil, "read mode was not enabled for this stream"
  end

  if self.mode.w or self.mode.a then
    self:flush()
  end

  if select("#", ...) == 0 then
    return self:readLine(true)
  end
  return self:formatted_read(readChunk, ...)
end

function buffer:setvbuf(mode, size)
  mode = mode or self.bufferMode
  size = size or self.bufferSize

  assert(mode == "no" or mode == "full" or mode == "line",
    "bad argument #1 (no, full or line expected, got " .. tostring(mode) .. ")")
  assert(mode == "no" or type(size) == "number",
    "bad argument #2 (number expected, got " .. type(size) .. ")")

  self.bufferMode = mode
  self.bufferSize = size

  return self.bufferMode, self.bufferSize
end

function buffer:write(...)
  if self.closed then
    return nil, "bad file descriptor"
  end
  if not self.mode.w and not self.mode.a then
    return nil, "write mode was not enabled for this stream"
  end
  local args = table.pack(...)
  for i = 1, args.n do
    if type(args[i]) == "number" then
      args[i] = tostring(args[i])
    end
    checkArg(i, args[i], "string")
  end

  for i = 1, args.n do
    local arg = args[i]
    local result, reason

    if self.bufferMode == "no" then
      result, reason = self.stream:write(arg)
    else
      result, reason = self:buffered_write(arg)
    end

    if not result then
      return nil, reason
    end
  end

  return self
end

--require("package").delay(buffer, "/lib/core/full_buffer.lua")










function buffer:getTimeout()
    return self.readTimeout
  end
  
  function buffer:setTimeout(value)
    self.readTimeout = tonumber(value)
  end
  
  function buffer:seek(whence, offset)
    whence = tostring(whence or "cur")
    assert(whence == "set" or whence == "cur" or whence == "end",
      "bad argument #1 (set, cur or end expected, got " .. whence .. ")")
    offset = offset or 0
    checkArg(2, offset, "number")
    assert(math.floor(offset) == offset, "bad argument #2 (not an integer)")
  
    if self.mode.w or self.mode.a then
      self:flush()
    elseif whence == "cur" then
      offset = offset - #self.bufferRead
    end
    local result, reason = self.stream:seek(whence, offset)
    if result then
      self.bufferRead = ""
      return result
    else
      return nil, reason
    end
  end
  
  function buffer:buffered_write(arg)
    local result, reason
    if self.bufferMode == "full" then
      if self.bufferSize - #self.bufferWrite < #arg then
        result, reason = self:flush()
        if not result then
          return nil, reason
        end
      end
      if #arg > self.bufferSize then
        result, reason = self.stream:write(arg)
      else
        self.bufferWrite = self.bufferWrite .. arg
        result = self
      end
    else--if self.bufferMode == "line" then
      local l
      repeat
        local idx = arg:find("\n", (l or 0) + 1, true)
        if idx then
          l = idx
        end
      until not idx
      if l or #arg > self.bufferSize then
        result, reason = self:flush()
        if not result then
          return nil, reason
        end
      end
      if l then
        result, reason = self.stream:write(arg:sub(1, l))
        if not result then
          return nil, reason
        end
        arg = arg:sub(l + 1)
      end
      if #arg > self.bufferSize then
        result, reason = self.stream:write(arg)
      else
        self.bufferWrite = self.bufferWrite .. arg
        result = self
      end
    end
    return result, reason
  end
  
  ----------------------------------------------------------------------------------------------
  
  function buffer:readNumber(readChunk)
    local len, sub
    if self.mode.b then
      len = rawlen
      sub = string.sub
    else
      len = unicode.len
      sub = unicode.sub
    end
  
    local number_text = ""
    local white_done
  
    local function peek()
      if len(self.bufferRead) == 0 then
        local result, reason = readChunk(self)
        if not result then
          return result, reason
        end
      end
      return sub(self.bufferRead, 1, 1)
    end
  
    local function pop()
      local n = sub(self.bufferRead, 1, 1)
      self.bufferRead = sub(self.bufferRead, 2)
      return n
    end
  
    while true do
      local peeked = peek()
      if not peeked then
        break
      end
  
      if peeked:match("[%s]") then
        if white_done then
          break
        end
        pop()
      else
        white_done = true
        if not tonumber(number_text .. peeked .. "0") then
          break
        end
        number_text = number_text .. pop() -- add pop to number_text
      end
    end
  
    return tonumber(number_text)
  end
  
  function buffer:readBytesOrChars(readChunk, n)
    n = math.max(n, 0)
    local len, sub
    if self.mode.b then
      len = rawlen
      sub = string.sub
    else
      len = unicode.len
      sub = unicode.sub
    end
    local data = ""
    while len(data) ~= n do
      if len(self.bufferRead) == 0 then
        local result, reason = readChunk(self)
        if not result then
          if reason then
            return result, reason
          else -- eof
            return #data > 0 and data or nil
          end
        end
      end
      local left = n - len(data)
      data = data .. sub(self.bufferRead, 1, left)
      self.bufferRead = sub(self.bufferRead, left + 1)
    end
    return data
  end
  
  function buffer:readAll(readChunk)
    repeat
      local result, reason = readChunk(self)
      if not result and reason then
        return result, reason
      end
    until not result -- eof
    local result = self.bufferRead
    self.bufferRead = ""
    return result
  end
  
  function buffer:formatted_read(readChunk, ...)
    self.timeout = require("computer").uptime() + self.readTimeout
    local function read(n, format)
      if type(format) == "number" then
        return self:readBytesOrChars(readChunk, format)
      else
        local first_char_index = 1
        if type(format) ~= "string" then
          error("bad argument #" .. n .. " (invalid option)")
        elseif unicode.sub(format, 1, 1) == "*"  then
          first_char_index = 2
        end
        format = unicode.sub(format, first_char_index, first_char_index)
        if format == "n" then
          return self:readNumber(readChunk)
        elseif format == "l" then
          return self:readLine(true, self.timeout)
        elseif format == "L" then
          return self:readLine(false, self.timeout)
        elseif format == "a" then
          return self:readAll(readChunk)
        else
          error("bad argument #" .. n .. " (invalid format)")
        end
      end
    end
  
    local results = {}
    local formats = table.pack(...)
    for i = 1, formats.n do
      local result, reason = read(i, formats[i])
      if result then
        results[i] = result
      elseif reason then
        return nil, reason
      end
    end
    return table.unpack(results, 1, formats.n)
  end
  
  function buffer:size()
    local len = self.mode.b and rawlen or unicode.len
    local size = len(self.bufferRead)
    if self.stream.size then
      size = size + self.stream:size()
    end
    return size
  end
  














local internet = {}

-------------------------------------------------------------------------------

function internet.request(url, data, headers, method)
  checkArg(1, url, "string")
  checkArg(2, data, "string", "table", "nil")
  checkArg(3, headers, "table", "nil")
  checkArg(4, method, "string", "nil")

  if not component.isAvailable("internet") then
    error("no primary internet card found", 2)
  end
  local inet = component.proxy(component.list("internet")())

  local post
  if type(data) == "string" then
    post = data
  elseif type(data) == "table" then
    for k, v in pairs(data) do
      post = post and (post .. "&") or ""
      post = post .. tostring(k) .. "=" .. tostring(v)
    end
  end

  local request, reason = inet.request(url, post, headers, method)
  if not request then
    error(reason, 2)
  end

  return setmetatable(
  {
    ["()"] = "function():string -- Tries to read data from the socket stream and return the read byte array.",
    close = setmetatable({},
    {
      __call = request.close,
      __tostring = function() return "function() -- closes the connection" end
    })
  },
  {
    __call = function()
      while true do
        local data, reason = request.read()
        if not data then
          request.close()
          if reason then
            error(reason, 2)
          else
            return nil -- eof
          end
        elseif #data > 0 then
          return data
        end
        -- else: no data, block
        os.sleep(0)
      end
    end,
    __index = request,
  })
end

-------------------------------------------------------------------------------

local socketStream = {}

function socketStream:close()
  if self.socket then
    self.socket.close()
    self.socket = nil
  end
end

function socketStream:seek()
  return nil, "bad file descriptor"
end

function socketStream:read(n)
  if not self.socket then
    return nil, "connection is closed"
  end
  return self.socket.read(n)
end

function socketStream:write(value)
  if not self.socket then
    return nil, "connection is closed"
  end
  while #value > 0 do
    local written, reason = self.socket.write(value)
    if not written then
      return nil, reason
    end
    value = string.sub(value, written + 1)
  end
  return true
end

function internet.socket(address, port)
  checkArg(1, address, "string")
  checkArg(2, port, "number", "nil")
  if port then
    address = address .. ":" .. port
  end

  local inet = component.proxy(component.list("internet")())
  local socket, reason = inet.connect(address)
  if not socket then
    return nil, reason
  end

  local stream = {inet = inet, socket = socket}
  local metatable = {__index = socketStream,
                     __metatable = "socketstream"}
  return setmetatable(stream, metatable)
end

function internet.open(address, port)
  local stream, reason = internet.socket(address, port)
  if not stream then
    return nil, reason
  end
  return buffer.new("rwb", stream)
end






local text = {}
text.internal = {}

text.syntax = {"^%d?>>?&%d+","^%d?>>?",">>?","<%&%d+","<",";","&&","||?"}

function text.trim(value) -- from http://lua-users.org/wiki/StringTrim
  local from = string.match(value, "^%s*()")
  return from > #value and "" or string.match(value, ".*%S", from)
end

-- used by lib/sh
function text.escapeMagic(txt)
  return txt:gsub('[%(%)%.%%%+%-%*%?%[%^%$]', '%%%1')
end

function text.removeEscapes(txt)
  return txt:gsub("%%([%(%)%.%%%+%-%*%?%[%^%$])","%1")
end

function text.internal.tokenize(value, options)
  checkArg(1, value, "string")
  checkArg(2, options, "table", "nil")
  options = options or {}
  local delimiters = options.delimiters
  local custom = not not options.delimiters
  delimiters = delimiters or text.syntax

  local words, reason = text.internal.words(value, options)

  local splitter = text.escapeMagic(custom and table.concat(delimiters) or "<>|;&")
  if type(words) ~= "table" or 
    #splitter == 0 or
    not value:find("["..splitter.."]") then
    return words, reason
  end

  return text.internal.splitWords(words, delimiters)
end

-- tokenize input by quotes and whitespace
function text.internal.words(input, options)
  checkArg(1, input, "string")
  checkArg(2, options, "table", "nil")
  options = options or {}
  local quotes = options.quotes
  local show_escapes = options.show_escapes
  local qr = nil
  quotes = quotes or {{"'","'",true},{'"','"'},{'`','`'}}
  local function append(dst, txt, _qr)
    local size = #dst
    if size == 0 or dst[size].qr ~= _qr then
      dst[size+1] = {txt=txt, qr=_qr}
    else
      dst[size].txt = dst[size].txt..txt
    end
  end
  -- token meta is {string,quote rule}
  local tokens, token = {}, {}
  local escaped, start = false, -1
  for i = 1, unicode.len(input) do
    local char = unicode.sub(input, i, i)
    if escaped then -- escaped character
      escaped = false
      -- include escape char if show_escapes
      -- or the followwing are all true
      -- 1. qr active
      -- 2. the char escaped is NOT the qr closure
      -- 3. qr is not literal
      if show_escapes or (qr and not qr[3] and qr[2] ~= char) then
        append(token, '\\', qr)
      end
      append(token, char, qr)
    elseif char == "\\" and (not qr or not qr[3]) then
        escaped = true
    elseif qr and qr[2] == char then -- end of quoted string
      -- if string is empty, we can still capture a quoted empty arg
      if #token == 0 or #token[#token] == 0 then
        append(token, '', qr)
      end
      qr = nil
    elseif not qr and tx.first(quotes,function(Q)
      qr=Q[1]==char and Q or nil return qr end) then
      start = i
    elseif not qr and string.find(char, "%s") then
      if #token > 0 then
        table.insert(tokens, token)
      end
      token = {}
    else -- normal char
      append(token, char, qr)
    end
  end
  if qr then
    return nil, "unclosed quote at index " .. start
  end

  if #token > 0 then
    table.insert(tokens, token)
  end

  return tokens
end

-- separate string value into an array of words delimited by whitespace
-- groups by quotes
-- options is a table used for internal undocumented purposes
function text.tokenize(value, options)
  checkArg(1, value, "string")
  checkArg(2, options, "table", "nil")
  options = options or {}

  local tokens, reason = text.internal.tokenize(value, options)

  if type(tokens) ~= "table" then
    return nil, reason
  end

  if options.doNotNormalize then
    return tokens
  end

  return text.internal.normalize(tokens)
end

-------------------------------------------------------------------------------
-- like tokenize, but does not drop any text such as whitespace
-- splits input into an array for sub strings delimited by delimiters
-- delimiters are included in the result if not dropDelims
function text.split(input, delimiters, dropDelims, di)
  checkArg(1, input, "string")
  checkArg(2, delimiters, "table")
  checkArg(3, dropDelims, "boolean", "nil")
  checkArg(4, di, "number", "nil")

  if #input == 0 then return {} end
  di = di or 1
  local result = {input}
  if di > #delimiters then return result end

  local function add(part, index, r, s, e)
    local sub = part:sub(s,e)
    if #sub == 0 then return index end
    local subs = r and text.split(sub,delimiters,dropDelims,r) or {sub}
    for i=1,#subs do
      table.insert(result, index+i-1, subs[i])
    end
    return index+#subs
  end

  local i,d=1,delimiters[di]
  while true do
    local next = table.remove(result,i)
    if not next then break end
    local si,ei = next:find(d)
    if si and ei and ei~=0 then -- delim found
      i=add(next, i, di+1, 1, si-1)
      i=dropDelims and i or add(next, i, false, si, ei)
      i=add(next, i, di, ei+1)
    else
      i=add(next, i, di+1, 1, #next)
    end
  end
  
  return result
end

-----------------------------------------------------------------------------

-- splits each word into words at delimiters
-- delimiters are kept as their own words
-- quoted word parts are not split
function text.internal.splitWords(words, delimiters)
  checkArg(1,words,"table")
  checkArg(2,delimiters,"table")

  local split_words = {}
  local next_word
  local function add_part(part)
    if next_word then
      split_words[#split_words+1] = {}
    end
    table.insert(split_words[#split_words], part)
    next_word = false
  end
  for wi=1,#words do local word = words[wi]
    next_word = true
    for pi=1,#word do local part = word[pi]
      local qr = part.qr
      if qr then
        add_part(part)
      else
        local part_text_splits = text.split(part.txt, delimiters)
        tx.foreach(part_text_splits, function(sub_txt)
          local delim = #text.split(sub_txt, delimiters, true) == 0
          next_word = next_word or delim
          add_part({txt=sub_txt,qr=qr})
          next_word = delim
        end)
      end
    end
  end

  return split_words
end

function text.internal.normalize(words, omitQuotes)
  checkArg(1, words, "table")
  checkArg(2, omitQuotes, "boolean", "nil")
  local norms = {}
  for _,word in ipairs(words) do
    local norm = {}
    for _,part in ipairs(word) do
      norm = tx.concat(norm, not omitQuotes and part.qr and {part.qr[1], part.txt, part.qr[2]} or {part.txt})
    end
    norms[#norms+1]=table.concat(norm)
  end
  return norms
end

function text.internal.stream_base(binary)
  return
  {
    binary = binary,
    plen = binary and string.len or unicode.len,
    psub = binary and string.sub or unicode.sub,
    seek = function (handle, whence, to)
      if not handle.txt then
        return nil, "bad file descriptor"
      end
      to = to or 0
      local offset = handle:indexbytes()
      if whence == "cur" then
        offset = offset + to
      elseif whence == "set" then
        offset = to
      elseif whence == "end" then
        offset = handle.len + to
      end
      offset = math.max(0, math.min(offset, handle.len))
      handle:byteindex(offset)
      return offset
    end,
    indexbytes = function (handle)
      return handle.psub(handle.txt, 1, handle.index):len()
    end,
    byteindex = function (handle, offset)
      local sub = string.sub(handle.txt, 1, offset)
      handle.index = handle.plen(sub)
    end,
  }
end

function text.internal.reader(txt, mode)
  checkArg(1, txt, "string")
  local reader = setmetatable(
  {
    txt = txt,
    len = string.len(txt),
    index = 0,
    read = function(_, n)
      checkArg(1, n, "number")
      if not _.txt then
        return nil, "bad file descriptor"
      end
      if _.index >= _.plen(_.txt) then
        return nil
      end
      local next = _.psub(_.txt, _.index + 1, _.index + n)
      _.index = _.index + _.plen(next)
      return next
    end,
    close = function(_)
      if not _.txt then
        return nil, "bad file descriptor"
      end
      _.txt = nil
      return true
    end,
  }, {__index=text.internal.stream_base((mode or ""):match("b"))})

  return require("buffer").new("r", reader)
end

function text.internal.writer(ostream, mode, append_txt)
  if type(ostream) == "table" then
    local mt = getmetatable(ostream) or {}
    checkArg(1, mt.__call, "function")
  end
  checkArg(1, ostream, "function", "table")
  checkArg(2, append_txt, "string", "nil")
  local writer = setmetatable(
  {
    txt = "",
    index = 0, -- last location of write
    len = 0,
    write = function(_, ...)
      if not _.txt then
        return nil, "bad file descriptor"
      end
      local pre = _.psub(_.txt, 1, _.index)
      local vs = {}
      local pos = _.psub(_.txt, _.index + 1)
      for _,v in ipairs({...}) do
        table.insert(vs, v)
      end
      vs = table.concat(vs)
      _.index = _.index + _.plen(vs)
      _.txt = pre .. vs .. pos
      _.len = string.len(_.txt)
      return true
    end,
    close = function(_)
      if not _.txt then
        return nil, "bad file descriptor"
      end
      ostream((append_txt or "") .. _.txt)
      _.txt = nil
      return true
    end,
  }, {__index=text.internal.stream_base((mode or ""):match("b"))})

  return require("buffer").new("w", writer)
end

function text.detab(value, tabWidth)
  checkArg(1, value, "string")
  checkArg(2, tabWidth, "number", "nil")
  tabWidth = tabWidth or 8
  local function rep(match)
    local spaces = tabWidth - match:len() % tabWidth
    return match .. string.rep(" ", spaces)
  end
  local result = value:gsub("([^\n]-)\t", rep) -- truncate results
  return result
end

function text.padLeft(value, length)
  checkArg(1, value, "string", "nil")
  checkArg(2, length, "number")
  if not value or unicode.wlen(value) == 0 then
    return string.rep(" ", length)
  else
    return string.rep(" ", length - unicode.wlen(value)) .. value
  end
end

function text.padRight(value, length)
  checkArg(1, value, "string", "nil")
  checkArg(2, length, "number")
  if not value or unicode.wlen(value) == 0 then
    return string.rep(" ", length)
  else
    return value .. string.rep(" ", length - unicode.wlen(value))
  end
end

function text.wrap(value, width, maxWidth)
  checkArg(1, value, "string")
  checkArg(2, width, "number")
  checkArg(3, maxWidth, "number")
  local line, nl = value:match("([^\r\n]*)(\r?\n?)") -- read until newline
  if unicode.wlen(line) > width then -- do we even need to wrap?
    local partial = unicode.wtrunc(line, width)
    local wrapped = partial:match("(.*[^a-zA-Z0-9._()'`=])")
    if wrapped or unicode.wlen(line) > maxWidth then
      partial = wrapped or partial
      return partial, unicode.sub(value, unicode.len(partial) + 1), true
    else
      return "", value, true -- write in new line.
    end
  end
  local start = unicode.len(line) + unicode.len(nl) + 1
  return line, start <= unicode.len(value) and unicode.sub(value, start) or nil, unicode.len(nl) > 0
end

function text.wrappedLines(value, width, maxWidth)
  local line
  return function()
    if value then
      line, value = text.wrap(value, width, maxWidth)
      return line
    end
  end
end

--[[
local args, options = shell.parse(...)
if #args < 1 then
  print("Usage: irc <nickname> [server[:port] ]")
  return
end
]]

local nick = gui_input(screen, nil, nil, "nickname")
if not nick then
    return
end
local host = gui_input(screen, nil, nil, "host")
if not host then
    return
end

if not host:find(":") then
  host = host .. ":6667"
end

-- try to connect to server.
local sock, reason = internet.open(host)
if not sock then
  gui_warn(screen, nil, nil, reason .. "\n")
  return
end

local window = graphic.createWindow(screen, 1, 1, graphic.getResolution(screen))

-- custom print that uses all except the last line for printing.
local function print(message, overwrite)
    overwrite = false

    local gpu = graphic.findGpu(screen)
    gpu.setBackground(colors.white)
    gpu.setForeground(colors.black)
  local w, h = gpu.getResolution()
  local line
  repeat
    line, message = text.wrap(text.trim(message), w, w)
    if not overwrite then
      gpu.copy(1, 1, w, h - 1, 0, -1)
    end
    overwrite = false
    gpu.fill(1, h - 1, w, 1, " ")
    gpu.set(1, h - 1, line)
  until not message or message == ""
end

-- utility method for reply tracking tables.
function autocreate(table, key)
  table[key] = {}
  return table[key]
end

-- extract nickname from identity.
local function name(identity)
  return identity and identity:match("^[^!]+") or identity or "Anonymous"
end

-- user defined callback for messages (via `lua function(msg) ... end`)
local callback = nil

-- list of whois info per user (used to accumulate whois replies).
local whois = setmetatable({}, {__index=autocreate})

-- list of users per channel (used to accumulate names replies).
local names = setmetatable({}, {__index=autocreate})

-- timer used to drive socket reading.
local timer

-- ignored commands, reserved according to RFC.
-- http://tools.ietf.org/html/rfc2812#section-5.3
local ignore = {
  [213]=true, [214]=true, [215]=true, [216]=true, [217]=true,
  [218]=true, [231]=true, [232]=true, [233]=true, [240]=true,
  [241]=true, [244]=true, [244]=true, [246]=true, [247]=true,
  [250]=true, [300]=true, [316]=true, [361]=true, [362]=true,
  [363]=true, [373]=true, [384]=true, [492]=true,
  -- custom ignored responses.
  [265]=true, [266]=true, [330]=true
}

-- command numbers to names.
local commands = {
--Replys
  RPL_WELCOME = "001",
  RPL_YOURHOST = "002",
  RPL_CREATED = "003",
  RPL_MYINFO = "004",
  RPL_BOUNCE = "005",
  RPL_LUSERCLIENT = "251",
  RPL_LUSEROP = "252",
  RPL_LUSERUNKNOWN = "253",
  RPL_LUSERCHANNELS = "254",
  RPL_LUSERME = "255",
  RPL_AWAY = "301",
  RPL_UNAWAY = "305",
  RPL_NOWAWAY = "306",
  RPL_WHOISUSER = "311",
  RPL_WHOISSERVER = "312",
  RPL_WHOISOPERATOR = "313",
  RPL_WHOISIDLE = "317",
  RPL_ENDOFWHOIS = "318",
  RPL_WHOISCHANNELS = "319",
  RPL_CHANNELMODEIS = "324",
  RPL_NOTOPIC = "331",
  RPL_TOPIC = "332",
  RPL_NAMREPLY = "353",
  RPL_ENDOFNAMES = "366",
  RPL_MOTDSTART = "375",
  RPL_MOTD = "372",
  RPL_ENDOFMOTD = "376",
  RPL_WHOISSECURE = "671",
  RPL_HELPSTART = "704",
  RPL_HELPTXT = "705",
  RPL_ENDOFHELP = "706",
  RPL_UMODEGMSG = "718",
  
--Errors
  ERR_BANLISTFULL = "478",
  ERR_CHANNELISFULL = "471",
  ERR_UNKNOWNMODE = "472",
  ERR_INVITEONLYCHAN = "473",
  ERR_BANNEDFROMCHAN = "474",
  ERR_CHANOPRIVSNEEDED = "482",
  ERR_UNIQOPRIVSNEEDED = "485",
  ERR_USERNOTINCHANNEL = "441",
  ERR_NOTONCHANNEL = "442",
  ERR_NICKCOLLISION = "436",
  ERR_NICKNAMEINUSE = "433",
  ERR_ERRONEUSNICKNAME = "432",
  ERR_WASNOSUCHNICK = "406",
  ERR_TOOMANYCHANNELS = "405",
  ERR_CANNOTSENDTOCHAN = "404",
  ERR_NOSUCHCHANNEL = "403",
  ERR_NOSUCHNICK = "401",
  ERR_MODELOCK = "742"
}

-- main command handling callback.
local function handleCommand(prefix, command, args, message)
  ---------------------------------------------------
  -- Keepalive

  if command == "PING" then
    sock:write(string.format("PONG :%s\r\n", message))
    sock:flush()

  ---------------------------------------------------
  -- General commands
  elseif command == "NICK" then
    local oldNick, newNick = name(prefix), tostring(args[1] or message)
    if oldNick == nick then
      nick = newNick
    end
    print(oldNick .. " is now known as " .. newNick .. ".")
  elseif command == "MODE" then
    if #args == 2 then
      print("[" .. args[1] .. "] " .. name(prefix) .. " set mode".. ( #args[2] > 2 and "s" or "" ) .. " " .. tostring(args[2] or message) .. ".")
    else
      local setmode = {}
      local cumode = "+"
      args[2]:gsub(".", function(char)
        if char == "-" or char == "+" then
          cumode = char
        else
          table.insert(setmode, {cumode, char})
        end
      end)
      local d = {}
      local users = {}
      for i = 3, #args do
        users[i-2] = args[i]
      end
      users[#users+1] = message
      local last
      local ctxt = ""
      for c = 1, #users do
        if not setmode[c] then
          break
        end
        local mode = setmode[c][2]
        local pfx = setmode[c][1]=="+"
        local key = mode == "o" and (pfx and "opped" or "deoped") or
          mode == "v" and (pfx and "voiced" or "devoiced") or
          mode == "q" and (pfx and "quieted" or "unquieted") or
          mode == "b" and (pfx and "banned" or "unbanned") or
          "set " .. setmode[c][1] .. mode .. " on"
        if last ~= key then
          if last then
            print(ctxt)
          end
          ctxt = "[" .. args[1] .. "] " .. name(prefix) .. " " .. key
          last = key
        end
        ctxt = ctxt .. " " .. users[c]
      end
      if #ctxt > 0 then
        print(ctxt)
      end
    end
  elseif command == "QUIT" then
    print(name(prefix) .. " quit (" .. (message or "Quit") .. ").")
  elseif command == "JOIN" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " entered the room.")
  elseif command == "PART" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " has left the room (quit: " .. (message or "Quit") .. ").")
  elseif command == "TOPIC" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " has changed the topic to: " .. message)
  elseif command == "KICK" then
    print("[" .. args[1] .. "] " .. name(prefix) .. " kicked " .. args[2])
  elseif command == "PRIVMSG" then
    local ctcp = message:match("^\1(.-)\1$")
    if ctcp then
      print("[" .. name(prefix) .. "] CTCP " .. ctcp)
      local ctcp, param = ctcp:match("^(%S+) ?(.-)$")
      ctcp = ctcp:upper()
      if ctcp == "TIME" then
        sock:write("NOTICE " .. name(prefix) .. " :\001TIME " .. os.date() .. "\001\r\n")
        sock:flush()
      elseif ctcp == "VERSION" then
        sock:write("NOTICE " .. name(prefix) .. " :\001VERSION Minecraft/OpenComputers Lua 5.2\001\r\n")
        sock:flush()
      elseif ctcp == "PING" then
        sock:write("NOTICE " .. name(prefix) .. " :\001PING " .. param .. "\001\r\n")
        sock:flush()
      end
    else
      if string.find(message, nick) then
        computer.beep(2000, 0.01)
        computer.beep(2000, 0.01)
      else
        --computer.beep(2000, 0.01)
      end
      if string.find(message, "\001ACTION") then
        print("[" .. args[1] .. "] " .. name(prefix) .. string.gsub(string.gsub(message, "\001ACTION", ""), "\001", ""))
      else
        print("[" .. args[1] .. "] " .. name(prefix) .. ": " .. message)
      end
    end
  elseif command == "NOTICE" then
    print("[NOTICE] " .. message)
  elseif command == "ERROR" then
    print("[ERROR] " .. message)

  ---------------------------------------------------
  -- Ignored reserved numbers
  -- -- http://tools.ietf.org/html/rfc2812#section-5.3

  elseif tonumber(command) and ignore[tonumber(command)] then
    -- ignore

  ---------------------------------------------------
  -- Command replies
  -- http://tools.ietf.org/html/rfc2812#section-5.1

  elseif command == commands.RPL_WELCOME then
    print(message)
  elseif command == commands.RPL_YOURHOST then -- ignore
  elseif command == commands.RPL_CREATED then -- ignore
  elseif command == commands.RPL_MYINFO then -- ignore
  elseif command == commands.RPL_BOUNCE then -- ignore
  elseif command == commands.RPL_LUSERCLIENT then
    print(message)
  elseif command == commands.RPL_LUSEROP then -- ignore
  elseif command == commands.RPL_LUSERUNKNOWN then -- ignore
  elseif command == commands.RPL_LUSERCHANNELS then -- ignore
  elseif command == commands.RPL_LUSERME then
    print(message)
  elseif command == commands.RPL_AWAY then
    print(string.format("%s is away: %s", name(args[1]), message))
  elseif command == commands.RPL_UNAWAY or command == commands.RPL_NOWAWAY then
    print(message)
  elseif command == commands.RPL_WHOISUSER then
    local nick = args[2]:lower()
    whois[nick].nick = args[2]
    whois[nick].user = args[3]
    whois[nick].host = args[4]
    whois[nick].realName = message
  elseif command == commands.RPL_WHOISSERVER then
    local nick = args[2]:lower()
    whois[nick].server = args[3]
    whois[nick].serverInfo = message
  elseif command == commands.RPL_WHOISOPERATOR then
    local nick = args[2]:lower()
    whois[nick].isOperator = true
  elseif command == commands.RPL_WHOISIDLE then
    local nick = args[2]:lower()
    whois[nick].idle = tonumber(args[3])
  elseif command == commands.RPL_WHOISSECURE then
    local nick = args[2]:lower()
    whois[nick].secureconn = "Is using a secure connection"
  elseif command == commands.RPL_ENDOFWHOIS then
    local nick = args[2]:lower()
    local info = whois[nick]
    if info.nick then print("Nick: " .. info.nick) end
    if info.user then print("User name: " .. info.user) end
    if info.realName then print("Real name: " .. info.realName) end
    if info.host then print("Host: " .. info.host) end
    if info.server then print("Server: " .. info.server .. (info.serverInfo and (" (" .. info.serverInfo .. ")") or "")) end
    if info.secureconn then print(info.secureconn) end
    if info.channels then print("Channels: " .. info.channels) end
    if info.idle then print("Idle for: " .. info.idle) end
    whois[nick] = nil
  elseif command == commands.RPL_WHOISCHANNELS then
    local nick = args[2]:lower()
    whois[nick].channels = message
  elseif command == commands.RPL_CHANNELMODEIS then
    print("Channel mode for " .. args[1] .. ": " .. args[2] .. " (" .. args[3] .. ")")
  elseif command == commands.RPL_NOTOPIC then
    print("No topic is set for " .. args[1] .. ".")
  elseif command == commands.RPL_TOPIC then
    print("Topic for " .. args[1] .. ": " .. message)
  elseif command == commands.RPL_NAMREPLY then
    local channel = args[3]
    table.insert(names[channel], message)
  elseif command == commands.RPL_ENDOFNAMES then
    local channel = args[2]
    print("Users on " .. channel .. ": " .. (#names[channel] > 0 and table.concat(names[channel], " ") or "none"))
    names[channel] = nil
  elseif command == commands.RPL_MOTDSTART then
    if options.motd then
      print(message .. args[1])
    end
  elseif command == commands.RPL_MOTD then
    if options.motd then
      print(message)
    end
  elseif command == commands.RPL_ENDOFMOTD then -- ignore
  elseif command == commands.RPL_HELPSTART or 
  command == commands.RPL_HELPTXT or 
  command == commands.RPL_ENDOFHELP then
    print(message)
  elseif command == commands.ERR_BANLISTFULL or
  command == commands.ERR_BANNEDFROMCHAN or
  command == commands.ERR_CANNOTSENDTOCHAN or
  command == commands.ERR_CHANNELISFULL or
  command == commands.ERR_CHANOPRIVSNEEDED or
  command == commands.ERR_ERRONEUSNICKNAME or
  command == commands.ERR_INVITEONLYCHAN or
  command == commands.ERR_NICKCOLLISION or
  command == commands.ERR_NOSUCHNICK or
  command == commands.ERR_NOTONCHANNEL or
  command == commands.ERR_UNIQOPRIVSNEEDED or
  command == commands.ERR_UNKNOWNMODE or
  command == commands.ERR_USERNOTINCHANNEL or
  command == commands.ERR_WASNOSUCHNICK or
  command == commands.ERR_MODELOCK then
    print("[ERROR]: " .. message)
  elseif tonumber(command) and (tonumber(command) >= 200 and tonumber(command) < 400) then
    print("[Response " .. command .. "] " .. table.concat(args, ", ") .. ": " .. message)

  ---------------------------------------------------
  -- Error messages. No real point in handling those manually.
  -- http://tools.ietf.org/html/rfc2812#section-5.2

  elseif tonumber(command) and (tonumber(command) >= 400 and tonumber(command) < 600) then
    print("[Error] " .. table.concat(args, ", ") .. ": " .. message)

  ---------------------------------------------------
  -- Unhandled message.

  else
    print("Unhandled command: " .. command .. ": " .. message)
  end
end

  -- say hello.
  --term.clear()
  window:clear(colors.white)
  print("Welcome to OpenIRC!")

  -- avoid sock:read locking up the computer.
  sock:setTimeout(0.05)

  -- http://tools.ietf.org/html/rfc2812#section-3.1
  sock:write(string.format("NICK %s\r\n", nick))
  sock:write(string.format("USER %s 0 * :%s [OpenComputers]\r\n", nick:lower(), nick))
  sock:flush()

  -- socket reading logic (receive messages) driven by a timer.
  timer = event.timer(0.5, function()
    if not sock then
        timer = nil --дабы потом не закрывать несушествуюший/другой таймер
      return false
    end
    repeat
      local ok, line = pcall(sock.read, sock)
      if ok then
        if not line then
          print("Connection lost.")
          sock:close()
          sock = nil
          timer = nil
          return false
        end
        line = text.trim(line) -- get rid of trailing \r
        local match, prefix = line:match("^(:(%S+) )")
        if match then line = line:sub(#match + 1) end
        local match, command = line:match("^(([^:]%S*))")
        if match then line = line:sub(#match + 1) end
        local args = {}
        repeat
          local match, arg = line:match("^( ([^:]%S*))")
          if match then
            line = line:sub(#match + 1)
            table.insert(args, arg)
          end
        until not match
        local message = line:match("^ :(.*)$")

        if callback then
          local result, reason = pcall(callback, prefix, command, args, message)
          if not result then
            print("Error in callback: " .. tostring(reason))
          end
        end
        handleCommand(prefix, command, args, message)
      end
    until not ok
  end, math.huge)

  -- default target for messages, so we don't have to type /msg all the time.
  local target = nil

  -- command history.
  local history = {}

  local gpu = graphic.findGpu(screen)
  repeat
    local w, h = gpu.getResolution()
    window:setCursor(1, h)
    window:write((target or "?") .. "> ")
    local line

    local reader = window:read(1, h, w, colors.gray, colors.white)
    while true do
        local eventData = {event.pull()}
        window:uploadEvent(eventData)
        local out = reader.uploadEvent(eventData)
        if out == true then
            break
        elseif out then
            line = out
            break
        end
    end

    if sock and line and line ~= "" then
      line = text.trim(line)
      if line:lower():sub(1,4) == "/me " then
        print("[" .. (target or "?") .. "] " .. nick .. " " .. line:sub(5), true)
      elseif line~="" then
        print("[" .. (target or "?") .. "] " .. nick .. ": " .. line, true)
      end
      if line:lower():sub(1, 5) == "/msg " then
        local user, message = line:sub(6):match("^(%S+) (.+)$")
        if message then
          message = text.trim(message)
        end
        if not user or not message or message == "" then
          print("Invalid use of /msg. Usage: /msg nick|channel message.")
          line = ""
        else
          target = user
          line = "PRIVMSG " .. target .. " :" .. message
        end
      elseif line:lower():sub(1, 6) == "/join " then
        local channel = text.trim(line:sub(7))
        if not channel or channel == "" then
          print("Invalid use of /join. Usage: /join channel.")
          line = ""
        else
          target = channel
          line = "JOIN " .. channel
        end
      elseif line:lower():sub(1, 5) == "/lua " then
        local script = text.trim(line:sub(6))
        local result, reason = load(script, "=stdin", nil, setmetatable({print=print, socket=sock, nick=nick}, {__index=_G}))
        if not result then
          result, reason = load("return " .. script, "=stdin", nil, setmetatable({print=print, socket=sock, nick=nick}, {__index=_G}))
        end
        line = ""
        if not result then
          print("Error: " .. tostring(reason))
        else
          result, reason = pcall(result)
          if not result then
            print("Error: " .. tostring(reason))
          elseif type(reason) == "function" then
            callback = reason
          elseif reason then
            line = tostring(reason)
          end
        end
      elseif line:lower():sub(1,4) == "/me " then
        if not target then
          print("No default target set. Use /msg or /join to set one.")
          line = ""
        else
          line = "PRIVMSG " .. target .. " :\001ACTION " .. line:sub(5) .. "\001"
        end
      elseif line:sub(1, 1) == "/" then
        line = line:sub(2)
      elseif line ~= "" then
        if not target then
          print("No default target set. Use /msg or /join to set one.")
          line = ""
        else
          line = "PRIVMSG " .. target .. " :" .. line
        end
      end
      if line and line ~= "" then
        sock:write(line .. "\r\n")
        sock:flush()
      end
    end
  until not sock or not line

if sock then
  sock:write("QUIT\r\n")
  sock:close()
end
if timer then
  event.cancel(timer)
end