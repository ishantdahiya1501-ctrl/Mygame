local player = require("scripts.player")
local animation = require("scripts.animation")
local Camera = require("scripts.camera")

function love.load()
    animation.load()
    cam = Camera.new()
end

function love.update(dt)
    player.update(dt)
    cam:update(dt)
end

function love.draw()
    cam:attach()
    player.draw()
    cam:detach()
end

function love.keypressed(key)
    player.keypressed(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    player.mousepressed(x, y, button)
end