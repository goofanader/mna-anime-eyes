s = require 'pixelateShader'
require 'middleclass'
require 'libraries/middleclass-commons'
require 'libraries/roundrect' -- taken from https://love2d.org/forums/viewtopic.php?t=11511
Player = require 'classes/player'

hasJoystick = false
DEFAULT_PIX_SIZE = 100
DEFAULT_IMG_TIME = 18
DEFAULT_TRANSITION_TIME = 1.0
DEFAULT_ADDITIONAL_GUESS_TIME = 3
DEFAULT_MESSAGE_TIME = 1.5
DEFAULT_SCREEN_WIDTH = 800
DEFAULT_SCREEN_HEIGHT = 600
DEFAULT_FONT_SIZE = 36
TRIVIA_BUTTONS_NAME = "REAL ARCADE PRO.3"
POINTS = 'points'
NAME = 'name'
INDEX = 'index'
IMAGES_DIRECTORY = "images"
SCORES_DIRECTORY = "scores"
SLASHES = package.config:sub(1,1)

DEFAULT_MAX_POINTS = 100
DEFAULT_MIN_POINTS = 10
DEFAULT_MIDPOINT_X = DEFAULT_MAX_POINTS / 100.0 * 99.0
DEFAULT_MIDPOINT_Y = DEFAULT_MAX_POINTS / 4.0 * 3.0

isDebugging = false
isTesting = false
isRandomFiles = true
isCheckingImages = false
triviaButtons = nil
contestantPointIndex = {}
contestantPointsSorted = {}
imageGuessers = {}

-- trim a string.
function trim(s)
  return s:match'^%s*(.*%S)' or ''
end

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
   playersFont = love.graphics.newFont(DEFAULT_FONT_SIZE + 10)
   defaultFont = love.graphics.setNewFont(DEFAULT_FONT_SIZE)

   -- set the default bezier curve for points
   maxPoints = DEFAULT_MAX_POINTS
   minPoints = DEFAULT_MIN_POINTS
   midPointX = DEFAULT_MIDPOINT_X
   midPointY = DEFAULT_MIDPOINT_Y

   pointCurve = love.math.newBezierCurve({minPoints, maxPoints, midPointX, midPointY, maxPoints, minPoints})

   -- create the images directory if it doesn't exist yet
   if not love.filesystem.exists(love.filesystem.getSaveDirectory() .. "/" .. IMAGES_DIRECTORY) then
      love.filesystem.createDirectory(IMAGES_DIRECTORY)
   end
   if not love.filesystem.exists(love.filesystem.getSaveDirectory() .. "/" .. SCORES_DIRECTORY) then
      love.filesystem.createDirectory(SCORES_DIRECTORY)
   end

   local directory = IMAGES_DIRECTORY
   testImgNames = loadImageFolder(directory)
   testImg = {}
   currImgIndex = 0
   currImgName = ""

   startingPixSize = DEFAULT_PIX_SIZE
   imgTime = DEFAULT_IMG_TIME
   transitionTime = DEFAULT_TRANSITION_TIME
   additionalTime = DEFAULT_ADDITIONAL_GUESS_TIME
   messageTime = DEFAULT_MESSAGE_TIME

   wd, ht = DEFAULT_SCREEN_WIDTH, DEFAULT_SCREEN_HEIGHT

   scaling = 1
   transX, transY = 0, 0

   -- load SFX
   correctSFX = love.sound.newSoundData("media/sfx/correcto.wav")
   wrongSFX = love.sound.newSoundData("media/sfx/wronnng.wav")
   buzzedSFX = love.sound.newSoundData("media/sfx/chime (hypocore, 164088).wav")

   --set the filter to be linear so when the image clears, the lines are smoothed out
   love.graphics.setDefaultFilter("linear", "linear")

   gameTime = 0
   isEndGame = true
   isImagePaused = false
   isGoingToNextImage = false
   isShowingPlayerMessage = false
   hasToldConsoleOfSwitch = false

   local joysticks = love.joystick.getJoysticks()
   hasJoystick = #joysticks > 0

   if #joysticks > 0 then
     print("Choose your control scheme:")
     --print("checking out joysticks")
     triviaButtons = nil
     for i = 1, #joysticks do
       print(i..". "..joysticks[i]:getName() .. ": # of buttons = " .. joysticks[i]:getButtonCount())
     end
     print("k. No Joystick (Checking Images Mode)")

     local isChoosing = true
     while isChoosing do
       print("(Enter the number (or 'k') of your choice. Note that the usual trivia buttons are '"..TRIVIA_BUTTONS_NAME.."')")
       local choice = trim(io.read()):lower()
       local choiceAsNumber = tonumber(choice)

       if choiceAsNumber ~= nil and not choice:find("%.") then
         if choiceAsNumber > 0 and choiceAsNumber <= #joysticks then
           isChoosing = false
           triviaButtons = joysticks[choiceAsNumber]
           break
         end
       elseif choice == 'k' then
         break
       end

       print("Bad choice, try again.")
     end
   end

   if triviaButtons ~= nil then
     print("Your joystick choice: "..triviaButtons:getName())
   else
     print("No joysticks. Running in image-checking mode.")
     isCheckingImages = true

     -- print out the controls on the console.
     print([[

## Controls ##
     r - reload the images in the image folder
     p - pause/unpause the pixelation. Will unpause if the image is cleared by "]" or "[".
     f - enter/exit fullscreen for the monitor the program's located on
     ] - makes the image clear. press again to go to the next image
     [ - makes the image clear. press again to go to the previous image
     q - quit the game
]])
   end

   -- The only thing that needs to be sent to the shader is the game time. If this value is changed in-game, I'll update it then, but this is the one constant. All the other variables change with each new image.
   s.shader:send('imgTime', imgTime)

   -- start thread
   consoleThread = love.thread.newThread("consoleThread.lua")
   channel = love.thread.getChannel("Console")
   gameChannel = love.thread.getChannel("GameStart")

   if triviaButtons ~= nil then
     consoleThread:start()
     channel:supply(getCorrectSlashSaveDirectory()..IMAGES_DIRECTORY)
   end
