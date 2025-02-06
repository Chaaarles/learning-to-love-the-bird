local Player = require 'player'
local Config = require 'config'

Sound = require 'sound'

local windowWidth, windowHeight = Config.gameWidth * 2, Config.gameHeight * 2

highScore = 0

love.window.setTitle('Flappy Bird but Again!')
love.window.setMode(windowWidth, windowHeight, {
    fullscreen = false,
    resizable = true,
    borderless = false,
    vsync = true
})

-- set filter to nearest neighbor
love.graphics.setDefaultFilter('nearest', 'nearest')

-- Create a pipe
function createPipe()
    local pipe = {}
    pipe.x = Config.gameWidth + 50
    local minY = pipeGap / 2 + 32
    local maxY = Config.gameHeight - Config.floorHeight - pipeGap / 2 - 32
    pipe.y = math.floor(math.random(minY, maxY))
    pipe.scored = false

    pipe.top = {
        y = 0,
        height = pipe.y - pipeGap / 2
    }

    pipe.bottom = {
        y = pipe.y + pipeGap / 2,
        height = Config.gameHeight - pipe.y - pipeGap / 2
    }

    return pipe
end

function love.load()
    loadTextures()
    Sound:init()

    gameState = Config.states.start

    -- Player table
    player = Player:new(Config.gameWidth / 4, Config.gameHeight / 2)

    -- Set up pipes
    pipes = {}
    pipeTimer = 0
    pipeInterval = 2
    pipeWidth = 32
    pipeGap = 80
    pipeSpeed = 80

    groundSpeed = 80
    groundPosition = 0

    backgroundSpeed = 20
    backgroundPosition = 0

    table.insert(pipes, createPipe())

    score = 0

    -- Load font
    font = love.graphics.newFont('resources/fonts/Jersey10-Regular.ttf', 21, 'mono')
    fontXL = love.graphics.newFont('resources/fonts/Jersey10-Regular.ttf', 33, 'mono')
end

-- Update player position in update function
function love.update(dt)
    player:update(dt)

    if (gameState == Config.states.play) then
        playStateUpdate(dt)
    end
end

function love.resize(w, h)
    windowWidth, windowHeight = w, h
end

function love.draw()
    -- Initialize canvas
    local canvas = love.graphics.newCanvas(Config.gameWidth, Config.gameHeight)
    love.graphics.setCanvas(canvas)

    love.graphics.setColor(1, 1, 1)

    -- Draw background
    love.graphics.draw(textures.backgroundTexture, textures.background.top, 0, 0, 0, 1, 100)
    for i = backgroundPosition, Config.gameWidth, 256 do
        love.graphics.draw(textures.backgroundTexture, textures.background.full, i,
            Config.gameHeight - 256 - Config.floorHeight)
    end

    -- Draw pipes
    love.graphics.setColor(1, 1, 1)
    for i, pipe in ipairs(pipes) do
        -- draw top pipe
        love.graphics
            .draw(textures.tiles, textures.greenPipe.bottom, pipe.x, pipe.top.y + pipe.top.height - 32, 0, 1, 1)
        love.graphics.draw(textures.tiles, textures.greenPipe.middle, pipe.x, pipe.top.y, 0, 1,
            (pipe.top.height / 16) - 2)

        -- draw bottom pipe
        love.graphics.draw(textures.tiles, textures.greenPipe.top, pipe.x, pipe.bottom.y, 0, 1, 1)
        love.graphics.draw(textures.tiles, textures.greenPipe.middle, pipe.x, pipe.bottom.y + 16, 0, 1,
            (pipe.bottom.height / 16) - 2)
    end

    -- Draw score
    renderUI()

    -- Draw floor as repeating tiles. Scrolling across the screen.
    love.graphics.setColor(1, 1, 1)
    -- Top level
    for i = groundPosition, Config.gameWidth, 64 do
        love.graphics.draw(textures.tiles, textures.ground.top, i, Config.gameHeight - Config.floorHeight)
    end
    -- Fill
    for i = groundPosition, Config.gameWidth, 16 do
        love.graphics.draw(textures.tiles, textures.ground.fill, i, Config.gameHeight - Config.floorHeight + 16)
    end

    -- Draw player
    love.graphics.setColor(1, 1, 1)
    player:draw()

    -- Reset canvas
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    local ratio = math.min(windowWidth / Config.gameWidth, windowHeight / Config.gameHeight)
    love.graphics.draw(canvas, windowWidth / 2, windowHeight / 2, 0, ratio, ratio, Config.gameWidth / 2,
        Config.gameHeight / 2)
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
    if gameState == Config.states.start then
        gameState = Config.states.play
        player:jump()
    elseif gameState == Config.states.play then
        player:jump()
    elseif gameState == Config.states.gameOver then
        love.load()
    end
