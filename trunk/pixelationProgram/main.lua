--s = require 'pixelateShader'
require 'libraries/additionalFunctions'
require 'network/pixelClient'
require 'network/officerServer'
require 'clientMessages'

require 'libraries/middleclass'
require 'libraries/middleclass-commons'
--require 'libraries/slither'
require 'socket'
--require '../libraries/luasocket/socket'
lube = require 'libraries/LUBE.init'

hasJoystick = false
DEFAULT_PIX_SIZE = 70
DEFAULT_IMG_TIME = 5
DEFAULT_SCREEN_WIDTH = 600
DEFAULT_SCREEN_HEIGHT = 400
--DEFAULT_PORT = 60700

isDebugging = false
isTesting = true
isRandomFiles = true

-- Initialize the game.
function love.load()
   if isDebugging then
      --allow ZeroBrane Studio to debug from within the IDE
      if arg[#arg] == "-debug" then
         require("mobdebug").start()
      end
   end

   -- create the images directory if it doesn't exist yet
   if not love.filesystem.exists(love.filesystem.getSaveDirectory() .. "images") then
      love.filesystem.createDirectory("images")
   end

   -- set up the client
   pixelClient = PixelClient:new()
   client = lube.tcpClient()
   print("set up client")
   client.handshake = "AnimeEyes"--Officer Program"
   --client:setPing(true, --[[.01]]1, "animeEyesPing\n")--officerClientPing")

   client.callbacks.recv = function(d)
      --print("Received " .. tostring(d) .. " from server")
      pixelClient:receiveServerData(d)
   end
   print("set up callback for client")
   local success, err = client:connect(PixelClient.static.LOCALHOST, pixelClient:getPort(), true)

   if success then
      print("Client connected to " .. PixelClient.static.LOCALHOST .. ":" .. pixelClient:getPort())
   else
      print(err)
   end

   local directory = "images"
   testImgNames = loadImageFolder(directory)
   testImg = {}
   currImgIndex = 0
   currImgName = ""
   hasServer = false
   isClearImage = true
   hasImageLoaded = false

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
   isFullscreen = false
   hasMouse = true

   local joysticks = love.joystick.getJoysticks()
   hasJoystick = #joysticks > 0

   print("checking out joysticks")
   for i = 1, #joysticks do
      print(joysticks[i]:getName())
   end
   print("done with them joysticks")
end

-- Loads the image folder's images.
function loadImageFolder(dir)
   local acceptedExtensions = {}
   acceptedExtensions["jpeg"] = true
   acceptedExtensions["jpg"] = true
   acceptedExtensions["png"] = true
   acceptedExtensions["gif"] = true
   acceptedExtensions["bmp"] = true

   local files = love.filesystem.getDirectoryItems(dir)
   local imageFiles = {}

   -- loop through the files in the directory for only images and add them to the array
   for k, file in ipairs(files) do
      -- make sure it's not a Mac hidden file
      if string.sub(file,1,1) ~= "." then
         local filename = split(file, '%.')

         -- if it's not a directory, check the extension filename
         if #filename > 1 and acceptedExtensions[string.lower(filename[#filename])] then
            table.insert(imageFiles, dir .. "/" .. file)
         end
      end
   end

   -- Need to sort the images so they're in alphabetical order if we don't want random order
   local sortFunction = function (a, b)
      return string.lower(a) < string.lower(b)
   end

   table.sort(imageFiles, sortFunction)

   -- if we're running the program for a real Anime Eyes event, randomize the file order
   if isRandomFiles then
      local randomizeFiles = {}
      local min = 1
      local max = #imageFiles
      local totalFiles = #imageFiles

      -- keep running until all the files have been randomly put in order
      while #randomizeFiles < totalFiles do
         local randIndex = love.math.random(min, max)

         -- if the random index value contains something, then add it to the list
         if imageFiles[randIndex] ~= nil then
            table.insert(randomizeFiles, imageFiles[randIndex])

            imageFiles[randIndex] = nil

            -- shorten the range for randomizing to make it run a little faster
            if randIndex == min then
               min = min + 1
            elseif randIndex == max then
               max = max - 1
            end
         end
      end

      return randomizeFiles
   else
      return imageFiles
   end
end

-- Draws the image to the screen.
function love.draw()
   -- if we haven't finished going through the images, pixelate the image
   if not isEndGame then
      -- move and scale the image so it's in the center of the window, scaled to fit the window completely
      love.graphics.push()
      love.graphics.translate(transX, transY)
      love.graphics.scale(scaling, scaling)

      love.graphics.setColor(255,255,255)
      love.graphics.draw(testImg[currImgIndex], 0,0)

      -- remove the graphics transformations
      love.graphics.pop()
   end

   -- print the FPS and filename at the top left corner
   if isTesting then
      love.graphics.setColor( 50, 205, 50, 255 )
      love.graphics.print('fps: '..love.timer.getFPS() .. '\nFilename: ' .. justFilename(currImgName), 0, 0 )
   end
end

-- Updates the shader with the correct amount of time left for the picture.
function love.update(dt)
   client:update(dt)

   if pixelClient:hasMessages() then
      resolveMessages()
   end

   if not isEndGame and not isPaused then
      gameTime = gameTime + dt
   end

   --[[data = client:receive()

   if data then
      print("data from server: " .. tostring(data))
   end]]

   if love.filesystem.exists("exit.txt") then
      local success = false

      while not success do
         success = love.filesystem.remove("exit.txt")
      end

      love.event.quit()
   end
end

function resolveMessages()
   while pixelClient:hasMessages() do
      local message = pixelClient:getFirstMessage()

      if message ~= nil and message ~= "" then
         local tokens = split(message, ':')

         if parseMessage[ tokens[1] ] ~= nil then
            parseMessage[ tokens[1] ](tokens)
         end
      end
   end
end

-- Handles keyboard presses.
function love.keypressed(key, isrepeat)
   if key == 'q' or key == 'escape' then -- quit program
      love.event.quit()
   end

   if key == 'f' then -- set to fullscreen
      isFullscreen = not isFullscreen

      client:send("isFullscreen:" .. tostring(isFullscreen) .. "\n")
   end

   if isEndGame or (not isEndGame and hasImageLoaded) then
      print("button pressed! isClearImage? " .. tostring(isClearImage))
      if key == '[' then -- move to previous image
         moveToNextImage(-1, 0)
      elseif key == ']' then -- move to next image
         moveToNextImage(1, #testImgNames + 1)
      end

      if key == 'r' then -- reload images folder, and eventually config.ini
         isEndGame = true
         currImgName = ""
         currImgIndex = 0
         gameTime = 0
         --love.mouse.setVisible(true)

         local directory = "images"
         testImgNames = loadImageFolder(directory)
         testImg = {}

         client:send("isEndGame:" .. tostring(isEndGame) .. "\n")
      end

      if key == 'p' then -- pause or unpause the game
         isPaused = not isPaused
         print("pressed 'p'")

         client:send("isPaused:" .. tostring(isPaused) .. "\n")
      end
   end
end

-- Scale and translate the image so it fits the window.
function scaleAndTranslateImage()
   -- determine whether we scale on the height or width of the image
   local scaledHeight = testImg[currImgIndex]:getHeight() * wd / testImg[currImgIndex]:getWidth()
   local scaledWidth = testImg[currImgIndex]:getWidth() * ht / testImg[currImgIndex]:getHeight()

   if scaledWidth <= wd then --scale on height
      scaling = scaledWidth / testImg[currImgIndex]:getWidth()
   else --scale on width
      scaling = scaledHeight / testImg[currImgIndex]:getHeight()
   end

   --## Center the image by getting its translation ##--
   transX = (wd - (scaling * testImg[currImgIndex]:getWidth())) - ((wd - scaling * testImg[currImgIndex]:getWidth()) / 2)
   transY = (ht - (scaling * testImg[currImgIndex]:getHeight())) - ((ht - scaling * testImg[currImgIndex]:getHeight()) / 2)
end

-- Moves to the next image, whether backwards or forwards in the list.
-- Depends on the increment value and the endIndex given.
function moveToNextImage(increment, endIndex)
   if isEndGame or (not isEndGame and isClearImage) then --go to the next image
      currImgIndex = currImgIndex + increment
      --while love.filesystem.exists("finishedImage.txt") do
      --local success = love.filesystem.remove("finishedImage.txt")
      --end
      isClearImage = false

      -- if it's not the end of the game
      if currImgIndex <= #testImgNames and currImgIndex > 0 then
         isEndGame = false
         if not isEndGame and not hasServer then
         end

         hasServer = isEndGame
         --love.mouse.setVisible(false)
         gameTime = 0

         currImgName = testImgNames[currImgIndex]
         -- pass in three images: the one previous, the current, and the next one. Want to load the images in efficient time.
         hasImageLoaded = false
         --client:send("gameTime:" .. gameTime .. "\n")
         client:send("currImgName:" .. currImgName .. "\n")
         --client:send("isEndGame:" .. tostring(isEndGame) .. "\n")

         -- Print out the image name
         print(currImgIndex .. ": " .. justFilename(currImgName))
         testImg[currImgIndex] = love.graphics.newImage(testImgNames[currImgIndex])

         scaleAndTranslateImage()
      else -- we've finished going through the images
         currImgName = ""
         currImgIndex = endIndex
         gameTime = 0
         isClearImage = true
         hasImageLoaded = false
         --love.mouse.setVisible(true)

         if not isEndGame then
            isEndGame = true
            client:send("isEndGame:" .. tostring(isEndGame) .. "\n")
         end
      end
   elseif not isEndGame and not isClearImage then -- reveal the image
      if gameTime ~= imgTime then
         gameTime = imgTime

         client:send("gameTime:" .. gameTime .. "\n")
      end
   end
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
   print("Closing connection...")
   client:disconnect()
   --client:send("AnimeEyes-\n")
   print("Closing pixelation program!")
end