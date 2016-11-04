#!/usr/bin/lua
--[[
url-collector-bot.lua - Telegram bot to collect URLs in a database
]]

--Telegram API Token
local token = ""
local bot, extension = require("lua-bot-api").configure(token)

--onMessageReceive handler. 
extension.onTextReceive = function (msg)
  print(string.format("[%s] Incoming message from '%s':\n%s", os.time(), msg.from.first_name, msg.text))
  msg.text = string.lower(msg.text)
  if string.find(msg.text, "http://") or string.find(msg.text, "https://") then
    for i in string.gmatch(msg.text, "%S+") do
      print("Url detected in message")
      local url = i:match("(http.-)$")
      if url then
        write_url(url)
        bot.sendMessage(msg.chat.id, string.format("URL '%s' guardada.", url))
      end
    end
  elseif (msg.text == "/start") then
    bot.sendMessage(msg.chat.id, "¿Qué onda raza? ¿Una carnita asada? Soy " .. bot.first_name)
  elseif (msg.text == "/ping") then
    bot.sendMessage(msg.chat.id, "pong")
  elseif (msg.text == "/lista") then
    bot.sendMessage(msg.chat.id, get_urls())
  elseif (msg.text == "/help") or (msg.text == "/man") or (msg.text == "/ayuda") then
    bot.sendMessage(msg.chat.id, "/ping: Checa si sigo vivo.\n/lista: Lista URLs en la base de datos.\n\n¿Qué más quieren que haga?")
  end
end

--Retrieves stored URLs.
function get_urls()
   local urls = "Lista de URLs en el asador:\n"
   local lines = {}
   for line in io.lines("urls.txt") do
      urls = urls .. line .. "\n"
   end
   return urls
end

--Stores URL in file. Each URL is stored as a new line.
function write_url(url)
  local file = io.open("urls.txt", "a")
  io.output(file)
  io.write(string.format("%s\n", url))
  io.close(file)  
end

extension.run()
