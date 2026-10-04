-- scripts/player.lua
-- movement + animation state machine for the player character.
-- the public API (update / keypressed / mousepressed / draw) is unchanged,
-- everything below the surface got shuffled around a bit.

local anims = require("scripts.animation")
local kb    = require("scripts.keybinds")

-- all tuning numbers live here so I stop hunting through the file
local CFG = {
    grav        = 1500,
    floorY      = 500,
    jumpV       = -600,

    w           = 100,
    h           = 200,
    crouchH     = 120,

    walkSpd     = 200,
    runSpd      = 350,
    creepSpd    = 100,
    dashSpd     = 700,
    climbSpd    = 120,

    boredAfter  = 5.0,   -- seconds of no input before the idle fidget kicks in
    dashLen     = 0.20,
    slideLen    = 0.45,
    punchLen    = 0.55,

    pxScale     = 10,
}

local p = {
    x = 300, y = 0,
    vx = 0, vy = 0,
    face = 1,
    width  = CFG.w,
    height = CFG.h,

    state      = "idle",
    prev_state = "idle",
    locked     = false,

    frame      = 1,
    frame_time = 0.05,
    timer      = 0,

    idle_time  = 0,
    state_time = 0,

    on_ladder  = false,
    on_wall    = false,
}

local function grounded()
    return p.y + p.height >= CFG.floorY
end

local function grabAnim(n)
    return anims[n]
end

-- wraps the keybind table lookup so I don't have to nil-check everywhere
local function held(action)
    local k = kb[action]
    return k and love.keyboard.isDown(k) or false
end

local function goTo(n)
    if p.state == n then return end

    p.prev_state = p.state
    p.state      = n
    p.frame      = 1
    p.timer      = 0
    p.state_time = 0

    local a = grabAnim(n)
    p.frame_time = (a and a.frame_time) or 0.05

    -- these three own the player until they run out, don't unlock them here
    if n ~= "punch" and n ~= "dash" and n ~= "slide" then
        p.locked = false
    end
end

local function pollKeys()
    local any = false

    -- NOTE: climb_up / climb_down deliberately left out of this check
    for _, k in ipairs({"left","right","up","down","crouch","sprint","jump","dead"}) do
        if held(k) then
            any = true
            break
        end
    end

    return {
        left       = held("left"),
        right      = held("right"),
        up         = held("up"),
        down       = held("down"),
        crouch     = held("crouch"),
        sprint     = held("sprint"),
        jump       = held("jump"),
        dead       = held("dead"),
        climb_up   = held("climb_up"),
        climb_down = held("climb_down"),
        any        = any,
    }
end

local function stepFrames(dt)
    local a = grabAnim(p.state)
    if not a or not a.frames or #a.frames == 0 then return end

    local ft = a.frame_time or 0.05
    p.timer = p.timer + dt

    while p.timer >= ft do
        p.timer = p.timer - ft
        p.frame = p.frame + 1

        if p.frame > #a.frames then
            p.frame = a.loop and 1 or #a.frames
        end
    end
end

local function animDone()
    local a = grabAnim(p.state)
    if not a or not a.frames or a.loop then return false end
    return p.frame >= #a.frames
end

local function fall(dt)
    p.vy = p.vy + CFG.grav * dt
    p.y  = p.y  + p.vy * dt

    if grounded() then
        p.y  = CFG.floorY - p.height
        p.vy = 0
    end
end

local function nudge(dt, dx)
    p.x = p.x + dx * dt
end

