local class = require 'libraries/middleclass'
require 'libraries/middleclass-commons'
require 'network/clientData'
require 'libraries/additionalFunctions'

OfficerServer = class('OfficerServer')

function OfficerServer:initialize()
   self.clientMessages = {}
   self.clients = {}
   self.port = ClientData.static.PORT
   self.serverMessages = {}
   self.first = 1
   self.last = 0
end

function OfficerServer:receiveClientData(data, clientID)
   self.last = self.last + 1
   self.clientMessages[self.last] = ClientData:new(clientID, data)
   self.clients[clientID] = true

   --print("received data from client " .. clientID .. ": " .. tostring(data))
end

function OfficerServer:clientConnect(clientID)
   self.clients[clientID] = true

   print("Client " .. clientID .. " connected!")
end

function OfficerServer:clientDisconnect(clientID)
   self.clients[clientID] = nil
end

function OfficerServer:getLatestMessage()
   self.last = self.last - 1
   local ret = self.clientMessages[self.last + 1]
   self.clientMessages[self.last + 1] = nil

   return ret
end

function OfficerServer:getFirstMessage()
   self.first = self.first + 1
   local ret = self.clientMessages[self.first - 1]
   self.clientMessages[self.first - 1] = nil

   return ret
end

function OfficerServer:peekLatestMessage()
   return self.clientMessages[self.last]
end

function OfficerServer:peekFirstMessage()
   return self.clientMessages[self.first]
end

function OfficerServer:getAllMessages()
   return self.clientMessages
end

function OfficerServer:getPort()
   return self.port
end

function OfficerServer:hasClient()
   for i = self.first, self.last do
      return true
   end

   return false
end

function OfficerServer:hasMessages()
   if self.first < self.last then
      return true
   else
      return false
   end
end

function OfficerServer:getClientList()
   return self.clients
end