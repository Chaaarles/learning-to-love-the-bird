local Player = require 'player'

gameWidth = 180
gameHeight = 320

windowWidth, windowHeight = gameWidth * 2, gameHeight * 2

states = {
    start = 'start',
    play = 'play',
    gameOver = 'gameOver'
}

highScore = 0

floorHeight = 30

love.window.setTitle('Flappy Bird but Again!')
love.window.setMode(windowWidth, windowHeight, {
    fullscreen = false,
    resizable = true,
    borderless = false,
    vsync = true
})

-- set filter to nearest neighbor
love.graphics.setDefaultFilter('nearest', 'nearest')

playerSprite = love.graphics.newImage('resources/sprites/bingus.png')

-- Create a pipe
function createPipe()
    local pipe = {}
    pipe.x = gameWidth + 50
    pipe.y = math.random(50, gameHeight - floorHeight - 50)
    pipe.scored = false

    pipe.top = {
        y = 0,
        height = pipe.y - pipeGap / 2
    }

    pipe.bottom = {
        y = pipe.y + pipeGap / 2,
        height = gameHeight - pipe.y - pipeGap / 2
    }

    return pipe
end

function love.load()
    gameState = states.start

    -- Player table
    player = Player:new()

    -- Set up pipes
    pipes = {}
    pipeTimer = 0
    pipeInterval = 2
    pipeWidth = 30
    pipeGap = 85
    pipeSpeed = 80

    table.insert(pipes, createPipe())

    score = 0

    -- Load font
    font = love.graphics.newFont('resources/fonts/CherryBombOne-Regular.ttf', 14)
    fontXL = love.graphics.newFont('resources/fonts/CherryBombOne-Regular.ttf', 28)
end

-- Update player position in update function
function love.update(dt)
    player:update(dt)

    if (gameState == states.play) then
        playStateUpdate(dt)
    end
end

function love.resize(w, h)
    windowWidth, windowHeight = w, h
end

function love.draw()
    -- Initialize canvas
    local canvas = love.graphics.newCanvas(gameWidth, gameHeight)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(.7, 1, 1)

    -- Draw pipes
    love.graphics.setColor(0, 0.7, 0)
    for i, pipe in ipairs(pipes) do
        love.graphics.rectangle('fill', pipe.x, pipe.top.y, pipeWidth, pipe.top.height)
        love.graphics.rectangle('fill', pipe.x, pipe.bottom.y, pipeWidth, pipe.bottom.height)
    end

    -- Draw score
    renderUI()

    -- Draw floor
    love.graphics.setColor(0, 0, 0.7)
    love.graphics.rectangle('fill', 0, gameHeight - floorHeight, gameWidth, floorHeight)

    -- Draw player
    love.graphics.setColor(1, 1, 1)
    player:draw()

    -- Reset canvas
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    local ratio = math.min(windowWidth / gameWidth, windowHeight / gameHeight)
    love.graphics.draw(canvas, windowWidth / 2, windowHeight / 2, 0, ratio, ratio, gameWidth / 2, gameHeight / 2)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    if key == 'space' then
        actionHandler()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        actionHandler()
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    actionHandler()
end

function actionHandler()
    if gameState == states.start then
        gameState = states.play
        player:jump()
    elseif gameState == states.play then
        player:jump()
    elseif gameState == states.gameOver then
        love.load()
    end
end

function handleCollision()
    if score > highScore then
        highScore = score
    end

    gameState = states.gameOver
end

function playStateUpdate(dt)
    -- Update pipes
    pipeTimer = pipeTimer + dt
    if pipeTimer > pipeInterval then
        table.insert(pipes, createPipe())
        pipeTimer = 0
    end

    for i, pipe in ipairs(pipes) do
        pipe.x = pipe.x - pipeSpeed * dt
        if pipe.x < -pipeWidth - 50 then
            table.remove(pipes, i)
        end
    end

    -- Check for collision
    for i, pipe in ipairs(pipes) do
        if player.x + player.width > pipe.x and player.x < pipe.x + pipeWidth then
            if player.y < pipe.top.height or player.y + player.height > pipe.bottom.y then
                handleCollision()
            end
        end
    end

    -- Check for floor
    if player.y + player.height > gameHeight - floorHeight then
        handleCollision()
    end

    -- Check for score
    for i, pipe in ipairs(pipes) do
        if player.x > pipe.x + pipeWidth / 2 and not pipe.scored then
            score = score + 1
            pipe.scored = true
        end
    end
end

function renderUI()
    love.graphics.setColor(0, 0, 0)

    if gameState == states.start then
        love.graphics.setFont(font)
        local text = 'Press Space to Start'
        local textWidth = font:getWidth(text)
        love.graphics.print(text, gameWidth / 2 - textWidth / 2, gameHeight / 2 - 50)
    elseif gameState == states.play then
        love.graphics.setFont(fontXL)
        local text = score
        local textWidth = font:getWidth(text)
        love.graphics.print(text, gameWidth / 2 - textWidth / 2, 20)
    elseif gameState == states.gameOver then
        love.graphics.setFont(font)
        local text = 'Game Over'
        local textWidth = font:getWidth(text)
        love.graphics.print(text, gameWidth / 2 - textWidth / 2, gameHeight / 2 - 50)

        local text = 'Score: ' .. score
        local textWidth = font:getWidth(text)
        love.graphics.print(text, gameWidth / 2 - textWidth / 2, gameHeight / 2)

        local text = 'High Score: ' .. highScore
        local textWidth = font:getWidth(text)
        love.graphics.print(text, gameWidth / 2 - textWidth / 2, gameHeight / 2 + 20)
    end
end