end

function getCorrectSlashSaveDirectory()
  local correctSlashSaveDirSplit = split(love.filesystem.getSaveDirectory(), "/")
  local correctSlashSaveDir = ""

  for i = 1, #correctSlashSaveDirSplit do
    correctSlashSaveDir = correctSlashSaveDir..correctSlashSaveDirSplit[i]..SLASHES
  end

  return correctSlashSaveDir
end

-- Draws the image to the screen.
function love.draw()
   local isEndOfImage = gameTime >= imgTime
   transitionAlpha = 255 * math.min(255, math.max(0.0, gameTime - (imgTime + additionalTime))) / (transitionTime * 1.0)
   if triviaButtons == nil then transitionAlpha = 0 end
   local isShowingPoints = gameTime >= imgTime + (additionalTime + transitionTime)

   if love.window.hasFocus() then
      -- if we haven't finished going through the images, pixelate the image
      if not isEndGame --[[and not isShowingPoints]] then
        love.graphics.setColor(255,255,255, math.max(100, 255 - transitionAlpha))
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
      if not isCheckingImages and not isEndGame and transitionAlpha > 0 then
        printPlayerScores(math.min(255, transitionAlpha))
      end

      if not isEndGame and isShowingPlayerMessage then
        if guesserTimer == nil then
          guesserTimer = love.timer.getTime()
        end

        printPrettyMessage(firstToUpper(guesser.name).."'s Turn!", "center", math.max(0, 255 - (255 * (love.timer.getTime() - guesserTimer) / (messageTime * 1.0))))
        
      elseif not isEndGame then
        guesserTimer = nil
        isShowingPlayerMessage = false
      end

      -- print the FPS and filename at the top left corner
      --[[if isTesting and not isImagePaused then
         love.graphics.setColor( 50, 205, 50, 255 )
         love.graphics.print('fps: '..love.timer.getFPS() .. '\nFilename: ' .. justFilename(currImgName), 0, 0 )
      end]]

      --[[if isTesting then
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
      end]]

      if isTesting then
        printPrettyMessage(tostring(currentPoints).." Points Available", "top right")

        -- show point bezier curve
        --[[love.graphics.setColor( 50, 205, 50, 255 )
        love.graphics.line(pointCurve:render())
        love.graphics.setColor(255,255,255)]]
      end

      -- print which button paused the game
      if isImagePaused then
         --[[if isTesting then
           love.graphics.setColor( 50, 205, 50, 255 )
           love.graphics.print(buttonString)
           love.graphics.print("\nThe guesser is "..tostring(guesser))
           love.graphics.setColor(255,255,255)
         end]]
      end

      if isWaitingForPlayerButton ~= nil and love.window.hasFocus() then
        local buttonMessage = firstToUpper(isWaitingForPlayerButton) .. ", press your button."
        printPrettyMessage(buttonMessage)
      end
   else
      if not isEndGame then 
         printPlayerScores()
         printPrettyMessage("Game Paused.")
      end
      
   end
   
   if isEndGame then
      printPlayerScores()
   end
