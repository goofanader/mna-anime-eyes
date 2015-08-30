local class = require '../libraries/middleclass'
require '../libraries/middleclass-commons'

GameData = class('GameData')

function GameData:Initialize()
   self.currImgName = nil
   self.gameTime = nil
   self.isFullscreen = nil
   self.players = {}
   self.pixelSize = nil
   self.imgTime = nil
   self.isEndGame = nil
   self.isPaused = nil
   self.directory = nil
end

function GameData:dataTable()
   return {
      currImgName = self.currImgName,
      gameTime = self.gameTime,
      isFullscreen = self.isFullscreen,
      players = self.players
   }
end