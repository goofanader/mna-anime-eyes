local class = require 'libraries/middleclass'
require 'libraries/middleclass-commons'

ClientData = class('ClientData')

ClientData.static.PORT = 68710

function ClientData:initialize(clientID, data)
   self.clientID = clientID
   self.data = data
end

function ClientData:getData()
   return self.data
end

function ClientData:getID()
   return self.clientID
end