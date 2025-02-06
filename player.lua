local anim8 = require "lib.anim8"
local Config = require 'config'

local Player = {}
Player.__index = Player

-- Create a new player
function Player:new(startX, startY)
    local player = setmetatable({}, Player)
    player.x = startX
    player.y = startY
    player.width = 15
    player.height = 11
    player.velocity = 0
    player.rotation = 0
    player.gravity = 1000
    player.jumpForce = -300
    player.maxVelocity = 550

    player.image = love.graphics.newImage('resources/sprites/all-birds.png')
    local g = anim8.newGrid(16, 16, player.image:getWidth(), player.image:getHeight())
    player.animation = anim8.newAnimation(g('1-4', 1), 0.1)

    return player
end

-- Update player state
function Player:update(dt)
    if gameState == Config.states.start then
        self:oscillate(dt)
    elseif gameState == Config.states.play then
        self:flap(dt)
    elseif gameState == Config.states.gameOver then
        self:flop(dt)
    end
end

-- Start screen behaviour
function Player:oscillate(dt)
    self.y = self.y + math.sin(love.timer.getTime() * 5) * dt * 50
    self.animation:update(dt)
end

-- Play screen behaviour
function Player:flap(dt)
    self.velocity = self.velocity + self.gravity * dt
    self.velocity = math.max(math.min(self.velocity, self.maxVelocity), -self.maxVelocity)

    self.rotation = self.velocity / self.maxVelocity * 0.5
    self.y = self.y + self.velocity * dt
    self.animation:update(dt)
end

-- Game over screen behaviour
function Player:flop(dt)
    self.velocity = self.velocity + self.gravity * dt
    self.y = self.y + self.velocity * dt
    local groundEmbrace = Config.gameHeight - Config.floorHeight - self.height + 5

    if self.y + self.height > groundEmbrace then
        self.y = groundEmbrace
        self.velocity = 0
    end

    self.rotation = self.velocity / self.maxVelocity * 0.5
end

-- Draw player to the screen
function Player:draw()
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2

    -- Draw the player sprite in the center of the player's hitbox
    -- The player sprite is 16x16, so we need to offset it by 8x8 
    self.animation:draw(self.image, centerX, centerY, self.rotation, 1, 1, 8, 8)
end

-- Add a jump force to the player
function Player:jump()
    self.velocity = math.min(self.velocity, 0)
    self.velocity = math.max(self.velocity + self.jumpForce, -self.maxVelocity)
end

return Player