end

function handleCollision()
    if score > highScore then
        highScore = score
    end

    Sound:play('hit')
    gameState = Config.states.gameOver
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

    -- Scroll ground
    groundPosition = groundPosition - groundSpeed * dt
    groundPosition = groundPosition % -64

    -- Scroll background
    backgroundPosition = backgroundPosition - backgroundSpeed * dt
    backgroundPosition = backgroundPosition % -256

    -- Check for collision
    for i, pipe in ipairs(pipes) do
        if player.x + player.width > pipe.x and player.x < pipe.x + pipeWidth then
            if player.y < pipe.top.height or player.y + player.height > pipe.bottom.y then
                handleCollision()
            end
        end
    end

    -- Check for floor
    if player.y + player.height > Config.gameHeight - Config.floorHeight then
        handleCollision()
    end

    -- Check for score
    for i, pipe in ipairs(pipes) do
        if player.x > pipe.x + pipeWidth / 2 and not pipe.scored then
            score = score + 1
            pipe.scored = true
            Sound:play('score')
        end
    end
end

function renderUI()
    love.graphics.setColor(0, 0, 0)

    if gameState == Config.states.start then
        love.graphics.setFont(font)
        local text = 'Press Space to Start'
        local textWidth = font:getWidth(text)
        love.graphics.print(text, math.floor(Config.gameWidth / 2 - textWidth / 2),
            math.floor(Config.gameHeight / 2 - 50))
    elseif gameState == Config.states.play then
        love.graphics.setFont(fontXL)
        local text = score
        local textWidth = font:getWidth(text)
        love.graphics.print(text, math.floor(Config.gameWidth / 2 - textWidth / 2), 20)
    elseif gameState == Config.states.gameOver then
        love.graphics.setFont(font)
        local text = 'Game Over'
        local textWidth = font:getWidth(text)
        love.graphics.print(text, math.floor(Config.gameWidth / 2 - textWidth / 2),
            math.floor(Config.gameHeight / 2 - 50))

        local text = 'Score: ' .. score
        local textWidth = font:getWidth(text)
        love.graphics.print(text, math.floor(Config.gameWidth / 2 - textWidth / 2), math.floor(Config.gameHeight / 2))

        local text = 'High Score: ' .. highScore
        local textWidth = font:getWidth(text)
        love.graphics.print(text, math.floor(Config.gameWidth / 2 - textWidth / 2),
            math.floor(Config.gameHeight / 2 + 20))
    end
end

function loadTextures()
    local tiles = love.graphics.newImage('resources/sprites/tiles.png')

    local greenPipeTopQuad = love.graphics.newQuad(0, 0, 32, 32, tiles:getDimensions())
    local greenPipeMiddleQuad = love.graphics.newQuad(0, 32, 32, 16, tiles:getDimensions())
    local greenPipeBottomQuad = love.graphics.newQuad(0, 48, 32, 32, tiles:getDimensions())

    local groundTopQuad = love.graphics.newQuad(0, 80, 64, 16, tiles:getDimensions())
    local groundFillQuad = love.graphics.newQuad(0, 96, 16, 16, tiles:getDimensions())

    local background = love.graphics.newImage('resources/sprites/background.png')
    local fullBackgroundQuad = love.graphics.newQuad(0, 0, 256, 256, background:getDimensions())
    local backgroundTopQuad = love.graphics.newQuad(0, 0, 256, 1, background:getDimensions())

    textures = {
        tiles = tiles,
        backgroundTexture = background,
        greenPipe = {
            top = greenPipeTopQuad,
            middle = greenPipeMiddleQuad,
            bottom = greenPipeBottomQuad
        },
        ground = {
            top = groundTopQuad,
            fill = groundFillQuad
        },
        background = {
            full = fullBackgroundQuad,
            top = backgroundTopQuad
        }
    }
end
