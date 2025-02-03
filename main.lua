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
    local player = {}
    player.x = gameWidth / 4
    player.y = gameHeight / 2
    player.width = 20
    player.height = 20
    player.velocity = 0
    player.gravity = 1000
    player.jump = -300
    player.maxVelocity = 550

    _G.player = player

    -- Set up pipes
    pipes = {}
    pipeTimer = 0
    pipeInterval = 2
    pipeWidth = 30
    pipeGap = 80
    pipeSpeed = 80

    table.insert(pipes, createPipe())

    score = 0

    -- Load font
    font = love.graphics.newFont('resources/fonts/CherryBombOne-Regular.ttf', 14)
    fontXL = love.graphics.newFont('resources/fonts/CherryBombOne-Regular.ttf', 28)
end

-- Update player position in update function
function love.update(dt)
    switch = {
        [states.start] = startStateUpdate,
        [states.play] = playStateUpdate,
        [states.gameOver] = gameOverStateUpdate
    }

    switch[gameState](dt)
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
    love.graphics.draw(playerSprite, player.x, player.y, 0, player.width / playerSprite:getWidth(),
        player.height / playerSprite:getHeight())

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
        playerJump()
    elseif gameState == states.play then
        playerJump()
    elseif gameState == states.gameOver then
        love.load()
    end
end

function playerJump()
    player.velocity = math.min(player.velocity, 0)
    player.velocity = player.velocity + player.jump
end

function handleCollision()
    if score > highScore then
        highScore = score
    end

    gameState = states.gameOver
end

function startStateUpdate(dt)
    -- oscillate player Y position
    player.y = player.y + math.sin(love.timer.getTime() * 5) * dt * 50
end

function playStateUpdate(dt)
    player.velocity = player.velocity + player.gravity * dt
    if player.velocity > player.maxVelocity then
        player.velocity = player.maxVelocity
    elseif player.velocity < -player.maxVelocity then
        player.velocity = -player.maxVelocity
    end

    player.y = player.y + player.velocity * dt

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

function gameOverStateUpdate(dt)
    -- player falls to the floor
    player.velocity = player.velocity + player.gravity * dt
    player.y = player.y + player.velocity * dt

    if player.y + player.height > gameHeight - floorHeight then
        player.y = gameHeight - floorHeight - player.height
        player.velocity = 0
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
        love.graphics.print(text, gameWidth / 2 - textWidth / 2, gameHeight / 2 + 50)
    end
end
