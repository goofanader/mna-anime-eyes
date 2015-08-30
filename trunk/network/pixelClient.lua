local class = require 'libraries/middleclass'
require 'libraries/middleclass-commons'
require 'libraries/additionalFunctions'
require 'network/clientData'

PixelClient = class('PixelClient')
PixelClient.static.LOCALHOST = "localhost"--"127.0.0.1"

function PixelClient:initialize()
   self.serverMessages = {}
   self.clientMessages = {}
   self.port = ClientData.static.PORT
   self.first = 1
   self.last = 0
end

function PixelClient:receiveServerData(data)
   local dataList = split(data, "\n")
   print("made dataLine")

   for i, dataLine in pairs(dataList) do
      print("checking dataLine")
      if not string.find(string.lower(dataLine), "ping") then
         self.last = self.last + 1
         self.serverMessages[self.last] = dataLine
         
         --print("last data entered: " .. tostring(self.serverMessages[self.last]))

         --print("received data from client " .. clientID .. ": " .. tostring(dataLine))
      end
   end

   --print("Received " .. tostring(data) .. " from server")
   --table.insert(self.serverMessages, data)
end

function PixelClient:getLatestMessage()
   self.last = self.last - 1
   local ret = self.serverMessages[self.last + 1]
   self.serverMessages[self.last + 1] = nil

   return ret
   --return table.remove(self.serverMessages, #self.serverMessages)
end

function PixelClient:getFirstMessage()
   self.first = self.first + 1
   local ret = self.serverMessages[self.first - 1]
   self.serverMessages[self.first - 1] = nil

   return ret
   --return table.remove(self.serverMessages, 1)
end

function PixelClient:peekLatestMessage()
   return self.serverMessages[self.last]
end

function PixelClient:peekFirstMessage()
   return self.serverMessages[self.first]
end

function PixelClient:getAllMessages()
   return self.serverMessages
end

function PixelClient:getPort()
   print("from getPort: port=" .. tostring(self.port))
   return self.port
end

function PixelClient:hasMessages()
   return self.first <= self.last
end