local directory = 'love-flappy-bird'
local filePath = directory .. '/highscore.txt'

local ScoreManager = {}
ScoreManager.__index = ScoreManager

function ScoreManager:new()
    local scoreManager = setmetatable({}, ScoreManager)

    local directoryExists = love.filesystem.getInfo(directory)
    if directoryExists == nil then
        love.filesystem.createDirectory(directory)
    end

    local fileExists = love.filesystem.getInfo(filePath)
    if fileExists == nil then
        love.filesystem.write(filePath, '0')
    end

    local contents, size = love.filesystem.read(filePath)

    scoreManager.highscore = tonumber(contents)

    return scoreManager
end

function ScoreManager:save()
    love.filesystem.write(filePath, tostring(self.highscore))
end

function ScoreManager:compare(score)
    if score > self.highscore then
        self.highscore = score
        self:save()
    end
end

return ScoreManager
