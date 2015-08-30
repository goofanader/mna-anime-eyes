-- Functions to handle pipe input.

channel = love.thread.getChannel("animeEyes")

while true do
   print("about to read from io.in...")
   hasInput = io.stdin:read()
   print("in the pipe...")
   
   if hasInput ~= nil then
      channel:supply(hasInput)
      print("pipe's got stuff!: " .. tostring(hasInput))
   end
end