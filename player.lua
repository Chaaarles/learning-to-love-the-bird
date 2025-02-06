anim8 = require "lib.anim8"

local Player = {}
Player.__index = Player

function Player:new()
    local player = setmetatable({}, Player)
    player.x = gameWidth / 4
    player.y = gameHeight / 2
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

function Player:update(dt)
    if gameState == states.start then
        self:oscilate(dt)
    elseif gameState == states.play then
        self:flap(dt)
    elseif gameState == states.gameOver then
        self:flop(dt)
    end
end

function Player:oscilate(dt)
    player.y = player.y + math.sin(love.timer.getTime() * 5) * dt * 50
    self.animation:update(dt)
end

function Player:flap(dt)
    self.velocity = self.velocity + self.gravity * dt
    if self.velocity > self.maxVelocity then
        self.velocity = self.maxVelocity
    elseif self.velocity < -self.maxVelocity then
        self.velocity = -self.maxVelocity
    end

    self.rotation = self.velocity / self.maxVelocity * 0.5
    self.y = self.y + self.velocity * dt
    self.animation:update(dt)
end

function Player:flop(dt)
    player.velocity = player.velocity + player.gravity * dt
    player.y = player.y + player.velocity * dt

    if player.y + player.height > gameHeight - floorHeight + 5 then
        player.y = gameHeight - floorHeight - player.height + 5
        player.velocity = 0
    end

    player.rotation = player.velocity / player.maxVelocity * 0.5
end

function Player:draw()
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    self.animation:draw(self.image, centerX, centerY, self.rotation, 1, 1, 8, 8)
end

function Player:jump()
    self.velocity = math.min(self.velocity, 0)
    self.velocity = self.velocity + self.jumpForce
end

return Player
