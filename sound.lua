local Sound = {}

function Sound:init()
    self:load()
end

function Sound:load()
    self.sounds = {
        jump = love.audio.newSource('resources/audio/jump.wav', 'static'),
        score = love.audio.newSource('resources/audio/score.wav', 'static'),
        hit = love.audio.newSource('resources/audio/hit.wav', 'static')
    }
end

function Sound:play(sound)
    self.sounds[sound]:play()
end

function Sound:stop(sound)
    self.sounds[sound]:stop()
end

return Sound
