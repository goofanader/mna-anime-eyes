parseMessage = {
   currImgName = function (tokens)
      --print("in clientMessages:parseMessage")
      currImgName = tokens[2]

      currImg = nil
      print("creating new image")
      currImg = love.graphics.newImage(currImgName)
      print("image created")
      gameTime = 0
      scaleAndTranslateImage()
      s.shader:send('screen', {currImg:getWidth(), currImg:getHeight()})
      isEndGame = false

      server:send("hasImageLoaded:true")

      print("got new image: " .. currImgName)
      --print("exiting clientMessages:parseMessage")
   end,

   gameTime = function (tokens)
      print("in clientMessages:gameTime")
      gameTime = tonumber(tokens[2])
      --s.shader:send('time', gameTime)
      print("got new gameTime: " .. gameTime --[[.. " and exiting"]])
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
         isClearImage = true
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
      --print("in clientMessages:isClearImage")
      isClearImage = strToBool(tokens[2])

      print("isClearImage? " .. tokens[2] --[[.. " and exiting"]])
   end
}