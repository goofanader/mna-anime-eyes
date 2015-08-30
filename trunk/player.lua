local class = require '../libraries/middleclass'
require '../libraries/middleclass-commons'

Player = class('Player')

function Player:Initialize(number)
   self.points = 0
   self.arcadeNum = nil
   self.name = "Player " .. (number or 1)
end