end

function printPlayerScores(alpha, font)
  --position = position or "center"
  alpha = alpha or 255
  font = font or playersFont
  local prevFont = love.graphics.getFont()
  love.graphics.setFont(font)

  contestantPointsSorted = {}
  local largestWidth = 0
  local longestName = 0
  local longestPoints = 0
  local spacing = "   "

  for index, player in pairs(contestantPointIndex) do
    table.insert(contestantPointsSorted, player)
    --local currWidth = font:getWidth(player.name..spacing..spacing..tostring(player.points))
    local nameLength = font:getWidth(player.name..spacing)
    local pointLength = font:getWidth(spacing..player.points)

    --[[if currWidth > largestWidth then
      largestWidth = currWidth
    end]]

    if longestName < nameLength then
      longestName = nameLength
    end
    if longestPoints < pointLength then
      longestPoints = pointLength
    end
  end
  table.sort(contestantPointsSorted,
     function(a, b)
        -- if the points are equal, sort by name
        if a.points == b.points then
           return a.name <= b.name --and true or false
        end

        -- else, give the higher points people precedence
        return a.points > b.points
     end
  )

  largestWidth = longestPoints + longestName
  local margin = 5
  local textSpacing = 10
  local edgeSize = 5
  local messageX = (wd / 2.0) - (largestWidth / 2.0)

  for index = 1, tablelen(contestantPointsSorted) do
    local player = contestantPointsSorted[index]

    local name = player.name..spacing
    local points = spacing..tostring(player.points)
    local messageY = textSpacing * 2 + ((font:getHeight() + (margin * 2) + (textSpacing * 2)) * (index - 1))
    local pointsX = messageX + largestWidth - font:getWidth(points)

    --[[if position:find("top") then
      messageY = margin * 2
    elseif position:find("bottom") then
      messageY = ht - font:getHeight() - (margin * 2)
    end

    if position:find("left") then
      messageX = margin * 2
    elseif position:find("right") then
      messageX = wd - font:getWidth(msg) - (margin * 2)
    end]]

    if messageY > ht then
      break
    end

    -- round rectangle background (TODO: CHANGE TO A GRAPHIC!!!!)
     -- shadow
    love.graphics.setColor(0,0,200,alpha / 2.0)
    love.graphics.roundrect('fill', messageX - margin, messageY - margin + 2, largestWidth + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

    -- background
    love.graphics.setColor(255,255,255,alpha / 4.0 * 3)
    love.graphics.roundrect('fill', messageX - margin, messageY - margin, largestWidth + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

    -- outline of box
    love.graphics.setLineWidth(3)
    love.graphics.roundrect("line", messageX - margin, messageY - margin, largestWidth + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

    --print the bar between the points and player name
    love.graphics.line(messageX + largestWidth - longestPoints, messageY - margin, messageX + largestWidth - longestPoints, messageY + font:getHeight() + margin)

    -- text on box
    love.graphics.setColor(0,0,0,alpha)
    love.graphics.print(player.name, messageX, messageY)
    love.graphics.print(points, pointsX, messageY)

    love.graphics.setColor(255, 255, 255)
  end

  love.graphics.setFont(prevFont)
end

function printPrettyMessage(msg, position, alpha, font)
  position = position or "center"
  alpha = alpha or 255
  font = font or defaultFont
  local prevFont = love.graphics.getFont()

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
  love.graphics.setColor(0,0,0,alpha / 2.0)
  love.graphics.roundrect('fill', messageX - margin, messageY - margin + 2, font:getWidth(msg) + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

  -- background
  love.graphics.setColor(255,255,255,alpha / 4.0 * 3.0)
  love.graphics.roundrect('fill', messageX - margin, messageY - margin, font:getWidth(msg) + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

  -- outline of box
  love.graphics.setLineWidth(3)
  love.graphics.roundrect("line", messageX - margin, messageY - margin, font:getWidth(msg) + (margin * 2), font:getHeight() + (margin * 2), edgeSize, edgeSize)

  -- text on box
  love.graphics.setColor(0,0,0,alpha)
  love.graphics.print(msg, messageX, messageY)
  love.graphics.setColor(255, 255, 255)

  love.graphics.setFont(prevFont)
end

function handleChannel()
   while channel:getCount() > 0 do
     local action = channel:pop()
     if isDebugging then print("Action: "..action) end
     if action == "exit" then
       --print("Exiting...")
       love.event.quit()
     elseif action:find("pixelSize || ") then
       startingPixSize = tonumber(split(action, " || ")[2])
     elseif action:find("gameTime || ") then
       imgTime = tonumber(split(action, " || ")[2])
     elseif action == "isCheckingImages" then
       isCheckingImages = not isCheckingImages
     elseif action == "isRandomFiles" then
       isRandomFiles = not isRandomFiles
       reloadImages()
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
   
   if not love.window.hasFocus() and not isEndGame and not hasToldConsoleOfSwitch then
      gameChannel:push("LostFocus")
      hasToldConsoleOfSwitch = true
   elseif love.window.hasFocus() then
      hasToldConsoleOfSwitch = false
   end

   if isWantingGameToStart and love.window.hasFocus() then
     isWantingGameToStart = false
     if triviaButtons ~= nil then gameChannel:supply("started") end
     moveToNextImage(1, #testImgNames + 1)
   end

   if isGoingToNextImage then
     moveToNextImage(1, #testImgNames + 1)
     isGoingToNextImage = false
   end

   if not isEndGame and --[[(not isImagePaused or gameTime >= imgTime)]]not isImagePaused and love.window.hasFocus() then
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
               if not isEndGame and not hasButtonDown and isWaitingForPlayerButton == nil and tablelen(imageGuessers) < tablelen(contestantPointIndex) and imageGuessers[i] == nil and contestantPointIndex[i] ~= nil and transitionAlpha <= 0 then
                  hasButtonDown = true
               end

               if isWaitingForPlayerButton ~= nil --[[and contestantPointIndex[i] == nil]] then
                  contestantPointIndex[i] = Player:new(isWaitingForPlayerButton, i)

                  local playerChannel = love.thread.getChannel("AddPlayer")
                  playerChannel:supply("added || "..isWaitingForPlayerButton.." || "..i)
                  isWaitingForPlayerButton = nil
                  playSound(buzzedSFX)
               end

               if imageGuessers[i] == nil and hasButtonDown and contestantPointIndex[i] ~= nil then
                 table.insert(guessers, contestantPointIndex[i])
               end
            end
         end
      end

      -- pause the game if any joystick buttons were down
      if hasButtonDown then
         isImagePaused = true
         playSound(buzzedSFX)
         isShowingPlayerMessage = true

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
         gameChannel:push("buzzedPlayer || "..guesser.name)
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
   if key == 'q' --[[or key == 'escape']] then -- quit program
      love.event.quit()
   end

   if key == 'f' and isEndGame then -- set to fullscreen
      --love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
      setFullscreen()
   end

   if key == '[' and isCheckingImages then -- move to previous image
      moveToNextImage(-1, 0)
   elseif key == ']' and not isEndGame then -- move to next image
      moveToNextImage(1, #testImgNames + 1)
   end

   if key == 'r' and triviaButtons == nil then -- reload images folder, and eventually config.ini
      --[[isEndGame = true
      currImgName = ""
      currImgIndex = 0
      gameTime = 0
      love.mouse.setVisible(true)

      local directory = isTesting and "testing" or "images"
      testImgNames = loadImageFolder(directory)
      testImg = {}]]
      reloadImages()
      print("Images reloaded.")
   end

   if key == 'p' then -- pause or unpause the game
      toggleImagePause()
   end

   if key == 'y' and triviaButtons ~= nil and not isEndGame and guesser ~= nil and transitionAlpha <= 0 then -- correct answer
     guesser.points = guesser.points + currentPoints
     contestantPointIndex[guesser.index].points = guesser.points

     imageGuessers = contestantPointIndex
     gameChannel:push("update || "..guesser.index.." || "..guesser.points)

     playSound(correctSFX)
     
     isShowingPlayerMessage = false
     guesserTimer = nil

     if gameTime < imgTime then
       moveToNextImage(1, #testImgNames + 1)
     else
       toggleImagePause()
     end
   elseif key == 'n' and triviaButtons ~= nil and not isEndGame and guesser ~= nil and transitionAlpha <= 0 then -- incorrect answer
     guesser.points = guesser.points - currentPoints
     contestantPointIndex[guesser.index].points = guesser.points

     imageGuessers[tonumber(guesser.index)] = guesser
     gameChannel:push("update || "..guesser.index.." || "..guesser.points)

     playSound(wrongSFX)
     
     isShowingPlayerMessage = false
     guesserTimer = nil

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
      guesser = nil

      -- if it's not the end of the game
      if currImgIndex <= #testImgNames and currImgIndex > 0 then
         isEndGame = false
         love.mouse.setVisible(false)

         currImgName = testImgNames[currImgIndex]

         -- Print out the image name
         if triviaButtons ~= nil then
           gameChannel:push("NextImage || "..currImgIndex .. ": " .. justFilename(currImgName))
         else
           print(currImgIndex .. ": " .. justFilename(currImgName))
         end
         testImg[currImgIndex] = love.graphics.newImage(testImgNames[currImgIndex])

         s.shader:send('screen', {testImg[currImgIndex]:getWidth(), testImg[currImgIndex]:getHeight()})

         scaleAndTranslateImage()
         gameTime = 0
      else -- we've finished going through the images
         if not isEndGame then
           saveScores()
           --if triviaButtons ~= nil then saveScores() end
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

function saveScores()
  --[[table.sort(contestantPointsSorted,
     function(a, b)
        -- if the points are equal, sort by name
        if a.points == b.points then
           return a.name <= b.name --and true or false
        end

        -- else, give the higher points people precedence
        return a.points > b.points
     end
  )]]
  -- save the scores of the players
  local filename = SCORES_DIRECTORY.."/"..os.date("%m-%d-%Y_%H-%M-%S", os.time()) .. ".ini"
  local correctSlashFilename = split(filename, "/")
  correctSlashFilename = correctSlashFilename[1]..SLASHES..correctSlashFilename[2]

  local saveData = love.filesystem.newFile(filename)
  local passed, errMsg = saveData:open("w")

  if passed then
    -- write the scores
    saveData:write("[PlayerScores]\r\n")
    for i = 1, #contestantPointsSorted do
      local player = contestantPointsSorted[i]
      saveData:write("\""..player.name.."\"="..player.points.."\r\n")
    end

    saveData:write("[Images]\r\n")
    for i = 1, #testImgNames do
      saveData:write("\"Image"..i.."\"=\""..split(testImgNames[i], "/")[2].."\"\r\n")
    end

    saveData:write("[Settings]\r\n")
    saveData:write("\"startingPixSize\"="..startingPixSize.."\r\n")
    saveData:write("\"imgTime\"="..imgTime.."\r\n")

    saveData:close()

    print("Player scores saved. You can view the scores at "..getCorrectSlashSaveDirectory()..correctSlashFilename..".")
  else
    print("Could not create save data of players' scores. Error message: "..errMsg)
    print("Here are the scores outputted to console instead:")

    for i = 1, #contestantPointsSorted do
      print(player)
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

function playSound(sound)
  love.audio.newSource(sound):play()
end
