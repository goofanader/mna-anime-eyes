s = require 'pixelateShader'
require 'middleclass'
require 'libraries/middleclass-commons'
require 'libraries/roundrect' -- taken from https://love2d.org/forums/viewtopic.php?t=11511
Player = require 'classes/player'

hasJoystick = false
DEFAULT_PIX_SIZE = 70
DEFAULT_IMG_TIME = 18
DEFAULT_SCREEN_WIDTH = 800
DEFAULT_SCREEN_HEIGHT = 600
TRIVIA_BUTTONS_NAME = "REAL ARCADE PRO.3"
POINTS = 'points'
NAME = 'name'
INDEX = 'index'

DEFAULT_MAX_POINTS = 100
DEFAULT_MIN_POINTS = 10
DEFAULT_MIDPOINT_X = DEFAULT_MAX_POINTS / 100.0 * 99.0
DEFAULT_MIDPOINT_Y = DEFAULT_MAX_POINTS / 4.0 * 3.0

isDebugging = false
isTesting = true
isRandomFiles = true
isCheckingImages = false
triviaButtons = nil
contestantPointIndex = {}
contestantPointsSorted = {}
imageGuessers = {}

-- Capitalize the first character of a string
-- Taken from http://stackoverflow.com/questions/2421695/first-character-uppercase-lua
function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

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

   -- start up a random number generator
   rng = love.math.newRandomGenerator()
   rng:setSeed(os.time())

   -- set the default font
   defaultFont = love.graphics.setNewFont(20)

   -- set the default bezier curve for points
   maxPoints = DEFAULT_MAX_POINTS
   minPoints = DEFAULT_MIN_POINTS
   midPointX = DEFAULT_MIDPOINT_X
   midPointY = DEFAULT_MIDPOINT_Y

   pointCurve = love.math.newBezierCurve({minPoints, maxPoints, midPointX, midPointY, maxPoints, minPoints})

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
   isImagePaused = false

   local joysticks = love.joystick.getJoysticks()
   hasJoystick = #joysticks > 0

   print("checking out joysticks")
   triviaButtons = nil
   for i = 1, #joysticks do
      if joysticks[i]:getName() == TRIVIA_BUTTONS_NAME then
         triviaButtons = joysticks[i]
         print(joysticks[i]:getName() .. ": # buttons = " .. joysticks[i]:getButtonCount())
      end
   end
   print("done with them joysticks")

   -- The only thing that needs to be sent to the shader is the game time. If this value is changed in-game, I'll update it then, but this is the one constant. All the other variables change with each new image.
   s.shader:send('imgTime', imgTime)

   -- start thread
   consoleThread = love.thread.newThread("consoleThread.lua")
   channel = love.thread.getChannel("Console")
   gameChannel = love.thread.getChannel("GameStart")
   consoleThread:start()

   --channel:supply(love.filesystem.getWorkingDirectory())
end

-- Draws the image to the screen.
function love.draw()
   local isEndOfImage = gameTime >= imgTime

   -- if we haven't finished going through the images, pixelate the image
   if not isEndGame then
     love.graphics.setColor(255,255,255)
      -- only use the shader if it's pixelating the image.
      if not isEndOfImage then
         love.graphics.setShader( s.shader )
      end

      -- move and scale the image so it's in the center of the window, scaled to fit the window completely
      love.graphics.push()
      love.graphics.translate(transX, transY)
      love.graphics.scale(scaling, scaling)

      -- if it's the end of the image, print just the image, no shader
      --[[if isEndOfImage then
         love.graphics.setColor(255,255,255)
      end]]
      love.graphics.draw(testImg[currImgIndex], 0,0)

      -- remove the graphics transformations
      love.graphics.pop()

      -- clear the shader
      if not isEndOfImage then
         love.graphics.setShader()
      end
   end

   -- print the FPS and filename at the top left corner
   --[[if isTesting and not isImagePaused then
      love.graphics.setColor( 50, 205, 50, 255 )
      love.graphics.print('fps: '..love.timer.getFPS() .. '\nFilename: ' .. justFilename(currImgName), 0, 0 )
   end]]

   if isTesting then
     love.graphics.setColor(50, 205, 50, 255)
     local counter = 0
     for index, player in pairs(contestantPointIndex) do
       local newlines = ""
       for i = 1, counter do
         newlines = newlines.."\n"
       end
       love.graphics.print(newlines..tostring(player))
       counter = counter + 1
     end
     love.graphics.setColor(255, 255, 255)
   end

   if isTesting then
     printPrettyMessage(tostring(currentPoints).." Points Available", "top right")

     -- show point bezier curve
     --[[love.graphics.setColor( 50, 205, 50, 255 )
     love.graphics.line(pointCurve:render())
     love.graphics.setColor(255,255,255)]]
   end

   -- print which button paused the game
   if isImagePaused then
      if isTesting then
        love.graphics.setColor( 50, 205, 50, 255 )
        love.graphics.print(buttonString)
        love.graphics.print("\nThe guesser is "..tostring(guesser))
        love.graphics.setColor(255,255,255)
      end
   end

   if isWaitingForPlayerButton ~= nil and love.window.hasFocus() then
     local buttonMessage = firstToUpper(isWaitingForPlayerButton) .. ", press your button."
     printPrettyMessage(buttonMessage)
   end

