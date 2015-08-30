---
-- Server and pixelation side of the Anime Eyes program.
-- Original by Lee Bourgeois, Second Version created by Nur Monson, This Version by Phyllis Douglas (goofanader@gmail.com)

s = require 'pixelateShader'
require 'libraries/additionalFunctions'
require 'network/officerServer'
require 'network/pixelClient'
require 'clientMessages'

--require 'libraries/middleclass'
--require 'libraries/middleclass-commons'
require 'libraries/slither'
require 'socket'
--require 'libraries/luasocket/socket'
lube = require 'libraries/LUBE.init'

hasJoystick = false
DEFAULT_PIX_SIZE = 70
DEFAULT_IMG_TIME = 5
DEFAULT_SCREEN_WIDTH = 800
DEFAULT_SCREEN_HEIGHT = 600
--DEFAULT_PORT = 60700

isDebugging = false
isTesting = false
isRandomFiles = true
hasPreviousImageKey = true
isNotLoadingClient = true

-- Initialize the game.
function love.load()
   if isDebugging then
      --allow ZeroBrane Studio to debug from within the IDE
      if arg[#arg] == "-debug" then
         require("mobdebug").start()
      end
   end

   hasExitFile = true
   isFullscreen = false
   hasClient = false
   isClearImage = false

   -- set up server
   print("Setting Up Server")
   officerServer = OfficerServer:new()
   server = lube.tcpServer()
   server.handshake = "AnimeEyes"--"Welcome to Anime Eyes!"
   --server:setPing(true, --[[.03]]3, "animeEyesPing\n")--"pixelServerPing")

   server.callbacks.recv = function(d, id)
      --print("Received: \"" .. tostring(d) .. "\"")
      -- need to loop through all messages, delimited by \n.
      if d == "AnimeEyes-\n" then
         hasExitFile = false
         love.event.quit()
      else
         officerServer:receiveClientData(d, id)
      end
   end
   server.callbacks.connect = function(id)
      --print (id .. " Connected")
      officerServer:clientConnect(id)
   end
   server.callbacks.disconnect = function(id)
      officerServer:clientDisconnect(id)
   end

   server:listen(officerServer:getPort())
   print("Server listening on port " .. officerServer:getPort())

   -- open the other program
   print("Opening Officer Program")
   -- the following is for windows. Remember to write one per platform
   assert(io.popen(love.filesystem.getWorkingDirectory() .. "/pixelationProgram/loveData/love.exe " .. love.filesystem.getWorkingDirectory() .."/pixelationProgram"))
   
   --assert(io.popen("\"" .. fileToWindowsFile(love.filesystem.getWorkingDirectory()) .. "\\otherWindow\\officerSide.exe\""))
   --server:accept()

   -- create the images directory if it doesn't exist yet
   --[[if not love.filesystem.exists(love.filesystem.getSaveDirectory() .. "images") then
   love.filesystem.createDirectory("images")
   `-end]]
   currImgName = ""
   currImg = nil

   startingPixSize = DEFAULT_PIX_SIZE
   imgTime = DEFAULT_IMG_TIME

   wd, ht = DEFAULT_SCREEN_WIDTH, DEFAULT_SCREEN_HEIGHT

   scaling = 1
   transX, transY = 0, 0

   --set the filter to be linear so when the image clears, the lines are smoothed out
   love.graphics.setDefaultFilter("linear", "linear")

   gameTime = 0
   isEndGame = true
   isPaused = false

   -- The only thing that needs to be sent to the shader is the game time. If this value is changed in-game, I'll update it then, but this is the one constant. All the other variables change with each new image.
   s.shader:send('imgTime', imgTime)
   --server:send("hello")
end

-- Draws the image to the screen.
function love.draw()
   local isEndOfImage = gameTime >= imgTime
   love.graphics.reset()

   -- if we haven't finished going through the images, pixelate the image
   if not isEndGame then
      -- only use the shader if it's pixelating the image.
      if not isEndOfImage then
         love.graphics.setShader( s.shader )
      end

      -- move and scale the image so it's in the center of the window, scaled to fit the window completely
      love.graphics.push()
      love.graphics.translate(transX, transY)
      love.graphics.scale(scaling, scaling)

      -- if it's the end of the image, print just the image, no shader
      if isEndOfImage then
         love.graphics.setColor(255,255,255)
      end
      love.graphics.draw(currImg, 0,0)

      -- remove the graphics transformations
      love.graphics.pop()

      -- clear the shader
      if not isEndOfImage then
         love.graphics.setShader()
      end
   else
      love.graphics.setBackgroundColor(0,0,0)
   end
end

-- Updates the shader with the correct amount of time left for the picture.
function love.update(dt)
   --server:send("hello")
   
   if gameTime >= imgTime and not isClearImage then
      server:send("isClearImage:true")
   --[[else
      client:send("isClearImage:false")]]
   end
   
   isClearImage = gameTime >= imgTime
   
   server:update(dt)

   if officerServer:hasMessages() then
      resolveMessages()
   end

   if not isEndGame and not isPaused then
      gameTime = gameTime + dt
   end

   if not isEndGame then
      s.shader:send('time', gameTime)
   end

   --[[if hasClient then]]
--[[end]]
end

function resolveMessages()
   --print("in main:resolveMessages")
   while officerServer:hasMessages() do
      local message = officerServer:getFirstMessage():getData()

      if message ~= nil and message ~= "" then
         local tokens = split(message, ':')

         if parseMessage[tokens[1]] ~= nil then
            parseMessage[tokens[1]](tokens)
         end
      end
   end
   --print("exiting main:resolveMessages")
end

-- Scale and translate the image so it fits the window.
function scaleAndTranslateImage()
   -- determine whether we scale on the height or width of the image
   local scaledHeight = currImg:getHeight() * wd / currImg:getWidth()
   local scaledWidth = currImg:getWidth() * ht / currImg:getHeight()

   if scaledWidth <= wd then --scale on height
      scaling = scaledWidth / currImg:getWidth()
   else --scale on width
      scaling = scaledHeight / currImg:getHeight()
   end

   --## Set the pixel size to be consistent apart from the scale ##--
   s.shader:send('startingPixSize', startingPixSize * currImg:getWidth() / (currImg:getWidth() * scaling))

   --## Center the image by getting its translation ##--
   transX = (wd - (scaling * currImg:getWidth())) - ((wd - scaling * currImg:getWidth()) / 2)
   transY = (ht - (scaling * currImg:getHeight())) - ((ht - scaling * currImg:getHeight()) / 2)
end

-- Function called when the window is resized.
function love.resize(w, h)
   wd = w
   ht = h

   if not isEndGame then
      scaleAndTranslateImage()
   end
end

function love.quit(r)
   if hasExitFile then
      --print("Writing exit file")
      --love.filesystem.write("exit.txt", "exit")
   end
end