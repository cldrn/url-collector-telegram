#!/usr/bin/lua
--[[
url-collector-bot.lua - Telegram bot to collect URLs in a database
]]

local feedparser = require("feedparser")
local https = require("ssl.https")
local requests = require("requests")

--Telegram API Token
local token = ""
local bot, extension = require("lua-bot-api").configure(token)

--Archivos
local PONCHOPUNTOS_FILE = "ponchopuntos.txt"
local URLS_FILE = "urls.txt"
local COD_FILE = "cmds.txt"

--onMessageReceive handler. 
extension.onTextReceive = function (msg)
  print(string.format("[%s] Incoming message from '%s':\n%s", os.date(), msg.from.first_name, msg.text))
  -- Detecta URLs en mensajes
  if msg.entities then
    for _, x in pairs(msg.entities) do
      if x.type == "url" then
        local url = string.sub(msg.text, x.offset, x.offset + x.length)
        if is_duplicate(url) then
          agrega_poncho_punto(msg.from.id, -10)
          bot.sendMessage(msg.chat.id, string.format("¡Pirata detectado! Por no leer mensajes anteriores -10 ponchopuntos para '%s'.", msg.from.first_name))
        else
          agrega_poncho_punto(msg.from.id, 1)
          write_url(url, msg.from.first_name)
          bot.sendMessage(msg.chat.id, string.format("URL '%s' guardada. +1 ponchopunto!", url))
        end
      end
    end
  end
  -- /hola
  if (msg.text == "/hola") then
    bot.sendMessage(msg.chat.id, "¿Qué onda raza? ¿Una carnita asada? Soy " .. bot.first_name)
  -- /ping
  elseif (msg.text == "/ping") then
    bot.sendMessage(msg.chat.id, "pong")
  -- /lista - Rompe la lista en 10 links por mensaje
  elseif (msg.text == "/lista") then
    local urls = get_urls()
    local tt2 = {}
    local c=0
    local tt={} 
    local restantes = 0
    for i=1,#urls do
      table.insert(tt, urls[i])
      if i == #urls then
         bot.sendMessage(msg.chat.id, table.concat(tt, "\n"))
      end
      c = c + 1
      if c > 9 then
        bot.sendMessage(msg.chat.id, table.concat(tt, "\n"))
        tt = {}
        c = 0
      end
    end
  -- /vdd Vulnerabilidad del dia
  elseif (msg.text == "/vdd") then
    local vulns = get_vdd()
    local rnd = math.random(2, #vulns)
    bot.sendMessage(msg.chat.id, string.format("%s -> %s", vulns[rnd]['desc'], vulns[rnd]['link']))
  elseif (msg.text == "/al_tiro_morros") then
  -- /al_tiro_morros Ultimas vulns del feed
    local vulns = get_vdd()
    bot.sendMessage(msg.chat.id, "¡Al tiro morros!")
    for i=(#vulns-5),#vulns do
      bot.sendMessage(msg.chat.id, string.format("%s -> %s", vulns[i]['desc'], vulns[i]['link']))
    end
  -- /cheve
  elseif (msg.text == "/cheve") then
     local cmds = get_cod()
     local rnd = math.random(#cmds)
     bot.sendMessage(msg.chat.id, string.format("¿Un comando y después una cheve? Bueno pues...\n%s", cmds[rnd]))
   elseif (msg.text == "/ponchopuntos") then
     local score = get_score(msg.from.id)
     if score then
       if tonumber(score) < 1 then
         bot.sendMessage(msg.chat.id, "Tienes "..tostring(score).." ponchopunto(s). Echale ganas morro.")
       else
         bot.sendMessage(msg.chat.id, "Tienes "..score.." ponchopunto(s).")
       end
     else 
       bot.sendMessage(msg.chat.id, "Tss. Ni siquiera sales en la lista morro...")
     end
   elseif (msg.text == "/help") or (msg.text == "/man") or (msg.text == "/ayuda") then
    local cmds = {}
    table.insert(cmds, "!Ponte al tiro morro! Aquí te va una vez más.")
    table.insert(cmds, "/ping: Checa si sigo vivo.")
    table.insert(cmds, "/lista: Lista URLs en la base de datos.")
    table.insert(cmds, "/vdd: La carnita del día (Vulnerabilidad del día).")
    table.insert(cmds, "/al_tiro_morros: Ultimas vulnerabilidades de NVD.")
    table.insert(cmds, "/cheve: Una cheve (Comando del día).")
    table.insert(cmds, "/ponchopuntos: Tus ponchopuntos del mes.")
    bot.sendMessage(msg.chat.id, table.concat(cmds, "\n"))
  end
end

--Lee el feed de vulns
function get_vdd()
  local titles = {}
  local req = https.request("https://nvd.nist.gov/download/nvd-rss-analyzed.xml")
  for x,y in string.gmatch(req, "<link>(.-)</link>%c%s+<description>(.-)</description>") do
    local t = {}
    t.desc = y
    t.link = x
    table.insert(titles, t)
    end
  return titles
end

--Retrieves stored URLs.
function get_urls()
  local urls = {}
  table.insert(urls, "URLs en el asador:")
  local lines = {}
  for line in io.lines("urls.txt") do
    table.insert(urls, line)
  end
  return urls
end

--Lee los puntos de alguien
function get_score(author)
  local score = nil
  for line in io.lines(PONCHOPUNTOS_FILE) do
    if string.find(line, author) then
      local author_frag = string.match(line, "%[(.-)]")
      if author_frag then
        score = author_frag
      end
    end
  end
  return score
end

--Agrega puntos
function agrega_poncho_punto(author, offset)
  local f = io.open(PONCHOPUNTOS_FILE, "r")
  local content = f:read("*all")
  f:close()
  local author_score = get_score(author)
  if not(author_score) then
    f = io.open(PONCHOPUNTOS_FILE, "a")
    f:write(string.format("%d [%d]\n", author, offset))
    f:close()
  else
    local author_str = author .. "%s%[(.-)]"
    author_score = author_score + offset
    local author_new = author .. " ["..author_score.."]"
    content = content:gsub(author_str, author_new)
    f = io.open(PONCHOPUNTOS_FILE, "w")
    f:write(content)
    f:close()
  end
end

--Read command of the day file
function get_cod()
  local cmds = {}
  for line in io.lines(COD_FILE) do
    table.insert(cmds, line)
  end
  return cmds
end

--Stores URL in file. Each URL is stored as a new line.
function write_url(url, author)
  local file = io.open(URLS_FILE, "a")
  io.output(file)
  io.write(string.format("%s [%s]\n", url, author))
  io.close(file)  
end

--Checks for duplicates
function is_duplicate(url)
  for line in io.lines(URLS_FILE) do
    if url == string.match(line, "%S+") then
      return true
    end
  end
  return false
end

extension.run()

