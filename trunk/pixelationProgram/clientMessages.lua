parseMessage = {
   currImgName = function (tokens)
      currImgName = tokens[2]

      currImg = love.graphics.newImage(currImgName)
      s.shader:send('screen', {currImg:getWidth(), currImg:getHeight()})
      gameTime = 0
      scaleAndTranslateImage()
      isEndGame = false

      print("got new image: " .. currImgName)
   end,

   gameTime = function (tokens)
      gameTime = tonumber(tokens[2])
      --s.shader:send('time', gameTime)
      print("got new gameTime: " .. gameTime)
   end,

   isFullscreen = function (tokens)
      local width, height, flags = love.window.getMode()
      local currDisplay = flags.display

      print("currDisplay: " .. currDisplay)

      love.window.setFullscreen(strToBool(tokens[2]), "desktop")

      print("fullscreen? " .. tokens[2])
   end,

   players = function (tokens)
   end,

   pixelSize = function (tokens)
      startingPixSize = tonumber(tokens[2])
   end,

   imgTime = function (tokens)
      imgTime = tonumber(tokens[2])
   end,

   isEndGame = function (tokens)
      isEndGame = strToBool(tokens[2])

      if isEndGame then
         gameTime = 0
         currImgName = ""
      end

      print("endgame: " .. tokens[2])
   end,

   isPaused = function (tokens)
      isPaused = strToBool(tokens[2])

      print("isPaused is now " .. tostring(isPaused))
   end,

   directory = function (tokens)
      directory = strToBool(tokens[2])
   end,
   
   isClearImage = function (tokens)
      isClearImage = strToBool(tokens[2])
      
      print("isClearImage? " .. tokens[2])
   end,
   
   hasImageLoaded = function (tokens)
      hasImageLoaded = strToBool(tokens[2])
      
      print("hasImageLoaded? " .. tokens[2])
   end
}