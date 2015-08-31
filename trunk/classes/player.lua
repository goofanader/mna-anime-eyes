local class = require 'middleclass'
local class_commons = require 'libraries/middleclass-commons'

local Player = class('Player')

function Player:initialize(name, index)
   self.name = name
   self.index = index
   self.points = 0
end

--[[function Player:__concat()
   return self.name .. " (Player "..self.index..")"--self:__tostring()
end]]

function Player:__tostring()
   return self.name .. ": "..self.points.." points (Player "..self.index..")"
end

return Player