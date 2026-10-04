local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)

    self.baseY = -30       -- resting camera offset (player sits lower on screen)
    self.y = self.baseY     -- current camera offset
    self.targetY = self.baseY

    self.lookAmount = -80   -- extra shift when looking up (negative = camera moves up)
    self.speed = 5          -- how fast the camera eases toward the target

    return self
end

function Camera:update(dt)
    if love.keyboard.isDown("w") then
        -- Look up: shift camera up so we see more of the world above
        self.targetY = self.baseY + self.lookAmount
    elseif love.keyboard.isDown("s") then
        -- Look down: shift camera down so we see more below
        self.targetY = self.baseY - self.lookAmount
    else
        -- Rest at the base position
        self.targetY = self.baseY
    end

    -- Smoothly ease toward the target (frame-rate independent)
    self.y = self.y + (self.targetY - self.y) * math.min(self.speed * dt, 1)
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(0, -self.y)
end

function Camera:detach()
    love.graphics.pop()
end

return Camera