local function figureOutState(i)
    if i.dead then return "dead", 0, p.face end

    if p.on_ladder then
        return "ladder", 0, p.face
    end

    if p.on_wall and not grounded() then
        return "hang", 0, p.face
    end

    if not grounded() then
        if i.crouch then
            return "crouch_jump", 0, p.face
        end
        if i.left and not i.right then
            return "jump", -CFG.walkSpd, -1
        elseif i.right and not i.left then
            return "jump", CFG.walkSpd, 1
        end
        return "jump", 0, p.face
    end

    if i.crouch then
        if i.left and not i.right then
            return "crouch_walk", -CFG.creepSpd, -1
        elseif i.right and not i.left then
            return "crouch_walk", CFG.creepSpd, 1
        end
        return "crouch", 0, p.face
    end

    -- both directions held = standing still, don't flip the sprite
    if i.left and i.right then
        return p.idle_time >= CFG.boredAfter
            and "idle_lookaround" or "idle", 0, p.face
    end

    if not (i.left or i.right) then
        if i.up   then return "look_up",   0, p.face end
        if i.down then return "look_down", 0, p.face end
    end

    if i.left then
        return "walk", -(i.sprint and CFG.runSpd or CFG.walkSpd), -1
    elseif i.right then
        return "walk",  (i.sprint and CFG.runSpd or CFG.walkSpd),  1
    end

    if p.idle_time >= CFG.boredAfter then
        return "idle_lookaround", 0, p.face
    end

    return "idle", 0, p.face
end

local function doPunch(dt)
    p.state_time = p.state_time + dt
    stepFrames(dt)
    fall(dt)

    if p.state_time >= CFG.punchLen then
        p.locked = false
        goTo("idle")
    end
end

local function doDash(dt)
    p.state_time = p.state_time + dt

    local a = grabAnim("dash")
    if a and a.loop == false and animDone() then
        p.state_time = CFG.dashLen
    end

    nudge(dt, CFG.dashSpd * p.face)
    stepFrames(dt)
    fall(dt)

    if p.state_time >= CFG.dashLen then
        p.locked = false
        goTo("idle")
    end
end

local function doSlide(dt)
    p.state_time = p.state_time + dt

    nudge(dt, CFG.creepSpd * 2 * p.face)
    stepFrames(dt)
    fall(dt)

    if p.state_time >= CFG.slideLen then
        p.locked = false
        goTo("idle")
    end
end

function p.update(dt)
    -- locked states run on their own timer and skip normal input handling
    if p.state == "punch" then doPunch(dt) return end
    if p.state == "dash"  then doDash(dt)  return end
    if p.state == "slide" then doSlide(dt) return end

    if p.state == "dead" then
        stepFrames(dt)
        return
    end

    local i = pollKeys()

    if i.any then
        p.idle_time = 0
    else
        p.idle_time = p.idle_time + dt
    end

    p.state_time = p.state_time + dt

    local newState, dx, newFace = figureOutState(i)
    goTo(newState)
    p.face = newFace

    nudge(dt, dx)

    if p.state == "ladder" then
        local vy = 0
        if i.climb_up   then vy = -CFG.climbSpd end
        if i.climb_down then vy =  CFG.climbSpd end
        p.y = p.y + vy * dt
    else
        fall(dt)
    end

    stepFrames(dt)
end

function p.keypressed(key)
    if p.state == "dead" then return end

    if key == kb.jump and grounded() then
        p.locked = false
        p.vy = CFG.jumpV
        goTo("jump")
        return
    end

    if key == kb.dash and not p.locked then
        p.locked = true
        goTo("dash")
        return
    end

    if key == kb.slide and grounded() and not p.locked then
        -- sliding in place looks dumb, only allow it while actually moving
        local moving = love.keyboard.isDown(kb.left)
                    or love.keyboard.isDown(kb.right)
        if moving then
            p.locked = true
            goTo("slide")
        end
    end
end

function p.mousepressed(x, y, button)
    if button ~= 1 then return end
    if p.locked or p.state == "dead" then return end

    p.locked = true
    goTo("punch")
end

local function grabFrame()
    local a = grabAnim(p.state)
    if not a or not a.frames or #a.frames == 0 then
        a = anims.idle
        if not a or not a.frames or #a.frames == 0 then return nil end
    end

    return a.frames[p.frame] or a.frames[1]
end

function p.draw()
    local img = grabFrame()
    if not img then return end

    local s  = CFG.pxScale
    local dx = p.x

    if p.face == -1 then
        -- flip around the right edge or the sprite teleports sideways
        dx = dx + img:getWidth() * s
    end

    love.graphics.draw(img, dx, p.y, 0, s * p.face, s)
end

return p