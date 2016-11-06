#!/usr/bin/lua
--[[
url-collector-bot.lua - Telegram bot to save URLs shared in a channel/conversation.

The bot saves the URLs in a text file with the format '<url> [<author]'.

Author: @calderpwn
Dependencies: lua-telegram-bot [https://github.com/cosmonawt/lua-telegram-bot]
]]

--Telegram API Token
local token = ""
local bot, extension = require("lua-bot-api").configure(token)

--onMessageReceive handler.
extension.onTextReceive = function (msg)
  print(string.format("[%s] Incoming message from '%s':\n%s", os.date(), msg.from.first_name, msg.text))
  msg.text = string.lower(msg.text)
  if msg.entities then
  for _, x in pairs(msg.entities) do
    if x.type == "url" then
      local url = string.sub(msg.text, x.offset, x.offset + x.length)
      write_url(url, msg.from.first_name)
      bot.sendMessage(msg.chat.id, string.format("URL '%s' saved.", url))
    end
  end
  end
  if (msg.text == "/hi") then
    bot.sendMessage(msg.chat.id, "Hello, I'm " .. bot.first_name)
  elseif (msg.text == "/ping") then
    bot.sendMessage(msg.chat.id, "pong")
  elseif (msg.text == "/list") then
    bot.sendMessage(msg.chat.id, table.concat(get_urls(), "\n")
  elseif (msg.text == "/help") or (msg.text == "/man") then
    bot.sendMessage(msg.chat.id, "/ping: Checks if I'm alive.\n/list: Returns a list of saved URLs.")
  end
end

--Retrieves stored URLs.
function get_urls()
  local urls = {}
  table.insert(urls, "URL list:")
  for line in io.lines("urls.txt") do
    table.insert(urls, line)
  end
  return urls
end

--Stores URL in file. Each URL is stored as a new line.
function write_url(url, author)
  local file = io.open("urls.txt", "a")
  io.output(file)
  io.write(string.format("%s [%s]\n", url, author))
  io.close(file)
end

extension.run()
