hasJoystick = false
s = require 'pixelateShader'
DEFAULT_PIX_SIZE = 70
DEFAULT_IMG_TIME = 18
DEFAULT_SCREEN_WIDTH = 800
DEFAULT_SCREEN_HEIGHT = 600

isDebugging = false
isTesting = false
isRandomFiles = false

---
-- Splits a string on the given pattern, returned as a table of the delimited strings.
-- @param str the string to parse through
-- @param pat the pattern/delimiter to look for in str
-- @return a table of the delimited strings. If pat is empty, returns str. If str is not given, aka '' is given, then it returns an empty table.
function split(str, pat)
   if pat == '' then
      return str
   end

   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
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

   local directory = "images"
   testImgNames = loadImageFolder(directory)
   testImg = {}
   currImgIndex = 0
   currImgName = ""

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

   local joysticks = love.joystick.getJoysticks()
   hasJoystick = #joysticks > 0

   print("checking out joysticks")
   for i = 1, #joysticks do
      print(joysticks[i]:getName())
   end
   print("done with them joysticks")
   
   -- The only thing that needs to be sent to the shader is the game time. If this value is changed in-game, I'll update it then, but this is the one constant. All the other variables change with each new image.
   s.shader:send('imgTime', imgTime)
end

-- Draws the image to the screen.
function love.draw()
   local isEndOfImage = gameTime >= imgTime

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
      love.graphics.draw(testImg[currImgIndex], 0,0)

      -- remove the graphics transformations
      love.graphics.pop()

      -- clear the shader
      if not isEndOfImage then
         love.graphics.setShader()
      end
   end

   -- print the FPS and filename at the top left corner
   if isTesting then
      love.graphics.setColor( 50, 205, 50, 255 )
      love.graphics.print('fps: '..love.timer.getFPS() .. '\nFilename: ' .. justFilename(currImgName), 0, 0 )
   end
end

-- Updates the shader with the correct amount of time left for the picture.
function love.update(dt)
   if not isEndGame and not isPaused then
      gameTime = gameTime + dt
   end

   if not isEndGame then
      s.shader:send('time', gameTime)
   end
end

-- Get just the filename, none of the folder parts.
function justFilename(filePath)
   if filePath ~= "" then
      local filenameParts = split(filePath, '/')
      return filenameParts[#filenameParts]
   else
      return ""
   end
end

-- Handles keyboard presses.
function love.keypressed(key, isrepeat)
   if key == 'q' or key == 'escape' then -- quit program
      love.event.quit()
   end

   if key == 'f' then -- set to fullscreen
      love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
   end

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
      love.mouse.setVisible(true)

      local directory = isTesting and "testing" or "images"
      testImgNames = loadImageFolder(directory)
      testImg = {}
   end

   if key == 'p' then -- pause or unpause the game
      isPaused = not isPaused
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

   --## Set the pixel size to be consistent apart from the scale ##--
   s.shader:send('startingPixSize', startingPixSize * testImg[currImgIndex]:getWidth() / (testImg[currImgIndex]:getWidth() * scaling))

   --## Center the image by getting its translation ##--
   transX = (wd - (scaling * testImg[currImgIndex]:getWidth())) - ((wd - scaling * testImg[currImgIndex]:getWidth()) / 2)
   transY = (ht - (scaling * testImg[currImgIndex]:getHeight())) - ((ht - scaling * testImg[currImgIndex]:getHeight()) / 2)
end

-- Moves to the next image, whether backwards or forwards in the list.
-- Depends on the increment value and the endIndex given.
function moveToNextImage(increment, endIndex)
   if gameTime >= imgTime or isEndGame then --go to the next image
      currImgIndex = currImgIndex + increment

      -- if it's not the end of the game
      if currImgIndex <= #testImgNames and currImgIndex > 0 then
         isEndGame = false
         love.mouse.setVisible(false)

         currImgName = testImgNames[currImgIndex]

         -- Print out the image name
         print(currImgIndex .. ": " .. justFilename(currImgName))
         testImg[currImgIndex] = love.graphics.newImage(testImgNames[currImgIndex])

         s.shader:send('screen', {testImg[currImgIndex]:getWidth(), testImg[currImgIndex]:getHeight()})

         scaleAndTranslateImage()
         gameTime = 0
      else -- we've finished going through the images
         isEndGame = true
         currImgName = ""
         currImgIndex = endIndex
         gameTime = 0
         love.mouse.setVisible(true)
      end
   elseif gameTime < imgTime then -- reveal the image
      gameTime = imgTime
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