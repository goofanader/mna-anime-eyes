local socket = require "socket"

--- CLIENT ---

local tcpClient = {}
tcpClient._implemented = true

function tcpClient:createSocket()
	self.socket = socket.tcp()
	self.socket:settimeout(0)
   self.socket:settimeout(10, 't')
end

function tcpClient:_connect()
	self.socket:settimeout(5)
   print("Host: " .. self.host .. ", port: " .. self.port)
   --self.port = 8192
	local success, err = self.socket:connect(self.host, self.port)
	self.socket:settimeout(0)
	return success, err
end

function tcpClient:_disconnect()
   --self.socket:settimeout(1)
	self.socket:shutdown()
end

function tcpClient:_send(data)
	local _, err, partial = self.socket:send(data)
   
   if err then
      print("client couldn't send: " .. err)
   end
end

function tcpClient:_receive()
   --self.socket:settimeout(1)
   self.socket:settimeout(0)
   --print("yo, client received something")
	local packet = ""
	local data, _, partial = self.socket:receive(8192)
   self.socket:settimeout(0)
   --local data, err, partial = self.socket:receive('*l')
   
   --print("err from _receive: " .. tostring(err))
	while data do
		packet = packet .. data
      self.socket:settimeout(0)
		data, _, partial = self.socket:receive(8192)
      self.socket:settimeout(0)
	end
	if not data and partial then
		packet = packet .. partial
	end
	if packet ~= "" then
		return packet
	end
	return nil, "No messages"
end

function tcpClient:setoption(option, value)
	if option == "broadcast" then
		self.socket:setoption("broadcast", not not value)
	end
end


--- SERVER ---

local tcpServer = {}
tcpServer._implemented = true

function tcpServer:createSocket()
	self._socks = {}
	self.socket = socket.tcp()
	self.socket:settimeout(0)
	self.socket:setoption("reuseaddr", true)
end

function tcpServer:_listen()
	self.socket:bind("*", self.port)
	self.socket:listen(5)
end

function tcpServer:send(data, clientid)
	-- This time, the clientip is the client socket.
	if clientid then
		clientid:send(data)
	else
		for sock, _ in pairs(self.clients) do
			sock:send(data)
		end
	end
end

function tcpServer:receive()
	for sock, _ in pairs(self.clients) do
		local packet = ""
		local data, _, partial = sock:receive(8192)
		while data do
			packet = packet .. data
			data, _, partial = sock:receive(8192)
		end
		if not data and partial then
			packet = packet .. partial
		end
		if packet ~= "" then
			return packet, sock
		end
	end
	for i, sock in pairs(self._socks) do
		local data = sock:receive()
		if data then
			local hs, conn = data:match("^(.+)([%+%-])\n?$")
			if hs == self.handshake and conn ==  "+" then
				self._socks[i] = nil
				return data, sock
			end
		end
	end
	return nil, "No messages."
end

function tcpServer:accept()
	local sock = self.socket:accept()
	while sock do
		sock:settimeout(0)
		self._socks[#self._socks+1] = sock
		sock = self.socket:accept()
	end
end

return {tcpClient, tcpServer}