end

function printPrettyMessage(msg, position, font)
  position = position or "center"
  font = font or defaultFont

  local margin = 5
  local edgeSize = 5
  local messageX = (wd / 2.0) - (font:getWidth(msg) / 2.0)
  local messageY = (ht / 2.0) - (font:getHeight() / 2.0)

  if position:find("top") then
    messageY = margin * 2
  elseif position:find("bottom") then
    messageY = ht - font:getHeight() - (margin * 2)
  end

  if position:find("left") then
    messageX = margin * 2
  elseif position:find("right") then
    messageX = wd - font:getWidth(msg) - (margin * 2)
  end

  -- round rectangle background (TODO: CHANGE TO A GRAPHIC!!!!)
   -- shadow
  love.graphics.setColor(0,0,0,128)
  love.graphics.roundrect('fill', messageX - margin, messageY - margin + 2, font:getWidth(msg) + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

  -- background
  love.graphics.setColor(255,255,255,200)
  love.graphics.roundrect('fill', messageX - margin, messageY - margin, font:getWidth(msg) + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

  -- outline of box
  love.graphics.setLineWidth(3)
  love.graphics.roundrect("line", messageX - margin, messageY - margin, font:getWidth(msg) + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

  -- text on box
  love.graphics.setColor(0,0,0,255)
  love.graphics.print(msg, messageX, messageY)
  love.graphics.setColor(255, 255, 255)
end

function handleChannel()
   while channel:getCount() > 0 do
     local action = channel:pop()
     print("Action: "..action)
     if action == "exit" then
       --print("Exiting...")
       love.event.quit()
     elseif action == "fullscreen" then
       setFullscreen()
     elseif action == "reload" then
       reloadImages()
     elseif action == "pause" then
       toggleImagePause() -- probably more of a game pause here, actually.
     elseif action:find("add || ") then
       local playerName = split(action, " || ")[2]
       isWaitingForPlayerButton = playerName
     elseif action:find("edit || ") then
       local info = split(action, " || ")
       local buttonNumber = tonumber(info[2])
       contestantPointIndex[buttonNumber].points = info[3]

       if imageGuessers[buttonNumber] ~= nil then
         imageGuessers[buttonNumber].points = info[3]
       end

       if guesser and guesser.index == buttonNumber then
         guesser.points = info[3]
       end
     elseif action:find("remove || ") then
       local info = split(action, " || ")
       local buttonNumber = tonumber(info[2])
       contestantPointIndex[buttonNumber] = nil
       imageGuessers[buttonNumber] = nil

       if guesser and guesser.index == buttonNumber then
         guesser = nil
       end
     elseif action == "start" then
       isWantingGameToStart = true
       currImgIndex = 0
       --moveToNextImage(1, #testImgNames + 1)
     end
   end

   channel:clear()
end

function setFullscreen()
  love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
end

function reloadImages()
   isEndGame = true
   currImgName = ""
   currImgIndex = 0
   gameTime = 0
   love.mouse.setVisible(true)

   local directory = isTesting and "testing" or "images"
   testImgNames = loadImageFolder(directory)
   testImg = {}
 end

 function toggleImagePause()
   isImagePaused = not isImagePaused

   if not isImagePaused then
     guesser = nil
   end
 end

-- taken from http://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
 function tablelen(T)
   local count = 0
   for _ in pairs(T) do count = count + 1 end
   return count
 end

-- Updates the shader with the correct amount of time left for the picture.
function love.update(dt)
   handleChannel()

   if isWantingGameToStart and love.window.hasFocus() then
     isWantingGameToStart = false
     moveToNextImage(1, #testImgNames + 1)
     gameChannel:supply("started")
   end

   if not isEndGame and not isImagePaused then
      gameTime = gameTime + dt
   end

   if not isEndGame then
      s.shader:send('time', gameTime)
   end

   -- determine points for this moment in time
   currentPointsX, currentPoints = pointCurve:evaluate(math.min(1.0, gameTime / (imgTime * 1.0)))
   currentPoints = math.floor(currentPoints + 0.5)

   -- check for joystick buttons
   local hasButtonDown = false

   if not isImagePaused then
      buttonString = "buttons that paused game: "
      local guessers = {}

      if triviaButtons ~= nil then
         for i = 1, triviaButtons:getButtonCount() do
            -- if there's a joystick button down, note which ones did so
            if triviaButtons:isDown(i) then
               if not isEndGame and not hasButtonDown and isWaitingForPlayerButton == nil and tablelen(imageGuessers) < tablelen(contestantPointIndex) then
                  hasButtonDown = true
               end

               -- TODO: remove this code as this creates a new player upon button hit. This should be done via command line for now.
               if isWaitingForPlayerButton ~= nil and contestantPointIndex[i] == nil then
                  contestantPointIndex[i] = Player:new(isWaitingForPlayerButton, i)

                  local playerChannel = love.thread.getChannel("AddPlayer")
                  playerChannel:supply("added || "..isWaitingForPlayerButton.." || "..i)
                  isWaitingForPlayerButton = nil
               end

               if imageGuessers[i] == nil then
                 table.insert(guessers, contestantPointIndex[i])
               end
            end
         end
      end

      -- pause the game if any joystick buttons were down
      if hasButtonDown then
         isImagePaused = true

         -- make a list of the guessers' indices for debug purposes
         for index, indivGuesser in ipairs(guessers) do
            buttonString = buttonString .. indivGuesser.index .. ","
         end

         -- determine who gets to go first
         if #guessers > 1 then
            --sort the contestant points
            table.sort(guessers,
               function(a, b)
                  -- if the points are equal, randomly move the positions
                  if a.points == b.points then
                     return rng:random() >= .5 --and true or false
                  end

                  -- else, give the lower points people precedence
                  return a.points < b.points
               end
            )
         end

         -- set guesser to the first person in the guessers list
         guesser = guessers[1]
      end
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
      --love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
      setFullscreen()
   end

   if key == '[' and isCheckingImages then -- move to previous image
      moveToNextImage(-1, 0)
   elseif key == ']' then -- move to next image
      moveToNextImage(1, #testImgNames + 1)
   end

   if key == 'r' then -- reload images folder, and eventually config.ini
      --[[isEndGame = true
      currImgName = ""
      currImgIndex = 0
      gameTime = 0
      love.mouse.setVisible(true)

      local directory = isTesting and "testing" or "images"
      testImgNames = loadImageFolder(directory)
      testImg = {}]]
      reloadImages()
   end

   if key == 'p' then -- pause or unpause the game
      toggleImagePause()
   end

   if key == 'o' and not isEndGame and guesser ~= nil then -- correct answer
     guesser.points = guesser.points + currentPoints
     contestantPointIndex[guesser.index].points = guesser.points

     imageGuessers = contestantPointIndex
     gameChannel:push("update || "..guesser.index.." || "..guesser.points)

     if gameTime < imgTime then
       moveToNextImage(1, #testImgNames + 1)
     else
       toggleImagePause()
     end
   elseif key == 'x' and not isEndGame and guesser ~= nil then -- incorrect answer
     guesser.points = guesser.points - currentPoints
     contestantPointIndex[guesser.index].points = guesser.points

     imageGuessers[guesser.index] = guesser
     gameChannel:push("update || "..guesser.index.." || "..guesser.points)

     if tablelen(imageGuessers) == tablelen(contestantPointIndex) and gameTime < imgTime then
       moveToNextImage(1, #testImgNames + 1)
     else
       toggleImagePause()
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
      imageGuessers = {}

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
         if not isEndGame then
           gameChannel:push("GameOver")
         end

         isEndGame = true
         currImgName = ""
         currImgIndex = endIndex
         gameTime = 0
         love.mouse.setVisible(true)
      end
   elseif gameTime < imgTime then -- reveal the image
      gameTime = imgTime
      isImagePaused = false
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

function love.quit()
  --[[if consoleThread:isRunning() then
    channel:push("exit")

    while consoleThread:isRunning() do
      --print("Thread running")
    end
  end]]

  return false
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end
